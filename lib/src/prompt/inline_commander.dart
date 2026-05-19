import 'dart:async';
import 'dart:io';

import '../tui/geometry/rect.dart';
import '../tui/runtime/event.dart';
import '../tui/runtime/key.dart';
import '../tui/runtime/render_context.dart';
import '../tui/runtime/render_mode.dart';
import '../tui/runtime/run_terminal.dart';
import '../tui/style/style.dart';
import '../tui/terminal/terminal.dart';
import '../tui/theme/theme_data.dart';
import '../tui/widget/widget.dart';
import '../tui/widgets/async/async.dart';
import '../tui/widgets/display/row_column.dart';
import '../tui/widgets/display/text.dart';
import '../tui/widgets/feedback/spinner.dart';
import '../tui/widgets/input/confirm.dart';
import '../tui/widgets/input/input.dart';
import '../tui/widgets/input/input_number.dart';
import '../tui/widgets/list/select.dart' as tui_select;
import 'run_one_shot.dart';
import 'status_print.dart';

/// One-shot interactive prompts built on top of the Commander TUI runtime.
///
/// Each interactive method opens its own `runTerminal` in flow mode, captures
/// a single value, and tears down cleanly. Status methods write directly to
/// stdout without entering raw mode.
///
/// ```dart
/// final commander = InlineCommander();
/// final name = await commander.ask('Your name?');
/// commander.success('Hello $name');
/// ```
class InlineCommander {
  final ThemeData? _theme;
  final Terminal? _terminalOverride;
  final IOSink? _sink;
  final bool _allowNonInteractive;

  Terminal? _cachedTerminal;
  bool _disposed = false;

  /// Creates a new commander.
  ///
  /// [theme] applies to every interactive prompt issued through this
  /// commander. [terminal] is mainly used by tests to inject a
  /// [TestTerminal]; production callers should leave it null. [sink]
  /// overrides the destination of status helpers (default: stdout).
  /// [allowNonInteractive] disables the TTY guard in `runTerminal` —
  /// only enable for testing.
  InlineCommander({
    ThemeData? theme,
    Terminal? terminal,
    IOSink? sink,
    bool allowNonInteractive = false,
  })  : _theme = theme,
        _terminalOverride = terminal,
        _sink = sink,
        _allowNonInteractive = allowNonInteractive;

  /// Returns the terminal to use for the next prompt. The same instance is
  /// reused across calls so successive prompts share one stdin
  /// subscription and avoid the "stdin: not a TTY" error that would
  /// otherwise appear after the first prompt's shutdown.
  Terminal _terminal() {
    if (_disposed) {
      throw StateError('InlineCommander has been disposed');
    }
    if (_terminalOverride != null) return _terminalOverride;
    return _cachedTerminal ??= Terminal();
  }

  /// Releases any internally-cached terminal. Call this when you're done
  /// issuing prompts (typically at the end of your program). No-op if the
  /// commander was constructed with an explicit `terminal:` argument.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final t = _cachedTerminal;
    _cachedTerminal = null;
    if (t != null) await t.shutdown();
  }

  // ---------------------------------------------------------------------------
  // Interactive prompts
  // ---------------------------------------------------------------------------

  /// Asks the user for a free-form string answer.
  ///
  /// [validate] returns null to accept, or an error message to retry. Returns
  /// the submitted value, or [defaultValue] when the user submits an empty
  /// line and a [defaultValue] is provided.
  Future<String> ask(
    String message, {
    String? defaultValue,
    String? placeholder,
    bool obscure = false,
    String? Function(String value)? validate,
  }) {
    final state = InputState();
    return runOneShot<String>(
      (ctx, submit) => ctx.draw(
        Input(
          id: Key.symbol(#__inline_ask),
          message: message,
          state: state,
          defaultValue: defaultValue,
          placeholder: placeholder,
          obscure: obscure,
          validate: validate,
          onSubmit: submit,
        ),
        Rect(ctx.area.x, ctx.area.y, ctx.area.width, state.error != null ? 2 : 1),
      ),
      theme: _theme,
      terminal: _terminal(),
      allowNonInteractive: _allowNonInteractive,
    );
  }

  /// Sugar for [ask] with `obscure: true`. The submitted value never appears
  /// on screen.
  Future<String> password(
    String message, {
    String? Function(String value)? validate,
  }) =>
      ask(message, obscure: true, validate: validate);

  /// Asks for a numeric answer with optional bounds.
  Future<num> number(
    String message, {
    num? min,
    num? max,
    num? defaultValue,
    bool allowDecimals = false,
    String? Function(num value)? validate,
  }) {
    final state = InputNumberState(initialValue: defaultValue);
    return runOneShot<num>(
      (ctx, submit) => ctx.draw(
        InputNumber(
          id: Key.symbol(#__inline_number),
          state: state,
          message: message,
          min: min,
          max: max,
          defaultValue: defaultValue,
          allowDecimals: allowDecimals,
          validate: validate,
          onSubmit: submit,
        ),
        Rect(ctx.area.x, ctx.area.y, ctx.area.width, state.error != null ? 2 : 1),
      ),
      theme: _theme,
      terminal: _terminal(),
      allowNonInteractive: _allowNonInteractive,
    );
  }

  /// Lets the user pick a single value from [options].
  Future<T> select<T>(
    String message, {
    required List<T> options,
    T? defaultValue,
    String Function(T item)? display,
    int visibleCount = 5,
    bool filterable = false,
  }) {
    if (options.isEmpty) {
      throw ArgumentError.value(options, 'options', 'must not be empty');
    }
    final state = tui_select.SelectState<T>();
    T? pending;
    var submitted = false;

    return runOneShot<T>(
      (ctx, submit) {
        if (submitted) {
          _drawCompactAnswer(ctx, message, display?.call(pending as T) ?? pending.toString());
          submit(pending as T);
          return;
        }
        final widget = tui_select.Select<T>(
          id: Key.symbol(#__inline_select),
          items: options,
          state: state,
          defaultValue: defaultValue,
          mode: tui_select.SelectionMode.single,
          visibleCount: visibleCount,
          filterable: filterable,
          builder: (item, itemState) {
            final label = display?.call(item) ?? item.toString();
            final prefix = itemState.isSelected ? '●' : '○';
            return Text(
              ' $prefix $label',
              style: itemState.isActive ? const Style(bold: true) : null,
            );
          },
          onSubmit: (list) {
            if (list.isEmpty) return;
            pending = list.first;
            submitted = true;
          },
        );
        _drawWithHeader(ctx, message, widget,
            bodyHeight: _selectBodyHeight(options.length, visibleCount, filterable));
      },
      theme: _theme,
      terminal: _terminal(),
      allowNonInteractive: _allowNonInteractive,
    );
  }

  /// Lets the user pick multiple values from [options]. Space toggles each
  /// row; Enter submits.
  Future<List<T>> multiSelect<T>(
    String message, {
    required List<T> options,
    List<T> defaults = const [],
    String Function(T item)? display,
    int? minSelections,
    int? maxSelections,
    int visibleCount = 5,
    bool filterable = false,
  }) {
    if (options.isEmpty) {
      throw ArgumentError.value(options, 'options', 'must not be empty');
    }
    final state = tui_select.SelectState<T>();
    List<T>? pending;
    var submitted = false;

    return runOneShot<List<T>>(
      (ctx, submit) {
        if (submitted) {
          final labels = (pending ?? const [])
              .map((e) => display?.call(e) ?? e.toString())
              .join(', ');
          _drawCompactAnswer(ctx, message, labels.isEmpty ? '(none)' : labels);
          submit(pending ?? const []);
          return;
        }
        final widget = tui_select.Select<T>(
          id: Key.symbol(#__inline_multi),
          items: options,
          state: state,
          defaultValues: defaults,
          mode: tui_select.SelectionMode.multi,
          minSelections: minSelections,
          maxSelections: maxSelections,
          visibleCount: visibleCount,
          filterable: filterable,
          builder: (item, itemState) {
            final label = display?.call(item) ?? item.toString();
            final mark = itemState.isSelected ? '☒' : '☐';
            return Text(
              ' $mark $label',
              style: itemState.isActive ? const Style(bold: true) : null,
            );
          },
          onSubmit: (list) {
            pending = list;
            submitted = true;
          },
        );
        _drawWithHeader(ctx, message, widget,
            bodyHeight: _selectBodyHeight(options.length, visibleCount, filterable));
      },
      theme: _theme,
      terminal: _terminal(),
      allowNonInteractive: _allowNonInteractive,
    );
  }

  /// Asks a y/n question and returns the boolean answer.
  ///
  /// Enter submits the current default. Pressing `y`/`n` (case-insensitive)
  /// submits immediately.
  Future<bool> confirm(
    String message, {
    bool defaultValue = false,
  }) {
    bool? pending;
    var submitted = false;

    return runOneShot<bool>(
      (ctx, submit) {
        if (submitted) {
          _drawCompactAnswer(ctx, message, pending! ? 'Yes' : 'No');
          submit(pending!);
          return;
        }
        ctx.draw(
          Confirm(
            id: Key.symbol(#__inline_confirm),
            message: message,
            defaultValue: defaultValue,
            onSubmit: (v) {
              pending = v;
              submitted = true;
            },
          ),
          Rect(ctx.area.x, ctx.area.y, ctx.area.width, 1),
        );
      },
      theme: _theme,
      terminal: _terminal(),
      allowNonInteractive: _allowNonInteractive,
    );
  }

  /// Runs [work] while showing a spinner. The future's value is returned;
  /// thrown errors propagate to the caller after the terminal is restored.
  Future<T> task<T>(
    String description,
    Future<T> Function() work,
  ) async {
    T? result;
    Object? caughtError;
    StackTrace? caughtStack;
    final key = Key.symbol(#__inline_task);

    await runTerminal<Object?>(
      initialState: null,
      theme: _theme,
      terminal: _terminal(),
      mode: const RenderMode.flow(height: 1, autoGrow: true),
      allowNonInteractive: _allowNonInteractive,
      enableMouse: false,
      onEvent: (_, event, handle) {
        if (event is AsyncResolvedEvent && event.key == key) {
          handle.stop();
        }
      },
      render: (ctx, _) {
        ctx.draw(
          Async<T>(
            key: key,
            future: () async {
              try {
                final v = await work();
                result = v;
                return v;
              } catch (e, st) {
                caughtError = e;
                caughtStack = st;
                rethrow;
              }
            },
            onLoading: () => Spinner(label: description),
            onSuccess: (_) => Text(
              '✓ $description',
              style: Style(fg: ctx.theme.colors.success, bold: true),
            ),
            onError: (e, _) => Text(
              '✗ $description: $e',
              style: Style(fg: ctx.theme.colors.error, bold: true),
            ),
          ),
          Rect(ctx.area.x, ctx.area.y, ctx.area.width, 1),
        );
      },
    );

    if (caughtError != null) {
      Error.throwWithStackTrace(caughtError!, caughtStack ?? StackTrace.current);
    }
    return result as T;
  }

  // ---------------------------------------------------------------------------
  // Status helpers
  // ---------------------------------------------------------------------------

  void success(String message) => writeSuccess(message, sink: _sink);
  void info(String message) => writeInfo(message, sink: _sink);
  void warn(String message) => writeWarn(message, sink: _sink);
  void error(String message) => writeError(message, sink: _sink);

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _drawWithHeader(
    RenderContext ctx,
    String message,
    Widget body, {
    required int bodyHeight,
  }) {
    final width = ctx.area.width;
    ctx.draw(
      Text(
        '? $message',
        style: Style(fg: ctx.theme.colors.primary, bold: true),
      ),
      Rect(ctx.area.x, ctx.area.y, width, 1),
    );
    ctx.draw(body, Rect(ctx.area.x, ctx.area.y + 1, width, bodyHeight));
  }

  /// Renders the post-submit single line replacing the live widget:
  /// `✓ message value` (green check + plain message + bold value). The
  /// renderer's diff emits spaces over the rows previously occupied by
  /// the widget, so the options disappear from the terminal.
  void _drawCompactAnswer(RenderContext ctx, String message, String value) {
    final width = ctx.area.width;
    final theme = ctx.theme;
    ctx.draw(
      Row(
        spacing: 1,
        children: [
          Fixed(
            size: 1,
            child: Text('✓',
                style: Style(fg: theme.colors.success, bold: true)),
          ),
          Fixed(
            size: message.length,
            child: Text(message),
          ),
          Expanded(
            child: Text(value, style: const Style(bold: true)),
          ),
        ],
      ),
      Rect(ctx.area.x, ctx.area.y, width, 1),
    );
  }

  int _selectBodyHeight(int itemCount, int visibleCount, bool filterable) {
    final visible = visibleCount.clamp(1, itemCount);
    return visible + (filterable ? 1 : 0);
  }
}

