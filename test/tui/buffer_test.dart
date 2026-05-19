import 'package:commander_ui/tui.dart';
import 'package:test/test.dart';

void main() {
  group('Buffer', () {
    test('writes text within bounds', () {
      final buf = Buffer(const Size(10, 3));
      buf.writeText(0, 0, 'Hello');
      expect(buf.get(0, 0).char, 'H');
      expect(buf.get(4, 0).char, 'o');
      expect(buf.get(5, 0).char, ' ');
    });

    test('truncates at right edge', () {
      final buf = Buffer(const Size(5, 1));
      buf.writeText(0, 0, 'Hello World');
      expect(buf.get(0, 0).char, 'H');
      expect(buf.get(4, 0).char, 'o');
    });

    test('clears properly', () {
      final buf = Buffer(const Size(3, 1));
      buf.writeText(0, 0, 'abc');
      buf.clear();
      expect(buf.get(0, 0).char, ' ');
      expect(buf.get(1, 0).char, ' ');
      expect(buf.get(2, 0).char, ' ');
    });
  });
}
