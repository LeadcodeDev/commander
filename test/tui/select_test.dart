import 'package:commander_ui/tui.dart';
import 'package:test/test.dart';

void main() {
  group('Select', () {
    test('opens on Enter and renders dropdown overlay', () {
      final selectState = SelectState();
      final widget = Select<String>(
        id: Key.symbol(#test),
        options: const ['Alpha', 'Beta', 'Gamma'],
        state: selectState,
        placeholder: 'Pick one',
      );

      // Initial state: closed
      expect(selectState.open, isFalse);

      // Simulate Enter via onKey
      final dummyBuffer = renderToBuffer(widget, size: const Size(30, 10));
      expect(dummyBuffer.toPlainString(), contains('▼'));
      expect(dummyBuffer.toPlainString(), contains('Pick one'));

      // Open the dropdown
      selectState.open = true;
      final openBuffer = _renderWithOverlays(widget, const Size(30, 10));
      expect(openBuffer.toPlainString(), contains('▲'));
      expect(openBuffer.toPlainString(), contains('Alpha'));
      expect(openBuffer.toPlainString(), contains('Beta'));
      expect(openBuffer.toPlainString(), contains('Gamma'));
    });

    test('onKey opens on Enter and Space, navigates on arrows', () {
      final selectState = SelectState();
      final widget = Select<String>(
        id: Key.symbol(#test),
        options: const ['A', 'B', 'C'],
        state: selectState,
      );

      final fakeCtx = _renderContextOnly(const Size(30, 10));
      expect(widget.onKey(const KeyEvent(key: 'Enter'), fakeCtx), isTrue);
      expect(selectState.open, isTrue);

      expect(widget.onKey(const KeyEvent(key: 'ArrowDown'), fakeCtx), isTrue);
      expect(selectState.highlightedIndex, 1);
      expect(widget.onKey(const KeyEvent(key: 'ArrowUp'), fakeCtx), isTrue);
      expect(selectState.highlightedIndex, 0);

      expect(widget.onKey(const KeyEvent(key: 'Escape'), fakeCtx), isTrue);
      expect(selectState.open, isFalse);
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

