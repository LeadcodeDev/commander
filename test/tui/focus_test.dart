import 'package:commander_ui/tui.dart';
import 'package:test/test.dart';

void main() {
  group('FocusController', () {
    test('register + finalize sets first as current', () {
      final fc = FocusController();
      fc.resetFrame();
      fc.register(Key.symbol(#a));
      fc.register(Key.symbol(#b));
      fc.register(Key.symbol(#c));
      fc.finalizeFrame();
      expect(fc.current, Key.symbol(#a));
    });

    test('next cycles', () {
      final fc = FocusController();
      fc.resetFrame();
      fc.register(Key.symbol(#a));
      fc.register(Key.symbol(#b));
      fc.register(Key.symbol(#c));
      fc.finalizeFrame();
      fc.next();
      expect(fc.current, Key.symbol(#b));
      fc.next();
      expect(fc.current, Key.symbol(#c));
      fc.next();
      expect(fc.current, Key.symbol(#a));
    });

    test('previous wraps', () {
      final fc = FocusController();
      fc.resetFrame();
      fc.register(Key.symbol(#a));
      fc.register(Key.symbol(#b));
      fc.finalizeFrame();
      fc.previous();
      expect(fc.current, Key.symbol(#b));
    });

    test('focus orphan falls back to first', () {
      final fc = FocusController();
      fc.resetFrame();
      fc.register(Key.symbol(#a));
      fc.register(Key.symbol(#b));
      fc.finalizeFrame();
      fc.focus(Key.symbol(#b));
      fc.resetFrame();
      fc.register(Key.symbol(#a));
      fc.register(Key.symbol(#c));
      fc.finalizeFrame();
      expect(fc.current, Key.symbol(#a));
    });
  });

  group('Key equality', () {
    test('SymbolKey', () {
      expect(Key.symbol(#a), equals(Key.symbol(#a)));
      expect(Key.symbol(#a), isNot(equals(Key.symbol(#b))));
    });
    test('ValueKey', () {
      expect(Key.of('x'), equals(Key.of('x')));
      expect(Key.of('x'), isNot(equals(Key.of('y'))));
    });
    test('CompositeKey', () {
      expect(Key.composite([1, 'a']), equals(Key.composite([1, 'a'])));
      expect(Key.composite([1, 'a']), isNot(equals(Key.composite([1, 'b']))));
    });
  });
}
