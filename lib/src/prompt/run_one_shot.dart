import '../tui/runtime/render_context.dart';
import '../tui/runtime/render_mode.dart';
import '../tui/runtime/run_terminal.dart';
import '../tui/terminal/terminal.dart';
import '../tui/theme/theme_data.dart';

class PromptCancelledException implements Exception {
  final String message;
  const PromptCancelledException([this.message = 'Prompt was cancelled']);
  @override
  String toString() => 'PromptCancelledException: $message';
}

typedef DrawFn<T> = void Function(
  RenderContext ctx,
  void Function(T value) submit,
);

/// Drives one prompt in flow mode and returns the value captured via the
/// `submit` callback passed to [draw]. The render loop ends as soon as
/// `submit` is called or the user presses Ctrl-C (which throws
/// [PromptCancelledException]).
Future<T> runOneShot<T>(
  DrawFn<T> draw, {
  ThemeData? theme,
  Terminal? terminal,
  bool allowNonInteractive = false,
}) async {
  T? captured;
  var isSet = false;

  await runTerminal<Object?>(
    initialState: null,
    theme: theme,
    terminal: terminal,
    mode: const RenderMode.flow(height: 1, autoGrow: true),
    allowNonInteractive: allowNonInteractive,
    enableMouse: false,
    onEvent: (_, __, ___) {},
    render: (ctx, _) {
      draw(ctx, (value) {
        captured = value;
        isSet = true;
        ctx.exit();
      });
    },
  );

  if (!isSet) {
    throw const PromptCancelledException();
  }

  return captured as T;
}
