import 'package:commander_ui/tui.dart';

class FormState {
  final name = InputState();
  final email = InputState();
  final password = InputState();
  final port = InputState(initialValue: '8080');
  bool wantsExit = false;
}

Future<void> main() => runTerminal<FormState>(
      initialState: FormState(),
      shouldExit: (s) => s.wantsExit,
      onEvent: (s, event, handle) {
        if (event is KeyEvent && event.key == 'q' && event.ctrl) {
          s.wantsExit = true;
        }
      },
      render: (ctx, state) {
        final steps = <_Step>[
          _Step(
            state: state.name,
            input: () => Input(
              id: Key.symbol(#name),
              state: state.name,
              message: 'Your name?',
              placeholder: 'John Doe',
              validate: (v) => v.trim().isEmpty ? 'Name is required' : null,
            ),
          ),
          _Step(
            state: state.email,
            input: () => Input(
              id: Key.symbol(#email),
              state: state.email,
              message: 'Email?',
              placeholder: 'you@example.com',
              validate: (v) {
                if (v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Must contain @';
                return null;
              },
            ),
          ),
          _Step(
            state: state.password,
            input: () => Input(
              id: Key.symbol(#password),
              state: state.password,
              message: 'Password?',
              obscure: true,
              validate: (v) => v.length < 6 ? 'Min 6 characters' : null,
            ),
          ),
          _Step(
            state: state.port,
            input: () => Input(
              id: Key.symbol(#port),
              state: state.port,
              message: 'Port?',
              defaultValue: '8080',
              validate: (v) {
                final n = int.tryParse(v);
                if (n == null) return 'Must be a number';
                if (n < 1 || n > 65535) return 'Port range: 1-65535';
                return null;
              },
            ),
          ),
        ];

        final activeIndex = _firstUnsubmitted(steps);

        var y = ctx.area.y;
        for (var i = 0; i <= activeIndex && i < steps.length; i++) {
          final s = steps[i];
          final needsErrorLine = !s.state.submitted && s.state.error != null;
          final h = needsErrorLine ? 2 : 1;
          final rect = Rect(ctx.area.x, y, ctx.area.width, h);
          ctx.draw(s.input(), rect);
          y += h;
        }

        if (activeIndex >= steps.length) {
          y += 1;
          final rect = Rect(ctx.area.x, y, ctx.area.width, 2);
          ctx.draw(
            Paragraph(
              '✓ All done. Press Ctrl-Q to quit.',
              style: Style(fg: ctx.theme.colors.success, bold: true),
            ),
            rect,
          );
        }

        final footer = Rect(ctx.area.x, ctx.area.bottom - 1, ctx.area.width, 1);
        ctx.draw(
          const Text('Enter to submit · Ctrl-Q to quit',
              align: TextAlign.center, style: Style(dim: true)),
          footer,
        );
      },
    );

int _firstUnsubmitted(List<_Step> steps) {
  for (var i = 0; i < steps.length; i++) {
    if (!steps[i].state.submitted) return i;
  }
  return steps.length;
}

class _Step {
  final InputState state;
  final Input Function() input;
  _Step({required this.state, required this.input});
}
