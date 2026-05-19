import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

class BarDatum {
  final String label;
  final num value;
  final Style? style;
  const BarDatum(this.label, this.value, {this.style});
}

enum BarOrientation { vertical, horizontal }

class BarChart implements Widget {
  static const _verticalBlocks = [
    '▁',
    '▂',
    '▃',
    '▄',
    '▅',
    '▆',
    '▇',
    '█',
  ];

  final List<BarDatum> data;
  final BarOrientation orientation;
  final num? min;
  final num? max;
  final bool showLabels;
  final bool showValues;
  final int barWidth;
  final int gap;
  final Style? defaultBarStyle;
  final Style? labelStyle;
  final Style? valueStyle;
  final String Function(num value)? formatValue;

  const BarChart({
    required this.data,
    this.orientation = BarOrientation.vertical,
    this.min,
    this.max,
    this.showLabels = true,
    this.showValues = false,
    this.barWidth = 2,
    this.gap = 1,
    this.defaultBarStyle,
    this.labelStyle,
    this.valueStyle,
    this.formatValue,
  }) : assert(barWidth > 0 && gap >= 0);

  String _fmt(num v) {
    if (formatValue != null) return formatValue!(v);
    if (v is int || (v is double && v == v.roundToDouble())) {
      return v.toInt().toString();
    }
    return v.toStringAsFixed(1);
  }

  (num, num) _range() {
    var lo = min ?? 0;
    var hi = max;
    if (hi == null) {
      hi = data.isEmpty ? 1 : data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
      if (hi == lo) hi = lo + 1;
    }
    return (lo, hi);
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty || data.isEmpty) return;
    if (orientation == BarOrientation.vertical) {
      _renderVertical(area, buffer, ctx);
    } else {
      _renderHorizontal(area, buffer, ctx);
    }
  }

  void _renderVertical(Rect area, Buffer buffer, RenderContext ctx) {
    final (lo, hi) = _range();
    final span = hi - lo;
    final labelRow = showLabels ? 1 : 0;
    final valueRow = showValues ? 1 : 0;
    final barHeight = area.height - labelRow - valueRow;
    if (barHeight <= 0) return;

    final baseStyle = defaultBarStyle ?? Style(fg: ctx.theme.colors.primary);
    final lStyle = labelStyle ?? Style(fg: ctx.theme.colors.muted);
    final vStyle = valueStyle ?? ctx.theme.text.body;

    var x = area.x;
    for (final d in data) {
      if (x + barWidth > area.right) break;
      final ratio = span == 0 ? 0.0 : ((d.value - lo) / span).clamp(0.0, 1.0);
      // Fractional height in eighths.
      final eighths = (ratio * barHeight * 8).round();
      final fullCells = eighths ~/ 8;
      final partial = eighths % 8;
      final style = d.style ?? baseStyle;

      final baseY = area.y + barHeight - 1 + (showValues ? 1 : 0);
      for (var i = 0; i < fullCells; i++) {
        final y = baseY - i;
        if (y < area.y) break;
        for (var bx = 0; bx < barWidth; bx++) {
          buffer.setChar(x + bx, y, '█', style: style);
        }
      }
      if (partial > 0 && fullCells < barHeight) {
        final y = baseY - fullCells;
        for (var bx = 0; bx < barWidth; bx++) {
          buffer.setChar(x + bx, y, _verticalBlocks[partial - 1], style: style);
        }
      }

      if (showValues) {
        final txt = _fmt(d.value);
        final tx = x + (barWidth - txt.length) ~/ 2;
        buffer.writeText(tx.clamp(area.x, area.right - txt.length), area.y,
            txt, style: vStyle, maxWidth: txt.length);
      }
      if (showLabels) {
        final lbl = d.label;
        final clipped = lbl.length > barWidth + gap
            ? lbl.substring(0, barWidth + gap)
            : lbl;
        buffer.writeText(x, area.y + area.height - 1, clipped,
            style: lStyle, maxWidth: clipped.length);
      }

      x += barWidth + gap;
    }
  }

  void _renderHorizontal(Rect area, Buffer buffer, RenderContext ctx) {
    final (lo, hi) = _range();
    final span = hi - lo;
    final labelWidth = showLabels
        ? data.map((d) => d.label.length).fold<int>(0, (a, b) => a > b ? a : b)
        : 0;
    final valueWidth = showValues
        ? data.map((d) => _fmt(d.value).length).fold<int>(0, (a, b) => a > b ? a : b)
        : 0;
    final padding = (showLabels ? 1 : 0) + (showValues ? 1 : 0);
    final barAvail = area.width - labelWidth - valueWidth - padding;
    if (barAvail <= 0) return;

    final baseStyle = defaultBarStyle ?? Style(fg: ctx.theme.colors.primary);
    final lStyle = labelStyle ?? Style(fg: ctx.theme.colors.muted);
    final vStyle = valueStyle ?? ctx.theme.text.body;

    var y = area.y;
    for (final d in data) {
      if (y >= area.bottom) break;
      var x = area.x;
      if (showLabels) {
        buffer.writeText(x, y, d.label.padRight(labelWidth),
            style: lStyle, maxWidth: labelWidth);
        x += labelWidth + 1;
      }

      final ratio = span == 0 ? 0.0 : ((d.value - lo) / span).clamp(0.0, 1.0);
      final eighths = (ratio * barAvail * 8).round();
      final full = eighths ~/ 8;
      final partial = eighths % 8;
      final style = d.style ?? baseStyle;

      for (var i = 0; i < full; i++) {
        buffer.setChar(x + i, y, '█', style: style);
      }
      if (partial > 0 && full < barAvail) {
        // Horizontal partial uses left blocks.
        const leftBlocks = ['▏', '▎', '▍', '▌', '▋', '▊', '▉'];
        buffer.setChar(x + full, y, leftBlocks[partial - 1], style: style);
      }
      x += barAvail;

      if (showValues) {
        x += 1;
        final txt = _fmt(d.value);
        buffer.writeText(x, y, txt, style: vStyle, maxWidth: valueWidth);
      }

      y += 1;
    }
  }
}
