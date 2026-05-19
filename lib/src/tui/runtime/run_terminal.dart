import 'dart:async';
import 'dart:io';

import '../geometry/rect.dart';
import '../geometry/size.dart';
import '../rendering/ansi_encoder.dart';
import '../rendering/buffer.dart';
import '../rendering/renderer.dart';
import '../style/color.dart';
import '../terminal/terminal.dart';
import '../theme/theme_data.dart';
import 'async_registry.dart';
import 'event.dart';
import 'focus_controller.dart';
import 'key.dart';
import 'logger.dart';
import 'not_a_terminal_exception.dart';
import 'render_context.dart';
import 'render_mode.dart';

typedef OnEventFn<S> = FutureOr<void> Function(
    S state, Event event, RunHandle handle);
typedef RenderFn<S> = void Function(RenderContext ctx, S state);
typedef ThemeBuilder<S> = ThemeData Function(S state);

class RunHandle {
  final FocusController focus;
  bool _running = true;
  bool _redrawRequested = true;

  RunHandle({required this.focus});

  bool get running => _running;
  void stop() => _running = false;
  void requestRedraw() => _redrawRequested = true;
}

Future<void> runTerminal<S>({
  required S initialState,
  required OnEventFn<S> onEvent,
  required RenderFn<S> render,
  ThemeData? theme,
  ThemeBuilder<S>? themeBuilder,
  RenderMode mode = const RenderMode.flow(),
  List<Stream<Event>> sources = const [],
  Duration? frameRate,
  Terminal? terminal,
  CommanderLogger logger = const SilentLogger(),
  ColorMode? colorMode,
  bool allowNonInteractive = false,
  bool enableMouse = true,
  bool exitOnCtrlC = true,
  Duration cursorQueryTimeout = const Duration(milliseconds: 500),
}) async {
  if (!allowNonInteractive) {
    final inIsTty = stdin.hasTerminal;
    final outIsTty = stdout.hasTerminal;
    if (!inIsTty || !outIsTty) {
      final sb = StringBuffer(
          'commander: TUI mode requires an interactive terminal.\n');
      sb.writeln(inIsTty
          ? '  stdin: TTY OK'
          : '  stdin: not a TTY (pipe or redirection)');
      sb.writeln(outIsTty
          ? '  stdout: TTY OK'
          : '  stdout: not a TTY (file redirection)');
      stderr.write(sb.toString());
      throw NotATerminalException(
        message: 'TUI mode requires interactive stdin/stdout.',
        stdinIsTty: inIsTty,
        stdoutIsTty: outIsTty,
      );
    }
  }

  final ownedTerminal = terminal == null;
  final term = terminal ?? Terminal();
  final detectedMode = colorMode ?? AnsiEncoder.detect();
  final encoder = AnsiEncoder(detectedMode);
  final renderer = Renderer(encoder);
  final focus = FocusController();
  final async_ = AsyncRegistry();
  final handle = RunHandle(focus: focus);
  final state = initialState;

  List<({Rect rect, Key key})> lastHitZones = const [];

  int yOffset = 0;
  int flowEffectiveHeight(FlowMode m) {
    final remaining = term.size.height - yOffset;
    final desired = m.height ?? remaining;
    final clamped = desired.clamp(1, term.size.height);
    final minH = m.minHeight ?? 1;
    return clamped < minH ? minH.clamp(1, term.size.height) : clamped;
  }

  Size currentSize = switch (mode) {
    AlternateScreenMode() => term.size,
    FullScreenMode() => term.size,
    FlowMode() => term.size, // placeholder, recomputed after setup
    InlineMode(:final height) => Size(term.size.width, height),
  };

  Buffer back = Buffer(currentSize);

  Future<void> drawFrame() async {
    // Drain pending microtasks so async flows (e.g. Chain) can advance to
    // their next state before we render. Avoids a 1-frame visual gap.
    await Future<void>(() {});

    final activeTheme = themeBuilder != null
        ? themeBuilder(state)
        : (theme ?? const ThemeData());

    final Size desired = switch (mode) {
      AlternateScreenMode() => term.size,
      FullScreenMode() => term.size,
      FlowMode m => Size(term.size.width, flowEffectiveHeight(m)),
      InlineMode(:final height) => Size(term.size.width, height),
    };
    if (desired != currentSize) {
      // Erase the old TUI region before resizing so stale rows from the
      // previous size don't linger in the terminal scrollback. Only applies to
      // flow / inline modes; alternate-screen modes always own the viewport.
      if (mode is FlowMode || mode is InlineMode) {
        final clampedY = yOffset.clamp(0, term.size.height);
        term.moveTo(0, clampedY);
        term.write(AnsiSequences.clearAfterCursor);
      }
      currentSize = desired;
      back = Buffer(currentSize);
      renderer.resize(currentSize);
      renderer.forceRepaint();
    } else {
      back.clear();
    }

    RenderContext makeCtx() {
      focus.resetFrame();
      async_.beginFrame();
      final c = RenderContext(
        buffer: back,
        area: Rect(0, 0, currentSize.width, currentSize.height),
        theme: activeTheme,
        focus: focus,
        async_: async_,
        logger: logger,
        requestRedraw: handle.requestRedraw,
        exit: handle.stop,
      );
      c.resetFrame();
      return c;
    }

    RenderContext ctx = makeCtx();
    render(ctx, state);
    ctx.flushOverlays();

    final isFlowAndRequiredMoreHight = mode is FlowMode &&
        mode.autoGrow &&
        ctx.maxDesiredHeight > currentSize.height;

    if (isFlowAndRequiredMoreHight) {
      final delta = ctx.maxDesiredHeight - currentSize.height;
      // Erase the old buffer area BEFORE scrolling so no stale content
      // ends up shifted into a visible row after scroll.
      term.moveTo(0, yOffset);
      term.write(AnsiSequences.clearAfterCursor);
      term.moveTo(0, yOffset + currentSize.height - 1);

      for (var i = 0; i < delta; i++) {
        term.write('\n');
      }

      await term.flush();

      final (_, newBottomRow) =
          await term.queryCursorPosition(timeout: cursorQueryTimeout);
      final newH = currentSize.height + delta;
      yOffset = (newBottomRow - newH + 1).clamp(0, term.size.height);
      currentSize = Size(currentSize.width, newH);
      back = Buffer(currentSize);
      renderer.resize(currentSize);
      renderer.yOffset = yOffset;
      renderer.forceRepaint();
      term.moveTo(0, yOffset);
      term.write(AnsiSequences.clearAfterCursor);
      ctx = makeCtx();

      render(ctx, state);

      ctx.flushOverlays();
    }

    final newTitle = ctx.pendingTitle;
    if (newTitle != null) {
      term.setTitle(newTitle);
    }

    focus.finalizeFrame();
    async_.endFrame();
    lastHitZones = ctx.hitZones;

    if (mode is AlternateScreenMode || mode is FullScreenMode) {
      term.moveTo(0, 0);
    } else if (mode is InlineMode || mode is FlowMode) {
      term.write('\r');
    }

    final out = renderer.paint(back);
    if (out.isNotEmpty) {
      term.write(out);
      await term.flush();
    }
  }

  Future<void> setup() async {
    term.enterRawMode();

    if (mode is AlternateScreenMode) {
      term.enterAlternateScreen();
    } else if (mode is FullScreenMode) {
      term.write(AnsiSequences.clear);
      term.write(AnsiSequences.home);
    } else if (mode is FlowMode) {
      await term.flush();

      final (_, row0) =
          await term.queryCursorPosition(timeout: cursorQueryTimeout);

      yOffset = row0.clamp(0, term.size.height);

      final height = flowEffectiveHeight(mode);
      for (int i = 0; i < height; i++) {
        term.write('\n');
      }

      term.write(AnsiSequences.moveUp(height));
      await term.flush();
      final (_, row1) =
          await term.queryCursorPosition(timeout: cursorQueryTimeout);
      yOffset = row1.clamp(0, term.size.height);
      currentSize = Size(term.size.width, height);
      term.moveTo(0, yOffset);
      term.write(AnsiSequences.clearAfterCursor);
    } else if (mode is InlineMode) {
      final h = mode.height;
      for (int i = 0; i < h; i++) {
        term.write('\n');
      }
      term.write(AnsiSequences.moveUp(h));

      await term.flush();
      final (_, row1) =
          await term.queryCursorPosition(timeout: cursorQueryTimeout);

      yOffset = row1.clamp(0, term.size.height);

      term.moveTo(0, yOffset);
      term.write(AnsiSequences.clearAfterCursor);
    }
    renderer.yOffset = yOffset;
    back = Buffer(currentSize);
    term.hideCursor();

    if (enableMouse) {
      term.enableMouse();
    }

    await term.flush();
  }

  int lastUsedRow() {
    for (var y = back.height - 1; y >= 0; y--) {
      for (var x = 0; x < back.width; x++) {
        final cell = back.get(x, y);
        if (cell.char != ' ' ||
            cell.style.bg != null ||
            cell.style.fg != null) {
          return y;
        }
      }
    }
    return -1;
  }

  Future<void> teardown() async {
    if (mode is FullScreenMode) {
      term.moveTo(0, term.size.height - 1);
      term.write('\n');
    } else if (mode is InlineMode || mode is FlowMode) {
      final used = lastUsedRow();
      final targetRow = used >= 0 ? yOffset + used + 1 : yOffset;
      // If the row after content would fall off-screen, scroll one line so
      // the cursor lands on a fresh row instead of overwriting content.
      // Otherwise just position on the row right after the last content
      // row — no extra blank line.
      if (targetRow >= term.size.height) {
        term.moveTo(0, term.size.height - 1);
        term.write('\n');
      } else {
        term.moveTo(0, targetRow);
      }
    }
    // When the caller passed their own terminal, only restore terminal
    // modes — leave the stdin subscription and event stream intact so
    // subsequent `runTerminal` calls on the same terminal still work.
    if (ownedTerminal) {
      await term.shutdown();
    } else {
      await term.restore();
    }
    async_.disposeAll();
  }

  try {
    await setup();
  } catch (e) {
    // If setup throws after partially mutating terminal state (e.g. raw mode
    // enabled before alternate screen failed), restore the terminal before
    // propagating to avoid leaving the user with a corrupted shell.
    try {
      await teardown();
    } catch (_) {}
    rethrow;
  }

  final controller = StreamController<Event>();
  async_.onCallbackError = (e, st) {
    logger.error('AsyncRegistry onResolved callback threw',
        error: e, stack: st);
  };
  async_.onResolved = (key) {
    handle.requestRedraw();
    if (!controller.isClosed) {
      controller.add(AsyncResolvedEvent(key));
    }
  };
  final subs = <StreamSubscription>[];
  subs.add(term.events.listen(controller.add));
  for (final s in sources) {
    subs.add(s.listen(controller.add));
  }

  Timer? frameTimer;
  var tickCount = 0;
  if (frameRate != null) {
    frameTimer = Timer.periodic(frameRate, (_) {
      controller.add(TickEvent(++tickCount));
    });
  }

  try {
    await drawFrame();
    await for (final event in controller.stream) {
      if (!handle.running) break;
      var consumed = false;

      try {
        if (event is KeyEvent) {
          if (exitOnCtrlC && event.ctrl && event.char == 'c') {
            handle.stop();
            break;
          }
          consumed = focus.dispatchKey(event);
          if (consumed) handle.requestRedraw();
          if (!consumed && event.key == NamedKey.tab) {
            if (event.shift) {
              focus.previous();
            } else {
              focus.next();
            }
            handle.requestRedraw();
            consumed = true;
          }
        } else if (event is MouseEvent && event.action == MouseAction.down) {
          for (final z in lastHitZones) {
            if (z.rect.contains(event.x, event.y)) {
              focus.focus(z.key);
              handle.requestRedraw();
              break;
            }
          }
        } else if (event is MouseEvent &&
            (event.action == MouseAction.scrollUp ||
                event.action == MouseAction.scrollDown)) {
          for (final z in lastHitZones) {
            if (z.rect.contains(event.x, event.y)) {
              focus.focus(z.key);
              final synthetic = KeyEvent(
                key: event.action == MouseAction.scrollUp
                    ? NamedKey.arrowUp
                    : NamedKey.arrowDown,
              );
              consumed = focus.dispatchKey(synthetic);
              if (consumed) handle.requestRedraw();
              break;
            }
          }
        }
      } catch (e, st) {
        logger.error('dispatch failed', error: e, stack: st);
      }

      if (!consumed) {
        try {
          await onEvent(state, event, handle);
        } catch (e, st) {
          logger.error('onEvent failed', error: e, stack: st);
        }
      }

      if (handle._redrawRequested ||
          event is ResizeEvent ||
          event is AsyncResolvedEvent ||
          event is TickEvent) {
        handle._redrawRequested = false;
        await drawFrame();
      }

      if (!handle.running) break;
    }
  } finally {
    frameTimer?.cancel();
    for (final s in subs) {
      await s.cancel();
    }
    await controller.close();
    await teardown();
  }
}
