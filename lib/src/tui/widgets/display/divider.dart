import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

enum DividerOrientation { horizontal, vertical }

class Divider implements Widget {
  final DividerOrientation orientation;
  final String char;
  final Style? style;

  const Divider({
    this.orientation = DividerOrientation.horizontal,
    this.char = '─',
    this.style,
  });

  factory Divider.vertical({String char = '│', Style? style}) =>
      Divider(orientation: DividerOrientation.vertical, char: char, style: style);

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    final s = style ?? ctx.theme.text.caption;
    if (orientation == DividerOrientation.horizontal) {
      for (var x = 0; x < area.width; x++) {
        buffer.setChar(area.x + x, area.y, char, style: s);
      }
    } else {
      for (var y = 0; y < area.height; y++) {
        buffer.setChar(area.x, area.y + y, char, style: s);
      }
    }
  }
}
