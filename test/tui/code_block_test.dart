import 'package:commander_ui/tui.dart';
import 'package:test/test.dart';

void main() {
  group('CodeBlock', () {
    const code = '''line1
line2
line3
line4
line5''';

    test('non-scrollable widget is not focusable', () {
      const widget = CodeBlock(code: code);
      expect(widget.isSkipped, isTrue);
      expect(widget.scrollable, isFalse);
    });

    test('scrollable requires a state (assertion)', () {
      expect(
        () => CodeBlock(code: code, scrollable: true),
        throwsA(isA<AssertionError>()),
      );
    });

    test('non-scrollable truncates lines beyond area.height', () {
      const widget = CodeBlock(code: code);
      final buf = renderToBuffer(widget, size: const Size(20, 3));
      final s = buf.toPlainString();
      expect(s, contains('line1'));
      expect(s, contains('line2'));
      expect(s, contains('line3'));
      expect(s, isNot(contains('line4')));
    });

    test('scrollable with offset 0 starts at the first line', () {
      final state = CodeBlockState();
      final widget = CodeBlock(
        id: Key.symbol(#cb),
        code: code,
        scrollable: true,
        state: state,
      );
      final buf = renderToBuffer(widget, size: const Size(20, 2));
      expect(buf.toPlainString(), contains('line1'));
      expect(buf.toPlainString(), contains('line2'));
      expect(buf.toPlainString(), isNot(contains('line3')));
    });

    test('arrowDown advances scroll offset', () {
      final state = CodeBlockState();
      final widget = CodeBlock(
        id: Key.symbol(#cb),
        code: code,
        scrollable: true,
        state: state,
      );
      widget.onKey(const KeyEvent(key: NamedKey.arrowDown), _ctx());
      widget.onKey(const KeyEvent(key: NamedKey.arrowDown), _ctx());
      expect(state.scrollOffset, 2);
    });

    test('arrowUp does not go below 0', () {
      final state = CodeBlockState();
      final widget = CodeBlock(
        id: Key.symbol(#cb),
        code: code,
        scrollable: true,
        state: state,
      );
      widget.onKey(const KeyEvent(key: NamedKey.arrowUp), _ctx());
      expect(state.scrollOffset, 0);
    });

    test('End jumps to last line, Home returns to first', () {
      final state = CodeBlockState();
      final widget = CodeBlock(
        id: Key.symbol(#cb),
        code: code,
        scrollable: true,
        state: state,
      );
      widget.onKey(const KeyEvent(key: NamedKey.end), _ctx());
      expect(state.scrollOffset, 4);
      widget.onKey(const KeyEvent(key: NamedKey.home), _ctx());
      expect(state.scrollOffset, 0);
    });

    test('render with scroll offset shows the offset window', () {
      final state = CodeBlockState(scrollOffset: 2);
      final widget = CodeBlock(
        id: Key.symbol(#cb),
        code: code,
        scrollable: true,
        state: state,
      );
      final buf = renderToBuffer(widget, size: const Size(20, 2));
      final s = buf.toPlainString();
      expect(s, contains('line3'));
      expect(s, contains('line4'));
      expect(s, isNot(contains('line1')));
    });

    test('non-scrollable widget ignores key events', () {
      const widget = CodeBlock(code: code);
      final consumed =
          widget.onKey(const KeyEvent(key: NamedKey.arrowDown), _ctx());
      expect(consumed, isFalse);
    });
  });
}

RenderContext _ctx() {
  final buffer = Buffer(const Size(40, 5));
  final focus = FocusController();
  return RenderContext(
    buffer: buffer,
    area: Rect(0, 0, 40, 5),
    theme: const ThemeData(),
    focus: focus,
    async_: AsyncRegistry(),
    logger: const SilentLogger(),
    requestRedraw: () {},
  );
}
