import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

class ProgressBar implements Widget {
  final num value;
  final num max;
  final String? label;
  final Style? barStyle;
  final Style? trackStyle;
  final String fillChar;
  final String emptyChar;

  const ProgressBar({
    required this.value,
    this.max = 1.0,
    this.label,
    this.barStyle,
    this.trackStyle,
    this.fillChar = '█',
    this.emptyChar = '░',
  });

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    final ratio = max == 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    final filledWidth = (area.width * ratio).round();
    final bar = barStyle ?? Style(fg: ctx.theme.colors.success);
    final track = trackStyle ?? Style(fg: ctx.theme.colors.muted);
    for (var i = 0; i < area.width; i++) {
      final ch = i < filledWidth ? fillChar : emptyChar;
      final s = i < filledWidth ? bar : track;
      buffer.setChar(area.x + i, area.y, ch, style: s);
    }
    if (label != null && area.height >= 1) {
      final tx = area.x + (area.width - label!.length) ~/ 2;
      buffer.writeText(tx, area.y, label!,
          style: ctx.theme.text.body, maxWidth: area.width);
    }
  }
}
