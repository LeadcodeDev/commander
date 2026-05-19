import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/render_context.dart';
import '../../widget/widget.dart';

class Each<T> implements Widget {
  final Iterable<T> items;
  final Widget Function(T item, int index) builder;
  final int Function(T item, int index)? heightOf;
  final bool Function(T item, int index)? where;
  final int spacing;

  const Each({
    required this.items,
    required this.builder,
    this.heightOf,
    this.where,
    this.spacing = 0,
  });

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    var y = area.y;
    var index = 0;
    for (final item in items) {
      if (where != null && !where!(item, index)) {
        index++;
        continue;
      }
      final h = heightOf?.call(item, index) ?? 1;
      if (h <= 0) {
        index++;
        continue;
      }
      final rect = Rect(area.x, y, area.width, h);
      ctx.draw(builder(item, index), rect);
      y += h + spacing;
      index++;
    }
  }
}
