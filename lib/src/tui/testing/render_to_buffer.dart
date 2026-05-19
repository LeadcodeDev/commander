import '../geometry/rect.dart';
import '../geometry/size.dart';
import '../rendering/buffer.dart';
import '../runtime/async_registry.dart';
import '../runtime/focus_controller.dart';
import '../runtime/logger.dart';
import '../runtime/render_context.dart';
import '../theme/theme_data.dart';
import '../widget/widget.dart';

Buffer renderToBuffer(Widget widget,
    {Size size = const Size(80, 24), ThemeData? theme}) {
  final buffer = Buffer(size);
  final focus = FocusController();
  final async_ = AsyncRegistry();
  focus.resetFrame();
  async_.beginFrame();
  final ctx = RenderContext(
    buffer: buffer,
    area: Rect(0, 0, size.width, size.height),
    theme: theme ?? const ThemeData(),
    focus: focus,
    async_: async_,
    logger: const SilentLogger(),
    requestRedraw: () {},
  );
  ctx.resetFrame();
  widget.render(ctx.area, buffer, ctx);
  focus.finalizeFrame();
  async_.endFrame();
  return buffer;
}

extension BufferAnsi on Buffer {
  String toAnsiString() {
    final sb = StringBuffer();
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final cell = get(x, y);
        if (cell.width == 0) continue;
        sb.write(cell.char.isEmpty ? ' ' : cell.char);
      }
      if (y < height - 1) sb.writeln();
    }
    return sb.toString();
  }
}
