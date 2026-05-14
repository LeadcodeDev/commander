import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

enum Wrap { none, char, word }

class Paragraph implements Widget {
  final String text;
  final Style? style;
  final Wrap wrap;

  const Paragraph(this.text, {this.style, this.wrap = Wrap.word});

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    final effectiveStyle = style ?? ctx.theme.text.body;
    final lines = _layout(text, area.width, wrap);
    for (var i = 0; i < lines.length && i < area.height; i++) {
      buffer.writeText(area.x, area.y + i, lines[i], style: effectiveStyle, maxWidth: area.width);
    }
  }

  static List<String> _layout(String text, int width, Wrap wrap) {
    if (width <= 0) return const [];
    final lines = <String>[];
    for (final raw in text.split('\n')) {
      if (wrap == Wrap.none) {
        lines.add(raw);
        continue;
      }
      if (wrap == Wrap.char) {
        var i = 0;
        while (i < raw.length) {
          final end = (i + width).clamp(0, raw.length);
          lines.add(raw.substring(i, end));
          i = end;
        }
        continue;
      }
      final words = raw.split(' ');
      var current = StringBuffer();
      var currentLen = 0;
      for (final w in words) {
        final wl = w.length;
        if (currentLen == 0) {
          current.write(w);
          currentLen = wl;
        } else if (currentLen + 1 + wl <= width) {
          current.write(' ');
          current.write(w);
          currentLen += 1 + wl;
        } else {
          lines.add(current.toString());
          current = StringBuffer(w);
          currentLen = wl;
        }
      }
      if (current.isNotEmpty) lines.add(current.toString());
    }
    return lines;
  }
}
