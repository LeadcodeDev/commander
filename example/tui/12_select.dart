import 'package:commander_ui/tui.dart';

class Country {
  final String code;
  final String name;
  final String continent;
  const Country(this.code, this.name, this.continent);
}

const _countries = [
  Country('FR', 'France', 'Europe'),
  Country('DE', 'Germany', 'Europe'),
  Country('IT', 'Italy', 'Europe'),
  Country('ES', 'Spain', 'Europe'),
  Country('PT', 'Portugal', 'Europe'),
  Country('BE', 'Belgium', 'Europe'),
  Country('US', 'United States', 'America'),
  Country('CA', 'Canada', 'America'),
  Country('JP', 'Japan', 'Asia'),
  Country('KR', 'South Korea', 'Asia'),
  Country('CN', 'China', 'Asia'),
  Country('AU', 'Australia', 'Oceania'),
];

class State {
  int tab = 0;
  final singleState = SelectState<Country>();
  final multiState = SelectState<Country>();
  Country? singleChoice;
  List<Country> multiChoice = const [];
  bool submittedSingle = false;
  bool submittedMulti = false;
}

Widget _row(Country c, SelectItemState s) {
  final marker = s.isSelected ? '●' : '○';
  final emphasis = s.isActive
      ? const Style(bold: true)
      : Style.none;
  return Row(children: [
    Fixed(size: 3, child: Text('  $marker', style: emphasis)),
    Fixed(size: 5, child: Text(c.code, style: const Style(dim: true))),
    Expanded(child: Text(c.name, style: emphasis)),
    Fixed(size: 12, child: Text(c.continent, style: const Style(dim: true))),
  ]);
}

Future<void> main() => runTerminal<State>(
      initialState: State(),
      onEvent: (s, event, handle) {
        if (event is KeyEvent && event.key == 'q' && event.ctrl) {
          handle.stop();
        }
        if (event is KeyEvent &&
            event.key == 'Tab' &&
            handle.focus.current == Key.symbol(#tabs)) {
          return;
        }
      },
      render: (ctx, state) {
        final rows = Layout.vertical([
          const Constraint.length(2),
          const Constraint.length(1),
          const Constraint.fill(1),
          const Constraint.length(1),
        ]).split(ctx.area);

        ctx.draw(
          Tabs(
            id: Key.symbol(#tabs),
            tabs: const ['Single', 'Multi (2-3)'],
            selected: state.tab,
            onTabSelected: (i) => state.tab = i,
          ),
          rows[0],
        );

        ctx.draw(const Divider(), rows[1]);

        final body = rows[2].insetAll(1);
        final block = Layout.vertical([
          const Constraint.length(1),
          const Constraint.length(10),
          const Constraint.fill(1),
        ]).split(body);

        switch (state.tab) {
          case 0:
            ctx.draw(
              const Text('Pick a single country (filterable)'),
              block[0],
            );
            ctx.draw(
              Select<Country>(
                id: Key.symbol(#singleSelect),
                items: _countries,
                state: state.singleState,
                builder: _row,
                mode: SelectionMode.single,
                visibleCount: 6,
                filterable: true,
                defaultValue: const Country('FR', 'France', 'Europe'),
                filter: (c, q) =>
                    c.name.toLowerCase().contains(q.toLowerCase()) ||
                    c.code.toLowerCase().contains(q.toLowerCase()),
                onChanged: (c) => state.singleChoice = c,
                onSubmit: (list) {
                  state.singleChoice = list.firstOrNull;
                  state.submittedSingle = true;
                },
              ),
              block[1],
            );
            ctx.draw(
              Paragraph(
                'Space to select · Enter to confirm · ↑/↓ to navigate · type to filter.\n\n'
                'Choice: ${state.singleChoice?.name ?? "(none)"}\n'
                'Submitted: ${state.submittedSingle}',
                style: ctx.theme.text.caption,
              ),
              block[2],
            );

          case 1:
            ctx.draw(
              const Text('Pick 2 or 3 countries (multi · max 3)'),
              block[0],
            );
            ctx.draw(
              Select<Country>(
                id: Key.symbol(#multiSelect),
                items: _countries,
                state: state.multiState,
                builder: _row,
                mode: SelectionMode.multi,
                visibleCount: 6,
                minSelections: 2,
                maxSelections: 3,
                filterable: true,
                filter: (c, q) =>
                    c.name.toLowerCase().contains(q.toLowerCase()),
                validate: (selection) {
                  if (selection.any((c) => c.continent == 'Oceania')) {
                    return null;
                  }
                  return selection.length >= 2
                      ? null
                      : 'Pick at least 2 countries.';
                },
                onSubmit: (list) {
                  state.multiChoice = list;
                  state.submittedMulti = true;
                },
              ),
              block[1],
            );
            ctx.draw(
              Paragraph(
                'Space to toggle · Enter to confirm · ↑/↓ navigate · type to filter.\n\n'
                'Selected: ${state.multiChoice.map((c) => c.code).join(', ')}\n'
                'Submitted: ${state.submittedMulti}',
                style: ctx.theme.text.caption,
              ),
              block[2],
            );
        }

        ctx.draw(
          const Text(
            '←/→ tabs · Tab cycles focus · Ctrl-Q quit',
            align: TextAlign.center,
          ),
          rows[3],
        );
      },
    );
