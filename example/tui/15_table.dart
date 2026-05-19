import 'package:commander_ui/tui.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String status;
  final int score;
  const User(this.id, this.name, this.email, this.status, this.score);
}

const _users = [
  User(1, 'Alice Martin', 'alice@example.com', 'active', 87),
  User(2, 'Bob Durand', 'bob@example.com', 'idle', 42),
  User(3, 'Charlie Petit', 'charlie@example.com', 'active', 91),
  User(4, 'David Roux', 'david@example.com', 'banned', 12),
  User(5, 'Eve Moreau', 'eve@example.com', 'active', 76),
  User(6, 'Frank Garcia', 'frank@example.com', 'idle', 58),
  User(7, 'Grace Henri', 'grace@example.com', 'active', 99),
  User(8, 'Helen Ibarra', 'helen@example.com', 'banned', 5),
];

class State {
  final tableState = TableState<User>();
  bool sortByScore = false;
  bool onlyActive = false;
  int lastActivated = -1;
}

Widget _cellName(User u, TableCellState s) => Text(
      u.name,
      style: s.isRowSelected ? const Style(bold: true) : Style.none,
    );

Widget _cellEmail(User u, TableCellState s) => Text(
      u.email,
      style: const Style(dim: true),
    );

Widget _cellStatus(User u, TableCellState s) {
  final color = switch (u.status) {
    'active' => Color.green,
    'idle' => Color.yellow,
    _ => Color.red,
  };

  return Text(u.status, style: Style(fg: color, bold: s.isCellSelected));
}

Widget _cellScore(User u, TableCellState s) => Text(
      u.score.toString(),
      align: TextAlign.right,
      style: Style(
        fg: u.score >= 80
            ? Color.green
            : u.score >= 50
                ? Color.yellow
                : Color.red,
      ),
    );

Future<void> main() => runTerminal<State>(
      initialState: State(),
      onEvent: (s, event, handle) {
        if (event is! KeyEvent) return;
        if (event.char == 'q' && event.ctrl) {
          handle.stop();
          return;
        }
        if (event.char == 's') {
          s.sortByScore = !s.sortByScore;
          handle.requestRedraw();
        }
        if (event.char == 'f') {
          s.onlyActive = !s.onlyActive;
          handle.requestRedraw();
        }
      },
      render: (ctx, state) {
        final rows = Layout.vertical([
          const Constraint.length(2),
          const Constraint.fill(1),
          const Constraint.length(2),
          const Constraint.length(1),
        ]).split(ctx.area);

        ctx.draw(
          Paragraph(
            'Users · sort=${state.sortByScore ? "score" : "id"} · filter=${state.onlyActive ? "active" : "all"}',
          ),
          rows[0],
        );

        ctx.draw(
          Table<User>(
            id: Key.symbol(#users),
            items: _users,
            state: state.tableState,
            columns: [
              TableColumn(
                title: 'ID',
                width: const TableConstraint.length(4),
                headerAlign: TextAlign.right,
                cellBuilder: (u, s) =>
                    Text(u.id.toString(), align: TextAlign.right),
              ),
              TableColumn(
                title: 'Name',
                width: const TableConstraint.fill(2),
                cellBuilder: _cellName,
              ),
              TableColumn(
                title: 'Email',
                width: const TableConstraint.fill(3),
                cellBuilder: _cellEmail,
              ),
              TableColumn(
                title: 'Status',
                width: const TableConstraint.length(10),
                cellBuilder: _cellStatus,
              ),
              TableColumn(
                title: 'Score',
                width: const TableConstraint.length(7),
                headerAlign: TextAlign.right,
                cellBuilder: _cellScore,
              ),
            ],
            columnSeparator: ' │ ',
            selectCells: true,
            selectRows: true,
            selectColumns: true,
            sortBy: state.sortByScore ? (a, b) => b.score - a.score : null,
            filter: state.onlyActive ? (u) => u.status == 'active' : null,
            onRowActivated: (idx, u) => state.lastActivated = u.id,
          ),
          rows[1],
        );

        final rowsSel = state.tableState.selectedRows.toList()..sort();
        final colsSel = state.tableState.selectedColumns.toList()..sort();
        final cellsSel = state.tableState.selectedCells
            .map((c) => '(${c.row},${c.col})')
            .join(' ');

        ctx.draw(
          Paragraph(
            'Rows: $rowsSel · Cols: $colsSel · Cells: $cellsSel\n'
            'Last activated: ${state.lastActivated == -1 ? "(none)" : "id=${state.lastActivated}"}',
            style: ctx.theme.text.caption,
          ),
          rows[2],
        );

        ctx.draw(
          const Text(
            '↑↓←→ navigate · Enter activate · Space cell · Shift-Space row · Alt-Space col · s sort · f filter · Ctrl-Q quit',
            align: TextAlign.center,
            style: Style(dim: true),
          ),
          rows[3],
        );
      },
    );
