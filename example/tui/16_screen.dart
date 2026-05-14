import 'package:commander_ui/tui.dart';

class State {
  int counter = 0;
  bool wantsExit = false;
}

Future<void> main() => runTerminal<State>(
      initialState: State(),
      onEvent: (s, event, handle) {
        if (event is KeyEvent) {
          if (event.key == '+') {
            s.counter++;
            handle.requestRedraw();
          } else if (event.key == '-') {
            s.counter--;
            handle.requestRedraw();
          } else if (event.key == 'q') {
            s.wantsExit = true;
            handle.requestRedraw();
          }
        }
      },
      shouldExit: (state) => state.wantsExit,
      render: (ctx, state) {
        ctx.draw(
          Screen(
            title: 'Commander — counter ${state.counter}',
            onExit: () => state.wantsExit = true,
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
                          if (event.key == 'Enter' || event.key == ' ') {
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
