import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

class Gauge implements Widget {
  final num value;
  final num max;
  final String? label;
  final Style? style;

  const Gauge({
    required this.value,
    this.max = 100,
    this.label,
    this.style,
  });

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    final ratio = max == 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    final filled = (area.width * ratio).round();
    final s = style ?? Style(bg: ctx.theme.colors.primary);
    final pct = '${(ratio * 100).round()}%';
    final text = label != null ? '$label  $pct' : pct;
    for (var y = 0; y < area.height; y++) {
      for (var x = 0; x < filled && x < area.width; x++) {
        buffer.setChar(area.x + x, area.y + y, ' ', style: s);
      }
    }
    final tx = area.x + (area.width - text.length) ~/ 2;
    final ty = area.y + area.height ~/ 2;
    buffer.writeText(tx, ty, text,
        style: ctx.theme.text.body, maxWidth: area.width);
  }
}
