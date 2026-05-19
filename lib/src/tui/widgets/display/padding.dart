import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/render_context.dart';
import '../../widget/widget.dart';
import 'container.dart';

class Padding implements Widget {
  final EdgeInsets padding;
  final Widget child;

  const Padding({required this.padding, required this.child});

  Padding.all(int v, {required this.child}) : padding = EdgeInsets.all(v);

  Padding.symmetric({int vertical = 0, int horizontal = 0, required this.child})
      : padding =
            EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal);

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    final inner = area.inset(
      top: padding.top,
      right: padding.right,
      bottom: padding.bottom,
      left: padding.left,
    );
    if (inner.isEmpty) return;
    ctx.draw(child, inner);
  }
}
