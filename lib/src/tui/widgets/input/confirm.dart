import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

/// A single-line y/n prompt. Pressing `y` / `n` (case-insensitive) submits
/// the corresponding boolean; pressing `Enter` submits [defaultValue].
///
/// Stateless on the framework side: the caller owns the boolean answer.
/// Rendered as `? message (Y/n)` or `? message (y/N)` depending on the
/// default. The widget occupies a single row.
class Confirm implements FocusableWidget, SizedWidget {
  @override
  final Key id;
  final String message;
  final bool defaultValue;
  final void Function(bool value)? onSubmit;

  final String askPrefix;
  final Style? askPrefixStyle;
  final Style? messageStyle;
  final Style? hintStyle;

  const Confirm({
    required this.id,
    required this.message,
    this.defaultValue = false,
    this.onSubmit,
    this.askPrefix = '?',
    this.askPrefixStyle,
    this.messageStyle,
    this.hintStyle,
  });

  @override
  int get height => 1;

  @override
  bool get isSkipped => false;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) => sink.add(area, id);

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    final ch = event.char?.toLowerCase();
    if (ch == 'y') {
      onSubmit?.call(true);
      return true;
    }
    if (ch == 'n') {
      onSubmit?.call(false);
      return true;
    }
    if (event.key == NamedKey.enter) {
      onSubmit?.call(defaultValue);
      return true;
    }
    return false;
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    final theme = ctx.theme;
    final hint = defaultValue ? '(Y/n)' : '(y/N)';
    final prefixStyle =
        askPrefixStyle ?? Style(fg: theme.colors.primary, bold: true);
    final msgStyle = messageStyle ?? theme.text.body;
    final hStyle = hintStyle ?? theme.text.caption;

    var x = area.x;
    buffer.writeText(x, area.y, askPrefix,
        style: prefixStyle, maxWidth: area.right - x);
    x += askPrefix.length + 1;
    if (x < area.right) {
      buffer.writeText(x, area.y, message,
          style: msgStyle, maxWidth: area.right - x);
      x += message.length + 1;
    }
    if (x < area.right) {
      buffer.writeText(x, area.y, hint,
          style: hStyle, maxWidth: area.right - x);
    }
  }
}
