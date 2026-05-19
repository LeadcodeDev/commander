import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/render_context.dart';
import '../../style/border.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';
import 'block.dart';

class EdgeInsets {
  final int top;
  final int right;
  final int bottom;
  final int left;
  const EdgeInsets({
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    this.left = 0,
  });
  const EdgeInsets.all(int v)
      : top = v,
        right = v,
        bottom = v,
        left = v;
  const EdgeInsets.symmetric({int vertical = 0, int horizontal = 0})
      : top = vertical,
        bottom = vertical,
        left = horizontal,
        right = horizontal;
}

class Container implements Widget {
  final BorderStyle? border;
  final String? title;
  final TitleAlign titleAlign;
  final EdgeInsets padding;
  final Style? fill;
  final Style? borderColor;
  final Widget? child;

  const Container({
    this.border,
    this.title,
    this.titleAlign = TitleAlign.left,
    this.padding = const EdgeInsets(),
    this.fill,
    this.borderColor,
    this.child,
  });

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    var inner = area;
    if (border != null) {
      final block = Block(
        borderStyle: border,
        title: title,
        titleAlign: titleAlign,
        borderColor: borderColor,
        fill: fill,
      );
      block.render(area, buffer, ctx);
      inner = block.inner(area);
    } else if (fill != null) {
      buffer.fillStyle(area, fill!);
    }
    inner = inner.inset(
      top: padding.top,
      right: padding.right,
      bottom: padding.bottom,
      left: padding.left,
    );
    if (child != null && !inner.isEmpty) {
      ctx.draw(child!, inner);
    }
  }
}
