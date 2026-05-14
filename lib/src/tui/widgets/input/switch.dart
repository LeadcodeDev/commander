import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

class Switch implements FocusableWidget {
  @override
  final Key id;
  final bool checked;
  final void Function(bool value)? onChanged;
  final String? label;
  final String onIndicator;
  final String offIndicator;
  final Style? onStyle;
  final Style? offStyle;

  const Switch({
    required this.id,
    required this.checked,
    this.onChanged,
    this.label,
    this.onIndicator = '[●━]',
    this.offIndicator = '[━●]',
    this.onStyle,
    this.offStyle,
  });

  @override
  bool get isSkipped => false;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) => sink.add(area, id);

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    if (event.key == ' ' || event.key == 'Enter') {
      onChanged?.call(!checked);
      return true;
    }
    return false;
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    final isFocused = ctx.isFocused(id);

    final indicator = checked ? onIndicator : offIndicator;
    final defaultOn = Style(fg: ctx.theme.colors.success, bold: true);
    final defaultOff = Style(fg: ctx.theme.colors.muted);
    final indicatorStyle = checked
        ? (onStyle ?? defaultOn)
        : (offStyle ?? defaultOff);

    final labelStyle = isFocused
        ? ctx.theme.text.body
            .copyWith(fg: ctx.theme.colors.primary, bold: true)
        : ctx.theme.text.body;

    buffer.writeText(area.x, area.y, indicator,
        style: indicatorStyle, maxWidth: area.width);

    if (label != null) {
      final lx = area.x + indicator.length + 1;
      if (lx < area.right) {
        buffer.writeText(lx, area.y, label!,
            style: labelStyle, maxWidth: area.right - lx);
      }
    }
  }
}
