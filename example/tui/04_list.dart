import 'package:commander_ui/tui.dart';

class State {
  final items = List.generate(50, (i) => 'Item #${i + 1}');
  final listState = ListState();
}

Future<void> main() => runTerminal<State>(
      initialState: State(),
      onEvent: (s, event, handle) {
        if (event is KeyEvent && event.char == 'q') handle.stop();
      },
      render: (ctx, state) {
        ctx.draw(
          Container(
            border: BorderStyle.rounded,
            title: ' Items (j/k or arrows · Enter to activate · q to quit) ',
            child: ListView<String>(
              id: Key.symbol(#list),
              items: state.items,
              state: state.listState,
              itemBuilder: (item, selected) => Text(
                selected ? '❯ $item' : '  $item',
              ),
            ),
          ),
          ctx.area,
        );
      },
    );
