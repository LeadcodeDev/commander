import 'package:commander_ui/tui.dart';

class State {
  bool running = true;
}

Future<void> main() => runTerminal<State>(
      initialState: State(),
      onEvent: (state, event, handle) {
        if (event is KeyEvent && event.key == 'q') handle.stop();
      },
      render: (ctx, state) {
        final rects = Layout.vertical([
          const Constraint.length(3),
          const Constraint.fill(1),
          const Constraint.length(1),
        ]).split(ctx.area);

        ctx.draw(
          Container(
            border: BorderStyle.single,
            title: ' Header ',
            child: const Center(child: Text('Three-zone layout')),
          ),
          rects[0],
        );

        final body = Layout.horizontal([
          const Constraint.percentage(30),
          const Constraint.fill(1),
        ]).split(rects[1]);

        ctx.draw(
          Container(
            border: BorderStyle.rounded,
            title: ' Left ',
            child: const Paragraph(
              'A column on the left side.\n\nWord-wrap works fine here.',
            ),
          ),
          body[0],
        );
        ctx.draw(
          Container(
            border: BorderStyle.rounded,
            title: ' Right ',
            child: const Paragraph(
              'The main content area expands to fill the available horizontal space.',
            ),
          ),
          body[1],
        );

        ctx.draw(
          const Text('q to quit · resize the terminal to test layout',
              align: TextAlign.center),
          rects[2],
        );
      },
    );
