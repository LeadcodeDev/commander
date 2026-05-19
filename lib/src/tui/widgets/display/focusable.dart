import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../widget/widget.dart';

typedef WidgetBuilder = Widget Function(bool isFocused);

class Focusable implements FocusableWidget {
  @override
  final Key id;
  final bool Function(KeyEvent event)? onKeyHandler;
  final WidgetBuilder builder;
  @override
  final bool isSkipped;

  const Focusable({
    required this.id,
    required this.builder,
    this.onKeyHandler,
    this.isSkipped = false,
  });

  @override
  bool onKey(KeyEvent event, RenderContext ctx) =>
      onKeyHandler?.call(event) ?? false;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) {
    sink.add(area, id);
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    builder(ctx.isFocused(id)).render(area, buffer, ctx);
  }
}
