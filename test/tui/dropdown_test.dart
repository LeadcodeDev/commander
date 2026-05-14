import 'package:commander_ui/tui.dart';
import 'package:test/test.dart';

void main() {
  group('Dropdown', () {
    test('opens on Enter and renders dropdown overlay', () {
      final dropState = DropdownState();
      final widget = Dropdown<String>(
        id: Key.symbol(#test),
        options: const ['Alpha', 'Beta', 'Gamma'],
        state: dropState,
        placeholder: 'Pick one',
      );

      expect(dropState.open, isFalse);

      final dummyBuffer = renderToBuffer(widget, size: const Size(30, 10));
      expect(dummyBuffer.toPlainString(), contains('▼'));
      expect(dummyBuffer.toPlainString(), contains('Pick one'));

      dropState.open = true;
      final openBuffer = _renderWithOverlays(widget, const Size(30, 10));
      expect(openBuffer.toPlainString(), contains('▲'));
      expect(openBuffer.toPlainString(), contains('Alpha'));
      expect(openBuffer.toPlainString(), contains('Beta'));
      expect(openBuffer.toPlainString(), contains('Gamma'));
    });

    test('onKey opens on Enter, navigates on arrows, closes on Escape', () {
      final dropState = DropdownState();
      final widget = Dropdown<String>(
        id: Key.symbol(#test),
        options: const ['A', 'B', 'C'],
        state: dropState,
      );

      final fakeCtx = _renderContextOnly(const Size(30, 10));
      expect(widget.onKey(const KeyEvent(key: 'Enter'), fakeCtx), isTrue);
      expect(dropState.open, isTrue);

      expect(widget.onKey(const KeyEvent(key: 'ArrowDown'), fakeCtx), isTrue);
      expect(dropState.highlightedIndex, 1);
      expect(widget.onKey(const KeyEvent(key: 'ArrowUp'), fakeCtx), isTrue);
      expect(dropState.highlightedIndex, 0);

      expect(widget.onKey(const KeyEvent(key: 'Escape'), fakeCtx), isTrue);
      expect(dropState.open, isFalse);
    });
  });
}

Buffer _renderWithOverlays(Widget widget, Size size) {
  final buffer = Buffer(size);
  final focus = FocusController();
  focus.resetFrame();
  final ctx = RenderContext(
    buffer: buffer,
    area: Rect(0, 0, size.width, size.height),
    theme: const ThemeData(),
    focus: focus,
    async_: AsyncRegistry(),
    logger: const SilentLogger(),
    requestRedraw: () {},
  );
  ctx.resetFrame();
  ctx.draw(widget, ctx.area);
  ctx.flushOverlays();
  focus.finalizeFrame();
  return buffer;
}

RenderContext _renderContextOnly(Size size) {
  final buffer = Buffer(size);
  final focus = FocusController();
  return RenderContext(
    buffer: buffer,
    area: Rect(0, 0, size.width, size.height),
    theme: const ThemeData(),
    focus: focus,
    async_: AsyncRegistry(),
    logger: const SilentLogger(),
    requestRedraw: () {},
  );
}
