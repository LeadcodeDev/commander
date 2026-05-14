import 'package:commander_ui/tui.dart';
import 'package:test/test.dart';

Widget _builder(String item, CheckboxItemState s) =>
    Text('${s.isChecked ? '[x]' : '[ ]'} $item');

void main() {
  group('CheckboxGroup', () {
    test('defaultChecked pre-fills the set', () {
      final state = CheckboxGroupState<String>();
      final widget = CheckboxGroup<String>(
        id: Key.symbol(#g),
        items: const ['A', 'B', 'C'],
        state: state,
        builder: _builder,
        defaultChecked: const ['B'],
      );
      renderToBuffer(widget, size: const Size(20, 5));
      expect(state.checked, {'B'});
    });

    test('defaultChecked outside items is ignored', () {
      final state = CheckboxGroupState<String>();
      final widget = CheckboxGroup<String>(
        id: Key.symbol(#g),
        items: const ['A', 'B'],
        state: state,
        builder: _builder,
        defaultChecked: const ['A', 'Z'],
      );
      renderToBuffer(widget, size: const Size(20, 5));
      expect(state.checked, {'A'});
    });

    test('Space toggles checked state', () {
      final state = CheckboxGroupState<String>();
      final widget = CheckboxGroup<String>(
        id: Key.symbol(#g),
        items: const ['A', 'B', 'C'],
        state: state,
        builder: _builder,
      );
      final ctx = _ctx();
      widget.onKey(const KeyEvent(key: ' '), ctx);
      expect(state.checked, {'A'});
      widget.onKey(const KeyEvent(key: ' '), ctx);
      expect(state.checked, isEmpty);
    });

    test('navigation moves active index', () {
      final state = CheckboxGroupState<String>();
      final widget = CheckboxGroup<String>(
        id: Key.symbol(#g),
        items: const ['A', 'B', 'C'],
        state: state,
        builder: _builder,
      );
      final ctx = _ctx();
      widget.onKey(const KeyEvent(key: 'ArrowDown'), ctx);
      expect(state.activeIndex, 1);
      widget.onKey(const KeyEvent(key: 'ArrowDown'), ctx);
      widget.onKey(const KeyEvent(key: 'ArrowDown'), ctx);
      expect(state.activeIndex, 2);
      widget.onKey(const KeyEvent(key: 'ArrowUp'), ctx);
      expect(state.activeIndex, 1);
    });

    test('onChanged fires with the updated list', () {
      final state = CheckboxGroupState<String>();
      List<String>? lastChange;
      final widget = CheckboxGroup<String>(
        id: Key.symbol(#g),
        items: const ['A', 'B'],
        state: state,
        builder: _builder,
        onChanged: (v) => lastChange = v,
      );
      final ctx = _ctx();
      widget.onKey(const KeyEvent(key: ' '), ctx);
      expect(lastChange, ['A']);
      widget.onKey(const KeyEvent(key: 'ArrowDown'), ctx);
      widget.onKey(const KeyEvent(key: ' '), ctx);
      expect(lastChange!.toSet(), {'A', 'B'});
    });

    test('scroll keeps active in view', () {
      final state = CheckboxGroupState<String>();
      final items = List.generate(10, (i) => 'Item $i');
      final widget = CheckboxGroup<String>(
        id: Key.symbol(#g),
        items: items,
        state: state,
        builder: _builder,
      );
      final ctx = _ctx();
      for (var i = 0; i < 5; i++) {
        widget.onKey(const KeyEvent(key: 'ArrowDown'), ctx);
      }
      renderToBuffer(widget, size: const Size(20, 3));
      expect(state.scrollOffset, 3);
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
