import 'package:commander_ui/tui.dart';

class State {
  String name = '';
  String email = '';
  bool agree = false;
  bool submitted = false;
  final nameState = TextFieldState();
  final emailState = TextFieldState();
}

Future<void> main() => runTerminal<State>(
      initialState: State(),
      onEvent: (s, event, handle) {
        if (event is KeyEvent && event.char == 'q' && event.ctrl) {
          handle.stop();
        }
      },
      render: (ctx, state) {
        final rects = Layout.vertical([
          const Constraint.length(3),
          const Constraint.length(3),
          const Constraint.length(3),
          const Constraint.length(1),
          const Constraint.length(3),
          const Constraint.fill(1),
          const Constraint.length(1),
        ]).split(ctx.area);

        ctx.draw(
          Container(
            border: BorderStyle.single,
            title: ' Sign up ',
            child: const Center(child: Text('Tab to move between fields')),
          ),
          rects[0],
        );

        ctx.draw(
          TextField(
            id: Key.symbol(#name),
            value: state.name,
            placeholder: 'Your name',
            state: state.nameState,
            onChanged: (v) => state.name = v,
          ),
          rects[1],
        );

        ctx.draw(
          TextField(
            id: Key.symbol(#email),
            value: state.email,
            placeholder: 'you@example.com',
            state: state.emailState,
            validate: (v) => v.isEmpty || v.contains('@'),
            onChanged: (v) => state.email = v,
          ),
          rects[2],
        );

        ctx.draw(
          Checkbox(
            id: Key.symbol(#agree),
            value: state.agree,
            label: 'I agree to the terms',
            onChanged: (v) => state.agree = v,
          ),
          rects[3],
        );

        ctx.draw(
          Button(
            id: Key.symbol(#submit),
            label: state.submitted ? 'Submitted ✓' : 'Submit',
            onPressed: () => state.submitted = true,
          ),
          rects[4],
        );

        ctx.draw(
          const Text('Tab to switch · Ctrl-Q to quit', align: TextAlign.center),
          rects[6],
        );
      },
    );
