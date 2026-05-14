import 'package:commander_ui/tui.dart';
import 'package:test/test.dart';

void main() {
  group('renderToBuffer', () {
    test('renders a simple text', () {
      final buf = renderToBuffer(
        const Text('Hello'),
        size: const Size(10, 1),
      );
      expect(buf.toPlainString().trim(), 'Hello');
    });

    test('renders a bordered container', () {
      final buf = renderToBuffer(
        const Container(border: BorderStyle.single, child: Text('Hi')),
        size: const Size(6, 3),
      );
      final out = buf.toPlainString();
      expect(out.split('\n').length, 3);
      expect(out, contains('Hi'));
    });

    test('renders centered text', () {
      final buf = renderToBuffer(
        const Center(child: Text('Hi')),
        size: const Size(10, 3),
      );
      final lines = buf.toPlainString().split('\n');
      expect(lines[1].contains('Hi'), isTrue);
    });
  });
}
