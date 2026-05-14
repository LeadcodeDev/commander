import 'package:commander_ui/tui.dart';

class State {
  int counter = 0;
}

Future<void> main() => runTerminal<State>(
      initialState: State(),
      onEvent: (s, event, handle) {
        if (event is KeyEvent) {
          if (event.char == '+') {
            s.counter++;
            handle.requestRedraw();
          } else if (event.char == '-') {
            s.counter--;
            handle.requestRedraw();
          } else if (event.char == 'q') {
            handle.stop();
          }
        }
      },
      render: (ctx, state) {
        ctx.draw(
          Screen(
            title: 'Commander — counter ${state.counter}',
            onExit: ctx.exit,
            builder: (ctx, exit) {
              return Center(
                child: Container(
                  border: BorderStyle.rounded,
                  title: ' Counter Demo ',
                  padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
                  child: Column(
                    children: [
                      Text(
                        'Value: ${state.counter}',
                        align: TextAlign.center,
                        style: Style(fg: ctx.theme.colors.primary, bold: true),
                      ),
                      const Text(
                        '+ to inc · - to dec',
                        align: TextAlign.center,
                        style: Style(dim: true),
                      ),
                      Focusable(
                        id: Key.symbol(#quit),
                        builder: (focused) => Text(
                          focused ? '> [ Quit ] <' : '  [ Quit ]  ',
                          align: TextAlign.center,
                          style: Style(
                            fg: focused
                                ? ctx.theme.colors.primary
                                : ctx.theme.colors.muted,
                            bold: focused,
                          ),
                        ),
                        onKeyHandler: (event) {
                          if (event.key == NamedKey.enter || event.char == ' ') {
                            exit();
                            return true;
                          }
                          return false;
                        },
                      ),
                    ],
                  ),
                ),
                width: 36,
                height: 9,
              );
            },
          ),
          ctx.area,
        );
      },
    );
