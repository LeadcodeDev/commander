import 'package:commander_ui/tui.dart';
import 'package:test/test.dart';

Widget _builder<T>(T item, SelectItemState state) =>
    Text('${state.isSelected ? '*' : ' '} $item');

void main() {
  group('Select (inline)', () {
    test('renders items inline with placeholder when empty', () {
      final state = SelectState<String>();
      final widget = Select<String>(
        id: Key.symbol(#s),
        items: const [],
        state: state,
        builder: _builder,
        placeholder: 'No items here',
      );
      final buf = renderToBuffer(widget, size: const Size(30, 6));
      expect(buf.toPlainString(), contains('No items here'));
    });

    test('renders first visibleCount items', () {
      final state = SelectState<String>();
      final items = List.generate(10, (i) => 'Item $i');
      final widget = Select<String>(
        id: Key.symbol(#s),
        items: items,
        state: state,
        builder: _builder,
        visibleCount: 3,
      );
      final buf = renderToBuffer(widget, size: const Size(30, 5));
      final s = buf.toPlainString();
      expect(s, contains('Item 0'));
      expect(s, contains('Item 1'));
      expect(s, contains('Item 2'));
      expect(s, isNot(contains('Item 3')));
    });

    test('navigation scrolls when active goes past viewport', () {
      final state = SelectState<String>();
      final items = List.generate(10, (i) => 'Item $i');
      final widget = Select<String>(
        id: Key.symbol(#s),
        items: items,
        state: state,
        builder: _builder,
        visibleCount: 3,
      );
      final ctx = _ctx();

      for (var i = 0; i < 5; i++) {
        widget.onKey(const KeyEvent(key: 'ArrowDown'), ctx);
      }
      expect(state.activeIndex, 5);
      renderToBuffer(widget, size: const Size(30, 4));
      expect(state.scrollOffset, 3);
    });

    test('clamps visibleCount when parent is smaller', () {
      final state = SelectState<String>();
      final items = List.generate(10, (i) => 'Item $i');
      final widget = Select<String>(
        id: Key.symbol(#s),
        items: items,
        state: state,
        builder: _builder,
        visibleCount: 8,
      );
      final buf = renderToBuffer(widget, size: const Size(30, 3));
      final s = buf.toPlainString();
      expect(s, contains('Item 0'));
      expect(s, contains('Item 2'));
      expect(s, isNot(contains('Item 8')));
    });

    test('single mode: space selects, never deselects', () {
      final state = SelectState<String>();
      final widget = Select<String>(
        id: Key.symbol(#s),
        items: const ['A', 'B', 'C'],
        state: state,
        builder: _builder,
        mode: SelectionMode.single,
      );
      final ctx = _ctx();
      widget.onKey(const KeyEvent(key: ' '), ctx);
      expect(state.selected, {'A'});
      widget.onKey(const KeyEvent(key: ' '), ctx);
      expect(state.selected, {'A'}); // still A
      widget.onKey(const KeyEvent(key: 'ArrowDown'), ctx);
      widget.onKey(const KeyEvent(key: ' '), ctx);
      expect(state.selected, {'B'});
    });

    test('multi mode: space toggles, maxSelections refused', () {
      final state = SelectState<String>();
      final widget = Select<String>(
        id: Key.symbol(#s),
        items: const ['A', 'B', 'C', 'D'],
        state: state,
        builder: _builder,
        mode: SelectionMode.multi,
        maxSelections: 2,
      );
      final ctx = _ctx();
      widget.onKey(const KeyEvent(key: ' '), ctx);
      widget.onKey(const KeyEvent(key: 'ArrowDown'), ctx);
      widget.onKey(const KeyEvent(key: ' '), ctx);
      expect(state.selected, {'A', 'B'});
      widget.onKey(const KeyEvent(key: 'ArrowDown'), ctx);
      widget.onKey(const KeyEvent(key: ' '), ctx);
      expect(state.selected, {'A', 'B'}); // refused
      widget.onKey(const KeyEvent(key: 'ArrowUp'), ctx);
      widget.onKey(const KeyEvent(key: 'ArrowUp'), ctx);
      widget.onKey(const KeyEvent(key: ' '), ctx);
      expect(state.selected, {'B'}); // deselected A
    });

    test('multi mode: minSelections triggers validationError on submit', () {
      final state = SelectState<String>();
      List<String>? submitted;
      final widget = Select<String>(
        id: Key.symbol(#s),
        items: const ['A', 'B', 'C'],
        state: state,
        builder: _builder,
        mode: SelectionMode.multi,
        minSelections: 2,
        onSubmit: (v) => submitted = v,
      );
      final ctx = _ctx();
      widget.onKey(const KeyEvent(key: ' '), ctx);
      widget.onKey(const KeyEvent(key: 'Enter'), ctx);
      expect(submitted, isNull);
      expect(state.validationError, isNotNull);
      widget.onKey(const KeyEvent(key: 'ArrowDown'), ctx);
      widget.onKey(const KeyEvent(key: ' '), ctx);
      expect(state.validationError, isNull); // cleared on toggle
      widget.onKey(const KeyEvent(key: 'Enter'), ctx);
      expect(submitted, ['A', 'B']);
    });

    test('validate callback returning String shows error', () {
      final state = SelectState<String>();
      List<String>? submitted;
      final widget = Select<String>(
        id: Key.symbol(#s),
        items: const ['A', 'B'],
        state: state,
        builder: _builder,
        mode: SelectionMode.multi,
        validate: (sel) => sel.contains('A') ? null : 'Must include A',
        onSubmit: (v) => submitted = v,
      );
      final ctx = _ctx();
      widget.onKey(const KeyEvent(key: 'ArrowDown'), ctx);
      widget.onKey(const KeyEvent(key: ' '), ctx);
      widget.onKey(const KeyEvent(key: 'Enter'), ctx);
      expect(submitted, isNull);
      expect(state.validationError, 'Must include A');
    });

    test('default value pre-selects in single mode', () {
      final state = SelectState<String>();
      final widget = Select<String>(
        id: Key.symbol(#s),
        items: const ['A', 'B', 'C'],
        state: state,
        builder: _builder,
        defaultValue: 'B',
      );
      renderToBuffer(widget, size: const Size(20, 5));
      expect(state.selected, {'B'});
      expect(state.activeIndex, 1);
    });

    test('defaultValues outside items are ignored', () {
      final state = SelectState<String>();
      final widget = Select<String>(
        id: Key.symbol(#s),
        items: const ['A', 'B'],
        state: state,
        builder: _builder,
        mode: SelectionMode.multi,
        defaultValues: ['A', 'Z'],
      );
      renderToBuffer(widget, size: const Size(20, 5));
      expect(state.selected, {'A'});
    });

    test('filter narrows visible items', () {
      final state = SelectState<String>();
      final widget = Select<String>(
        id: Key.symbol(#s),
        items: const ['France', 'Germany', 'Italy'],
        state: state,
        builder: _builder,
        filterable: true,
      );
      final ctx = _ctx();
      state.filterFocused = true;
      widget.onKey(const KeyEvent(key: 'f'), ctx);
      widget.onKey(const KeyEvent(key: 'r'), ctx);
      expect(state.filterQuery, 'fr');
      final buf = renderToBuffer(widget, size: const Size(20, 6));
      final s = buf.toPlainString();
      expect(s, contains('France'));
      expect(s, isNot(contains('Germany')));
    });
  });
}

RenderContext _ctx() {
  final buffer = Buffer(const Size(30, 10));
  final focus = FocusController();
  return RenderContext(
    buffer: buffer,
    area: Rect(0, 0, 30, 10),
    theme: const ThemeData(),
    focus: focus,
    async_: AsyncRegistry(),
    logger: const SilentLogger(),
    requestRedraw: () {},
  );
}
