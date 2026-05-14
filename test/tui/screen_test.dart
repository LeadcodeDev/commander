import 'package:commander_ui/tui.dart';
import 'package:test/test.dart';

void main() {
  group('Screen', () {
    test('sets terminal title via ctx', () {
      final widget = Screen(
        title: 'My App',
        builder: (ctx, exit) => const Text('hello'),
      );
      final buffer = Buffer(const Size(20, 5));
      final focus = FocusController();
      final ctx = RenderContext(
        buffer: buffer,
        area: Rect(0, 0, 20, 5),
        theme: const ThemeData(),
        focus: focus,
        async_: AsyncRegistry(),
        logger: const SilentLogger(),
        requestRedraw: () {},
      );
      ctx.resetFrame();
      widget.render(ctx.area, buffer, ctx);
      expect(ctx.pendingTitle, 'My App');
    });

    test('builder content is drawn', () {
      final widget = Screen(
        title: 'X',
        builder: (ctx, exit) => const Text('Hello body'),
      );
      final buf = renderToBuffer(widget, size: const Size(30, 3));
      expect(buf.toPlainString(), contains('Hello body'));
    });

    test('exit callback invokes onExit', () {
      var exited = false;
      final widget = Screen(
        title: 'X',
        onExit: () => exited = true,
        builder: (ctx, exit) {
          exit();
          return const Text('');
        },
      );
      renderToBuffer(widget, size: const Size(20, 3));
      expect(exited, isTrue);
    });
  });
}
