import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/render_context.dart';
import '../../widget/widget.dart';

typedef ScreenBuilder = Widget Function(RenderContext ctx, void Function() exit);

class Screen implements Widget {
  final String title;
  final ScreenBuilder builder;
  final void Function()? onExit;

  const Screen({
    required this.title,
    required this.builder,
    this.onExit,
  });

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    ctx.setTitle(title);
    final child = builder(ctx, () => onExit?.call());
    ctx.draw(child, area);
  }
}
