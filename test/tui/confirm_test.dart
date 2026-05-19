import 'package:commander_ui/tui.dart';
import 'package:test/test.dart';

void main() {
  group('Confirm', () {
    test('renders message and (y/N) hint when default is false', () {
      final widget = Confirm(
        id: Key.symbol(#c),
        message: 'Continue?',
        defaultValue: false,
      );
      final buf = renderToBuffer(widget, size: const Size(40, 1));
      final s = buf.toPlainString();
      expect(s, contains('?'));
      expect(s, contains('Continue?'));
      expect(s, contains('(y/N)'));
    });

    test('renders (Y/n) hint when default is true', () {
      final widget = Confirm(
        id: Key.symbol(#c),
        message: 'Continue?',
        defaultValue: true,
      );
      final buf = renderToBuffer(widget, size: const Size(40, 1));
      expect(buf.toPlainString(), contains('(Y/n)'));
    });

    test("'y' submits true", () {
      bool? submitted;
      final widget = Confirm(
        id: Key.symbol(#c),
        message: 'OK?',
        onSubmit: (v) => submitted = v,
      );
      widget.onKey(const KeyEvent(char: 'y'), _ctx());
      expect(submitted, isTrue);
    });

    test("'N' (uppercase) submits false", () {
      bool? submitted;
      final widget = Confirm(
        id: Key.symbol(#c),
        message: 'OK?',
        onSubmit: (v) => submitted = v,
      );
      widget.onKey(const KeyEvent(char: 'N'), _ctx());
      expect(submitted, isFalse);
    });

    test('Enter submits the defaultValue', () {
      bool? submitted;
      final widget = Confirm(
        id: Key.symbol(#c),
        message: 'OK?',
        defaultValue: true,
        onSubmit: (v) => submitted = v,
      );
      widget.onKey(const KeyEvent(key: NamedKey.enter), _ctx());
      expect(submitted, isTrue);
    });

    test('unrelated keys are not consumed and never call onSubmit', () {
      var calls = 0;
      final widget = Confirm(
        id: Key.symbol(#c),
        message: 'OK?',
        onSubmit: (_) => calls++,
      );
      final consumed = widget.onKey(const KeyEvent(char: 'x'), _ctx());
      expect(consumed, isFalse);
      expect(calls, 0);
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
