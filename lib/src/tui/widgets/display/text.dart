import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

class Text implements Widget {
  final String text;
  final Style? style;
  final TextAlign align;

  const Text(this.text, {this.style, this.align = TextAlign.left});

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    final s = style ?? ctx.theme.text.body;
    final line = text.replaceAll('\n', ' ');
    var x = area.x;
    if (align != TextAlign.left) {
      final w = _measure(line, area.width);
      if (align == TextAlign.center) {
        x = area.x + (area.width - w) ~/ 2;
      } else if (align == TextAlign.right) {
        x = area.x + area.width - w;
      }
      if (x < area.x) x = area.x;
    }
    buffer.writeText(x, area.y, line, style: s, maxWidth: area.right - x);
  }

  static int _measure(String text, int max) {
    var w = 0;
    for (final r in text.runes) {
      if (r == 10 || r == 13) continue;
      final cw = r < 0x1100 ? 1 : 2;
      if (w + cw > max) return w;
      w += cw;
    }
    return w;
  }
}

enum TextAlign { left, center, right }
