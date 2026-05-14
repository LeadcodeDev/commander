import 'package:commander_ui/tui.dart';

class State {
  String query = '';
  final inputState = TextFieldState();
  final items = const [
    'apple',
    'banana',
    'cherry',
    'date',
    'elderberry',
    'fig',
    'grape',
  ];
  final listState = ListState();
}

Future<void> main() => runTerminal<State>(
      initialState: State(),
      mode: const RenderMode.inline(height: 8),
      onEvent: (s, event, handle) {
        if (event is KeyEvent && event.key == 'Escape') handle.stop();
        if (event is KeyEvent && event.key == 'Enter' &&
            ctxCurrentFocus(s) == Key.symbol(#list)) {
          handle.stop();
        }
      },
      render: (ctx, state) {
        final filtered = state.items
            .where((i) => i.contains(state.query.toLowerCase()))
            .toList();

        final rows = Layout.vertical([
          const Constraint.length(3),
          const Constraint.fill(1),
        ]).split(ctx.area);

        ctx.draw(
          TextField(
            id: Key.symbol(#search),
            value: state.query,
            placeholder: 'Type to filter...',
            state: state.inputState,
            onChanged: (v) => state.query = v,
          ),
          rows[0],
        );

        ctx.draw(
          ListView<String>(
            id: Key.symbol(#list),
            items: filtered,
            state: state.listState,
            itemBuilder: (item, selected) =>
                Text(selected ? '> $item' : '  $item'),
          ),
          rows[1],
        );
      },
    );

Key? ctxCurrentFocus(State s) => null;
