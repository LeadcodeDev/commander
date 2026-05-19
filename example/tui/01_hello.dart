import 'package:commander_ui/tui.dart';

class HelloState {
  bool running = true;
}

Future<void> main() => runTerminal<HelloState>(
      initialState: HelloState(),
      onEvent: (state, event, handle) {
        if (event is KeyEvent && event.char == 'q') {
          handle.stop();
        }
      },
      render: (ctx, state) {
        ctx.draw(
          Center(
            child: Container(
              border: BorderStyle.rounded,
              title: ' Commander TUI ',
              padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
              child: const Text(
                'Hello, World!',
                align: TextAlign.center,
              ),
            ),
            width: 40,
            height: 5,
          ),
          ctx.area,
        );

        ctx.draw(
          const Text(
            'Press q or Ctrl-C to quit',
            align: TextAlign.center,
          ),
          Rect(0, ctx.area.height - 1, ctx.area.width, 1),
        );
      },
    );
