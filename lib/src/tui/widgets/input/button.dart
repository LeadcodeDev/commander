import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

class Button implements FocusableWidget {
  @override
  final Key id;
  final String label;
  final void Function()? onPressed;
  final Style? style;
  final Style? focusedStyle;

  const Button({
    required this.id,
    required this.label,
    this.onPressed,
    this.style,
    this.focusedStyle,
  });

  @override
  bool get isSkipped => false;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) {
    sink.add(area, id);
  }

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    if (event.key == NamedKey.enter || event.char == ' ') {
      onPressed?.call();
      return true;
    }
    return false;
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    final isFocused = ctx.isFocused(id);
    final s = isFocused
        ? (focusedStyle ?? Style(bg: ctx.theme.colors.primary, fg: ctx.theme.colors.background, bold: true))
        : (style ?? Style(fg: ctx.theme.colors.primary));
    final text = ' $label ';
    final mid = area.y + area.height ~/ 2;
    final tx = area.x + (area.width - text.length) ~/ 2;
    buffer.fillStyle(area, s);
    buffer.writeText(tx.clamp(area.x, area.right), mid, text, style: s, maxWidth: area.width);
  }
}
