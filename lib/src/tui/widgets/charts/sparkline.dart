import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

/// Single-row line chart using Unicode block characters.
///
/// Heights: ▁ ▂ ▃ ▄ ▅ ▆ ▇ █ (8 levels).
class Sparkline implements Widget {
  static const _blocks = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'];

  final List<num> values;
  final num? min;
  final num? max;
  final Style? lineStyle;

  const Sparkline({
    required this.values,
    this.min,
    this.max,
    this.lineStyle,
  });

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty || values.isEmpty) return;
    final style = lineStyle ?? Style(fg: ctx.theme.colors.primary);

    num lo = min ?? values.first;
    num hi = max ?? values.first;
    if (min == null || max == null) {
      for (final v in values) {
        if (v < lo) lo = v;
        if (v > hi) hi = v;
      }
    }
    final span = hi - lo;

    // If values.length > area.width, downsample by averaging buckets.
    final n = area.width;
    final samples = <num>[];
    if (values.length <= n) {
      samples.addAll(values);
    } else {
      for (var i = 0; i < n; i++) {
        final start = (i * values.length / n).floor();
        final end = ((i + 1) * values.length / n).ceil();
        var sum = 0.0;
        var count = 0;
        for (var j = start; j < end && j < values.length; j++) {
          sum += values[j];
          count++;
        }
        samples.add(count == 0 ? 0 : sum / count);
      }
    }

    for (var i = 0; i < samples.length && i < n; i++) {
      final v = samples[i];
      final level = span == 0
          ? _blocks.length ~/ 2
          : ((v - lo) / span * (_blocks.length - 1)).round().clamp(0, _blocks.length - 1);
      buffer.setChar(area.x + i, area.y, _blocks[level], style: style);
    }
  }
}
