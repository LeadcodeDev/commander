import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/render_context.dart';
import '../../widget/widget.dart';

class Stack implements Widget {
  final List<Widget> children;
  const Stack({required this.children});

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    for (final c in children) {
      ctx.draw(c, area);
    }
  }
}

class Positioned implements Widget {
  final int? left;
  final int? top;
  final int? width;
  final int? height;
  final Widget child;
  const Positioned({this.left, this.top, this.width, this.height, required this.child});

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    final x = area.x + (left ?? 0);
    final y = area.y + (top ?? 0);
    final w = width ?? area.width - (left ?? 0);
    final h = height ?? area.height - (top ?? 0);
    ctx.draw(child, Rect(x, y, w, h));
  }
}

class Align implements Widget {
  final Alignment alignment;
  final int? width;
  final int? height;
  final Widget child;
  const Align({this.alignment = Alignment.center, this.width, this.height, required this.child});

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    final w = width ?? area.width;
    final h = height ?? area.height;
    final ax = switch (alignment.horizontal) {
      -1 => area.x,
      1 => area.right - w,
      _ => area.x + (area.width - w) ~/ 2,
    };
    final ay = switch (alignment.vertical) {
      -1 => area.y,
      1 => area.bottom - h,
      _ => area.y + (area.height - h) ~/ 2,
    };
    ctx.draw(child, Rect(ax, ay, w, h));
  }
}

class Alignment {
  final int horizontal;
  final int vertical;
  const Alignment(this.horizontal, this.vertical);

  static const center = Alignment(0, 0);
  static const topLeft = Alignment(-1, -1);
  static const topRight = Alignment(1, -1);
  static const bottomLeft = Alignment(-1, 1);
  static const bottomRight = Alignment(1, 1);
  static const topCenter = Alignment(0, -1);
  static const bottomCenter = Alignment(0, 1);
  static const centerLeft = Alignment(-1, 0);
  static const centerRight = Alignment(1, 0);
}

class Center implements Widget {
  final Widget child;
  final int? width;
  final int? height;
  const Center({required this.child, this.width, this.height});

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    final h = height ?? 1;
    final w = width ?? area.width;
    final ax = area.x + (area.width - w) ~/ 2;
    final ay = area.y + (area.height - h) ~/ 2;
    ctx.draw(child, Rect(ax, ay, w, h));
  }
}
