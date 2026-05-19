import 'package:commander_ui/tui.dart';

sealed class AppRoute {
  const AppRoute();
}

class HomeRoute extends AppRoute {
  const HomeRoute();
}

class DetailRoute extends AppRoute {
  final int itemId;
  const DetailRoute(this.itemId);
}

class SettingsRoute extends AppRoute {
  const SettingsRoute();
}

class State {
  final navigator = TuiNavigator<AppRoute>(initial: const HomeRoute());
  int selectedItem = 0;
}

Future<void> main() => runTerminal<State>(
      initialState: State(),
      onEvent: (s, event, handle) {
        if (event is KeyEvent) {
          if (event.char == 'q' && event.ctrl) handle.stop();

          final current = s.navigator.current;
          if (current is HomeRoute) {
            if (event.key == NamedKey.enter) {
              s.navigator.push(DetailRoute(s.selectedItem));
              handle.requestRedraw();
            } else if (event.char == 's') {
              s.navigator.push(const SettingsRoute());
              handle.requestRedraw();
            }
          } else {
            if (event.key == NamedKey.escape || event.char == 'b') {
              s.navigator.pop();
              handle.requestRedraw();
            }
          }
        }
      },
      render: (ctx, state) {
        final rect = ctx.area;
        final current = state.navigator.current;

        switch (current) {
          case HomeRoute():
            ctx.draw(
              Container(
                border: BorderStyle.rounded,
                title: ' Home ',
                padding: const EdgeInsets.all(1),
                child: Paragraph(
                  'Welcome.\n\nEnter to open detail · s for settings · Ctrl-Q to quit',
                ),
              ),
              rect,
            );
          case DetailRoute(:final itemId):
            ctx.draw(
              Container(
                border: BorderStyle.rounded,
                title: ' Detail #$itemId ',
                padding: const EdgeInsets.all(1),
                child: const Paragraph(
                  'You are now on the detail screen.\n\nb or Escape to go back.',
                ),
              ),
              rect,
            );
          case SettingsRoute():
            ctx.draw(
              Container(
                border: BorderStyle.rounded,
                title: ' Settings ',
                padding: const EdgeInsets.all(1),
                child: const Paragraph('Settings · b or Escape to go back.'),
              ),
              rect,
            );
        }
      },
    );
