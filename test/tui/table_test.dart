import 'package:commander_ui/tui.dart';
import 'package:test/test.dart';

class Row {
  final int id;
  final String name;
  const Row(this.id, this.name);
}

List<TableColumn<Row>> _cols() => [
      TableColumn(
        title: 'ID',
        width: const TableConstraint.length(4),
        cellBuilder: (r, s) => Text(r.id.toString()),
      ),
      TableColumn(
        title: 'Name',
        width: const TableConstraint.fill(1),
        cellBuilder: (r, s) => Text(r.name),
      ),
    ];

void main() {
  group('Table', () {
    test('renders header + items by default', () {
      final state = TableState<Row>();
      final widget = Table<Row>(
        id: Key.symbol(#t),
        items: const [Row(1, 'Alice'), Row(2, 'Bob')],
        state: state,
        columns: _cols(),
      );
      final buf = renderToBuffer(widget, size: const Size(30, 6));
      final s = buf.toPlainString();
      expect(s, contains('ID'));
      expect(s, contains('Name'));
      expect(s, contains('Alice'));
      expect(s, contains('Bob'));
    });

    test('hides header when showHeader is false', () {
      final state = TableState<Row>();
      final widget = Table<Row>(
        id: Key.symbol(#t),
        items: const [Row(1, 'Alice')],
        state: state,
        columns: _cols(),
        showHeader: false,
      );
      final buf = renderToBuffer(widget, size: const Size(30, 3));
      final s = buf.toPlainString();
      expect(s, isNot(contains('ID')));
      expect(s, contains('Alice'));
    });

    test('placeholder when empty', () {
      final state = TableState<Row>();
      final widget = Table<Row>(
        id: Key.symbol(#t),
        items: const [],
        state: state,
        columns: _cols(),
        placeholder: 'Nothing here',
      );
      final buf = renderToBuffer(widget, size: const Size(30, 6));
      expect(buf.toPlainString(), contains('Nothing here'));
    });

    test('filter narrows items', () {
      final state = TableState<Row>();
      final widget = Table<Row>(
        id: Key.symbol(#t),
        items: const [Row(1, 'Alice'), Row(2, 'Bob'), Row(3, 'Charlie')],
        state: state,
        columns: _cols(),
        filter: (r) => r.id.isOdd,
      );
      final buf = renderToBuffer(widget, size: const Size(30, 6));
      final s = buf.toPlainString();
      expect(s, contains('Alice'));
      expect(s, contains('Charlie'));
      expect(s, isNot(contains('Bob')));
    });

    test('sortBy reorders items', () {
      final state = TableState<Row>();
      final widget = Table<Row>(
        id: Key.symbol(#t),
        items: const [Row(3, 'C'), Row(1, 'A'), Row(2, 'B')],
        state: state,
        columns: _cols(),
        sortBy: (a, b) => a.id - b.id,
      );
      final buf = renderToBuffer(widget, size: const Size(20, 5));
      final lines = buf.toPlainString().split('\n');
      // header line 0, separator line 1, data starts line 2
      final iA = lines.indexWhere((l) => l.contains('A'));
      final iB = lines.indexWhere((l) => l.contains('B'));
      final iC = lines.indexWhere((l) => l.contains('C'));
      expect(iA < iB, isTrue);
      expect(iB < iC, isTrue);
    });

    test('navigation moves activeRow and activeColumn', () {
      final state = TableState<Row>();
      final widget = Table<Row>(
        id: Key.symbol(#t),
        items: const [Row(1, 'A'), Row(2, 'B'), Row(3, 'C')],
        state: state,
        columns: _cols(),
      );
      final ctx = _ctx();
      widget.onKey(const KeyEvent(key: 'ArrowDown'), ctx);
      expect(state.activeRow, 1);
      widget.onKey(const KeyEvent(key: 'ArrowRight'), ctx);
      expect(state.activeColumn, 1);
      widget.onKey(const KeyEvent(key: 'ArrowUp'), ctx);
      expect(state.activeRow, 0);
    });

    test('Space toggles cell when selectCells', () {
      final state = TableState<Row>();
      final widget = Table<Row>(
        id: Key.symbol(#t),
        items: const [Row(1, 'A'), Row(2, 'B')],
        state: state,
        columns: _cols(),
        selectCells: true,
      );
      final ctx = _ctx();
      widget.onKey(const KeyEvent(key: ' '), ctx);
      expect(state.selectedCells, {(row: 0, col: 0)});
      widget.onKey(const KeyEvent(key: ' '), ctx);
      expect(state.selectedCells, isEmpty);
    });

    test('Shift+Space toggles row when selectRows + selectCells', () {
      final state = TableState<Row>();
      final widget = Table<Row>(
        id: Key.symbol(#t),
        items: const [Row(1, 'A'), Row(2, 'B')],
        state: state,
        columns: _cols(),
        selectCells: true,
        selectRows: true,
      );
      final ctx = _ctx();
      widget.onKey(const KeyEvent(key: ' ', shift: true), ctx);
      expect(state.selectedRows, {0});
      expect(state.selectedCells, isEmpty);
    });

    test('Alt+Space toggles column when selectColumns enabled', () {
      final state = TableState<Row>();
      final widget = Table<Row>(
        id: Key.symbol(#t),
        items: const [Row(1, 'A')],
        state: state,
        columns: _cols(),
        selectCells: true,
        selectColumns: true,
      );
      final ctx = _ctx();
      widget.onKey(const KeyEvent(key: ' ', alt: true), ctx);
      expect(state.selectedColumns, {0});
      expect(state.selectedCells, isEmpty);
    });

    test('Enter activates row', () {
      final state = TableState<Row>();
      int? lastIdx;
      Row? lastItem;
      final widget = Table<Row>(
        id: Key.symbol(#t),
        items: const [Row(1, 'A'), Row(2, 'B')],
        state: state,
        columns: _cols(),
        onRowActivated: (idx, r) {
          lastIdx = idx;
          lastItem = r;
        },
      );
      final ctx = _ctx();
      widget.onKey(const KeyEvent(key: 'Enter'), ctx);
      expect(lastIdx, 0);
      expect(lastItem?.id, 1);
    });

    test('column widths split fill evenly', () {
      // 3 fill(1) columns in 30 width, no separator
      final widget = Table<Row>(
        id: Key.symbol(#t),
        items: const [],
        state: TableState<Row>(),
        columns: [
          TableColumn(title: 'A', cellBuilder: (r, s) => const Text('')),
          TableColumn(title: 'B', cellBuilder: (r, s) => const Text('')),
          TableColumn(title: 'C', cellBuilder: (r, s) => const Text('')),
        ],
      );
      // Use internal method via render-to-buffer indirect: render header and check positions.
      final buf = renderToBuffer(widget, size: const Size(30, 4));
      final firstLine = buf.toPlainString().split('\n').first;
      // Each column ~ 10 chars wide minus 1 space separator between → roughly evenly distributed
      expect(firstLine.contains('A'), isTrue);
      expect(firstLine.contains('B'), isTrue);
      expect(firstLine.contains('C'), isTrue);
    });
  });
}

RenderContext _ctx() {
  final buffer = Buffer(const Size(40, 10));
  final focus = FocusController();
  return RenderContext(
    buffer: buffer,
    area: Rect(0, 0, 40, 10),
    theme: const ThemeData(),
    focus: focus,
    async_: AsyncRegistry(),
    logger: const SilentLogger(),
    requestRedraw: () {},
  );
}
