import 'package:commander_ui/tui.dart';

class FormState {
  final chain = ChainFlowState();
  final name = InputState();
  final email = InputState();
  final password = InputState();
  final port = InputState(initialValue: '8080');

  String? nameValue;
  String? emailValue;
  String? passwordValue;
  int? portValue;
}

Future<void> main() => runTerminal<FormState>(
      initialState: FormState(),
      mode: const RenderMode.flow(autoGrow: true),
      onEvent: (s, event, handle) {
        if (event is KeyEvent && event.char == 'q' && event.ctrl) {
          handle.stop();
        }
      },
      render: (ctx, state) {
        ctx.draw(
          Chain.flow(
            state: state.chain,
            onComplete: (values) {
              // Toutes les réponses collectées.
            },
            flow: (ctx) async {
              state.nameValue = await ctx.draw<String>(
                Input(
                  id: Key.symbol(#name),
                  state: state.name,
                  message: 'Your name?',
                  placeholder: 'John Doe',
                  validate: (v) => v.trim().isEmpty ? 'Name is required' : null,
                  onSubmit: ctx.complete,
                ),
              );

              state.emailValue = await ctx.draw<String>(
                Input(
                  id: Key.symbol(#email),
                  state: state.email,
                  message: 'Email?',
                  placeholder: 'you@example.com',
                  validate: (v) {
                    if (v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Must contain @';
                    return null;
                  },
                  onSubmit: ctx.complete,
                ),
              );

              // Conditional step: only ask for password if email looks admin-y.
              if (state.emailValue!.contains('admin')) {
                state.passwordValue = await ctx.draw<String>(
                  Input(
                    id: Key.symbol(#password),
                    state: state.password,
                    message: 'Admin password?',
                    obscure: true,
                    validate: (v) => v.length < 6 ? 'Min 6 characters' : null,
                    onSubmit: ctx.complete,
                  ),
                );
              }

              state.portValue = int.parse(await ctx.draw<String>(
                Input(
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
                  onSubmit: ctx.complete,
                ),
              ));
            },
          ),
          ctx.area,
        );

        // Paragraph de confirmation dessiné en dehors du Chain, une fois
        // tous les inputs submitted.
        if (state.chain.completed) {
          ctx.draw(
            Paragraph(
              '✓ Submission complete — ${state.chain.length} answer(s) recorded.',
              style: Style(fg: ctx.theme.colors.success, bold: true),
            ),
            Rect(
              ctx.area.x,
              ctx.area.y + state.chain.length,
              ctx.area.width,
              1,
            ),
          );

          ctx.exit();
        }
      },
    );
