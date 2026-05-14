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

typedef OnEventFn<S> = FutureOr<void> Function(S state, Event event, RunHandle handle);
typedef RenderFn<S> = void Function(RenderContext ctx, S state);
typedef ThemeBuilder<S> = ThemeData Function(S state);
typedef ShouldExitFn<S> = bool Function(S state);

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
  ShouldExitFn<S>? shouldExit,
}) async {
  if (!allowNonInteractive) {
    final inIsTty = stdin.hasTerminal;
    final outIsTty = stdout.hasTerminal;
    if (!inIsTty || !outIsTty) {
      final sb = StringBuffer('commander: TUI mode requires an interactive terminal.\n');
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
    return desired.clamp(1, remaining > 0 ? remaining : 1);
  }

  Size currentSize = switch (mode) {
    AlternateScreenMode() => term.size,
    FullScreenMode() => term.size,
    FlowMode() => term.size, // placeholder, recomputed after setup
    InlineMode(:final height) => Size(term.size.width, height),
  };

  Buffer back = Buffer(currentSize);

  Future<void> drawFrame() async {
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
      currentSize = desired;
      back = Buffer(currentSize);
      renderer.resize(currentSize);
      renderer.forceRepaint();
    } else {
      back.clear();
    }

    focus.resetFrame();
    async_.beginFrame();

    final ctx = RenderContext(
      buffer: back,
      area: Rect(0, 0, currentSize.width, currentSize.height),
      theme: activeTheme,
      focus: focus,
      async_: async_,
      logger: logger,
      requestRedraw: handle.requestRedraw,
    );
    ctx.resetFrame();

    render(ctx, state);
    ctx.flushOverlays();
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
      term.write('\x1B[2J\x1B[H');
    } else if (mode is FlowMode) {
      await term.flush();
      final (_, row0) = await term.queryCursorPosition();
      yOffset = row0;
      final m = mode as FlowMode;
      final h = flowEffectiveHeight(m);
      for (var i = 0; i < h; i++) {
        term.write('\n');
      }
      term.write('\x1B[${h}A');
      await term.flush();
      final (_, row1) = await term.queryCursorPosition();
      yOffset = row1;
      currentSize = Size(term.size.width, h);
      term.moveTo(0, yOffset);
      term.write('\x1B[0J');
    } else if (mode is InlineMode) {
      final h = (mode as InlineMode).height;
      for (var i = 0; i < h; i++) {
        term.write('\n');
      }
      term.write('\x1B[${h}A');
      await term.flush();
      final (_, row1) = await term.queryCursorPosition();
      yOffset = row1;
      term.moveTo(0, yOffset);
      term.write('\x1B[0J');
    }
    renderer.yOffset = yOffset;
    back = Buffer(currentSize);
    term.hideCursor();
    if (enableMouse) term.enableMouse();
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
      term.moveTo(0, targetRow);
      term.write('\r');
    }
    await term.shutdown();
    async_.disposeAll();
  }

  await setup();

  final controller = StreamController<Event>();
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

      if (shouldExit != null && shouldExit(state)) {
        handle.stop();
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
