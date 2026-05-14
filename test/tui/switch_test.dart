import 'package:commander_ui/tui.dart' as tui;
import 'package:commander_ui/tui.dart';
import 'package:test/test.dart';

void main() {
  group('Switch', () {
    test('renders ON indicator when checked', () {
      final w = tui.Switch(
        id: Key.symbol(#s),
        checked: true,
        label: 'Notifications',
      );
      final buf = renderToBuffer(w, size: const Size(30, 1));
      expect(buf.toPlainString(), contains('●━'));
      expect(buf.toPlainString(), contains('Notifications'));
    });

    test('renders OFF indicator when not checked', () {
      final w = tui.Switch(
        id: Key.symbol(#s),
        checked: false,
        label: 'Notifications',
      );
      final buf = renderToBuffer(w, size: const Size(30, 1));
      expect(buf.toPlainString(), contains('━●'));
    });

    test('Space toggles the value via onChanged', () {
      bool? newValue;
      final w = tui.Switch(
        id: Key.symbol(#s),
        checked: false,
        onChanged: (v) => newValue = v,
      );
      final ctx = _ctx();
      w.onKey(const KeyEvent(char: ' '), ctx);
      expect(newValue, isTrue);
    });

    test('Enter also toggles', () {
      bool? newValue;
      final w = tui.Switch(
        id: Key.symbol(#s),
        checked: true,
        onChanged: (v) => newValue = v,
      );
      final ctx = _ctx();
      w.onKey(const KeyEvent(key: NamedKey.enter), ctx);
      expect(newValue, isFalse);
    });

    test('other keys are not consumed', () {
      final w = tui.Switch(id: Key.symbol(#s), checked: false);
      final ctx = _ctx();
      expect(w.onKey(const KeyEvent(char: 'a'), ctx), isFalse);
      expect(w.onKey(const KeyEvent(key: NamedKey.tab), ctx), isFalse);
    });
  });
}

RenderContext _ctx() {
  final buffer = Buffer(const Size(20, 5));
  final focus = FocusController();
  return RenderContext(
    buffer: buffer,
    area: Rect(0, 0, 20, 5),
    theme: const ThemeData(),
    focus: focus,
    async_: AsyncRegistry(),
    logger: const SilentLogger(),
    requestRedraw: () {},
  );
}
