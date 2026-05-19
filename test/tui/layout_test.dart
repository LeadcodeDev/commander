import 'package:commander_ui/tui.dart';
import 'package:test/test.dart';

void main() {
  group('Layout', () {
    test('vertical with length + fill + length', () {
      final rects = Layout.vertical([
        const Constraint.length(3),
        const Constraint.fill(1),
        const Constraint.length(1),
      ]).split(const Rect(0, 0, 80, 24));
      expect(rects.length, 3);
      expect(rects[0].height, 3);
      expect(rects[2].height, 1);
      expect(rects[1].height, 20);
    });

    test('horizontal percentage + fill', () {
      final rects = Layout.horizontal([
        const Constraint.percentage(30),
        const Constraint.fill(1),
      ]).split(const Rect(0, 0, 100, 10));
      expect(rects[0].width, 30);
      expect(rects[1].width, 70);
    });

    test('zero area returns zero rects', () {
      final rects = Layout.vertical([
        const Constraint.length(3),
        const Constraint.fill(1),
      ]).split(const Rect.zero());
      expect(rects.every((r) => r.isEmpty), isTrue);
    });

    test('fill weights all zero do not divide by zero', () {
      final rects = Layout.horizontal([
        const Constraint.fill(0),
        const Constraint.fill(0),
      ]).split(const Rect(0, 0, 10, 1));
      expect(rects.length, 2);
      expect(rects[0].width + rects[1].width, 10);
    });
  });
}
