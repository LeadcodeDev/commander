import '../../geometry/rect.dart';
import '../../layout/constraint.dart';
import '../../layout/layout.dart';
import '../../rendering/buffer.dart';
import '../../runtime/render_context.dart';
import '../../widget/widget.dart';

class Flexible {
  final int flex;
  final Widget child;
  const Flexible({this.flex = 1, required this.child});
}

class Fixed {
  final int size;
  final Widget child;
  const Fixed({required this.size, required this.child});
}

class Expanded extends Flexible {
  const Expanded({super.flex, required super.child});
}

class Row implements Widget {
  final List<Object> children;
  final int spacing;

  const Row({required this.children, this.spacing = 0});

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    final constraints = children.map(_toConstraint).toList(growable: false);
    final rects = Layout.horizontal(constraints, spacing: spacing).split(area);
    for (var i = 0; i < children.length; i++) {
      final child = _toWidget(children[i]);
      if (child != null && !rects[i].isEmpty) {
        ctx.draw(child, rects[i]);
      }
    }
  }
}

class Column implements Widget {
  final List<Object> children;
  final int spacing;

  const Column({required this.children, this.spacing = 0});

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    final constraints = children.map(_toConstraint).toList(growable: false);
    final rects = Layout.vertical(constraints, spacing: spacing).split(area);
    for (var i = 0; i < children.length; i++) {
      final child = _toWidget(children[i]);
      if (child != null && !rects[i].isEmpty) {
        ctx.draw(child, rects[i]);
      }
    }
  }
}

Constraint _toConstraint(Object item) {
  if (item is Fixed) return Constraint.length(item.size);
  if (item is Flexible) return Constraint.fill(item.flex);
  if (item is Widget) return const Constraint.fill(1);
  if (item is Constraint) return item;
  return const Constraint.fill(1);
}

Widget? _toWidget(Object item) {
  if (item is Widget) return item;
  if (item is Fixed) return item.child;
  if (item is Flexible) return item.child;
  return null;
}
