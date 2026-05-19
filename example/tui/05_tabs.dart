import 'package:commander_ui/tui.dart';

class State {
  int tab = 0;
}

Future<void> main() => runTerminal<State>(
      initialState: State(),
      onEvent: (s, event, handle) {
        if (event is KeyEvent && event.char == 'q') handle.stop();
      },
      render: (ctx, state) {
        final rows = Layout.vertical([
          const Constraint.length(2),
          const Constraint.fill(1),
          const Constraint.length(1),
        ]).split(ctx.area);

        ctx.draw(
          Tabs(
            id: Key.symbol(#tabs),
            tabs: const ['Overview', 'Logs', 'Metrics', 'Settings'],
            selected: state.tab,
            onTabSelected: (i) => state.tab = i,
          ),
          rows[0],
        );

        final body = switch (state.tab) {
          0 =>
            'Welcome to the Overview tab.\n\nUse arrow keys or h/l to switch tabs.',
          1 =>
            '[INFO ] Application started\n[INFO ] Listening on :8080\n[WARN ] High memory usage detected',
          2 => 'CPU: 42%\nMemory: 1.2 GB / 4 GB\nRequests/s: 128',
          _ => 'Settings panel goes here.',
        };

        ctx.draw(
          Container(
            border: BorderStyle.single,
            padding: const EdgeInsets.all(1),
            child: Paragraph(body),
          ),
          rows[1],
        );

        ctx.draw(
          const Text('h/l or arrows · q to quit', align: TextAlign.center),
          rows[2],
        );
      },
    );
