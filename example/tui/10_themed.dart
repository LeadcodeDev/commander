import 'package:commander_ui/tui.dart';

class State {
  bool dark = true;
}

ThemeData buildTheme(State state) => state.dark
    ? const ThemeData(
        colors: ColorScheme(
          primary: Color.cyan,
          background: Color.black,
          foreground: Color.white,
        ),
      )
    : const ThemeData(
        colors: ColorScheme(
          primary: Color.blue,
          background: Color.white,
          foreground: Color.black,
        ),
      );

Future<void> main() => runTerminal<State>(
      initialState: State(),
      themeBuilder: buildTheme,
      onEvent: (s, event, handle) {
        if (event is KeyEvent) {
          if (event.key == 'q') handle.stop();
          if (event.key == 't') {
            s.dark = !s.dark;
            handle.requestRedraw();
          }
        }
      },
      render: (ctx, state) {
        ctx.draw(
          Container(
            border: BorderStyle.rounded,
            title: ' Theming · t to toggle ',
            padding: const EdgeInsets.all(1),
            fill: Style(bg: ctx.theme.colors.background),
            child: Center(
              child: Text(
                state.dark ? 'Dark theme' : 'Light theme',
                style: Style(
                  fg: ctx.theme.colors.primary,
                  bold: true,
                ),
              ),
            ),
          ),
          ctx.area,
        );
      },
    );
