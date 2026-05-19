import 'package:commander_ui/tui.dart';

class State {
  int tab = 0;

  String name = '';
  final nameInput = TextFieldState();
  bool accept = false;

  String? country;
  final dropdownState = DropdownState();

  Key? wantsFocus = Key.symbol(#tabs);
}

const _countries = [
  'France',
  'Germany',
  'Italy',
  'Spain',
  'Portugal',
  'Belgium'
];

final _tabsKey = Key.symbol(#tabs);

Key _firstFocusOfTab(int tab) => switch (tab) {
      0 => Key.symbol(#name),
      _ => Key.symbol(#country),
    };

Future<void> main() => runTerminal<State>(
      initialState: State(),
      onEvent: (s, event, handle) {
        if (event is! KeyEvent) return;
        if (event.char == 'q' && event.ctrl) {
          handle.stop();
          return;
        }

        final currentFocus = handle.focus.current;
        if (event.key == NamedKey.escape && currentFocus != _tabsKey) {
          s.wantsFocus = _tabsKey;
          handle.requestRedraw();
          return;
        }

        if ((event.key == NamedKey.arrowDown || event.key == NamedKey.enter) &&
            currentFocus == _tabsKey) {
          s.wantsFocus = _firstFocusOfTab(s.tab);

          if (s.tab == 1) {
            s.dropdownState.open = true;
            s.dropdownState.highlightedIndex = s.country == null
                ? 0
                : _countries
                    .indexOf(s.country!)
                    .clamp(0, _countries.length - 1);
          }

          handle.requestRedraw();
          return;
        }
        if (event.key == NamedKey.arrowDown && currentFocus != _tabsKey) {
          handle.focus.next();
          handle.requestRedraw();
          return;
        }
        if (event.key == NamedKey.arrowUp && currentFocus != _tabsKey) {
          handle.focus.previous();
          handle.requestRedraw();
          return;
        }
      },
      render: (ctx, state) {
        if (state.wantsFocus != null) {
          ctx.focus.focus(state.wantsFocus!);
          state.wantsFocus = null;
        }

        final rows = Layout.vertical([
          const Constraint.length(2),
          const Constraint.length(1),
          const Constraint.fill(1),
          const Constraint.length(1),
        ]).split(ctx.area);

        ctx.draw(
          Tabs(
            id: _tabsKey,
            tabs: const ['Profile', 'Preferences'],
            selected: state.tab,
            onTabSelected: (i) => state.tab = i,
          ),
          rows[0],
        );

        ctx.draw(const Divider(), rows[1]);

        final body = rows[2];
        switch (state.tab) {
          case 0:
            final fields = Layout.vertical([
              const Constraint.length(3),
              const Constraint.length(1),
              const Constraint.fill(1),
            ]).split(body.insetAll(1));

            ctx.draw(
              TextField(
                id: Key.symbol(#name),
                value: state.name,
                placeholder: 'Your name',
                state: state.nameInput,
                onChanged: (v) => state.name = v,
              ),
              fields[0],
            );

            ctx.draw(
              Checkbox(
                id: Key.symbol(#accept),
                value: state.accept,
                label: 'I accept the terms',
                onChanged: (v) => state.accept = v,
              ),
              fields[1],
            );

            ctx.draw(
              Paragraph(
                'Tabs ←/→ · ↓ to enter fields · Esc back to tabs · Tab cycles.\n\n'
                'Current: name="${state.name}", accept=${state.accept}',
                style: ctx.theme.text.caption,
              ),
              fields[2],
            );

          case 1:
            final fields = Layout.vertical([
              const Constraint.length(8),
              const Constraint.fill(1),
            ]).split(body.insetAll(1));

            ctx.draw(
              Dropdown<String>(
                id: Key.symbol(#country),
                options: _countries,
                selected: state.country,
                state: state.dropdownState,
                onChanged: (v) => state.country = v,
                placeholder: 'Choose a country',
              ),
              fields[0],
            );

            ctx.draw(
              Paragraph(
                'Enter/Space to open · ↑/↓ to navigate · Enter to confirm · Esc to close.\n\n'
                'Selected: ${state.country ?? "(none)"}',
                style: ctx.theme.text.caption,
              ),
              fields[1],
            );
        }

        ctx.draw(
          const Text(
            '←/→ tabs · ↓ enter · Esc back · Tab cycles · Ctrl-Q quit',
            align: TextAlign.center,
          ),
          rows[3],
        );
      },
    );
