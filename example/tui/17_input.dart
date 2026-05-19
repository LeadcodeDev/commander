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

class AppState {
  FormState form;
  AppState(this.form);
}

Future<void> main() async {
  final form = FormState();
  final state = AppState(form);

  await runTerminal<AppState>(
    initialState: state,
    mode: const RenderMode.flow(autoGrow: true),
    onEvent: (s, event, handle) {
      if (event is KeyEvent && event.char == 'q' && event.ctrl) {
        handle.stop();
      }
    },
    render: (ctx, state) {
      ctx.draw(
        Chain.flow(
          state: state.form.chain,
          onComplete: (values) {
            // All responses collected.
          },
          flow: (ctx) async {
            state.form.nameValue = await ctx.draw<String>(
              Input(
                state: state.form.name,
                message: 'Your name?',
                placeholder: 'John Doe',
                validate: (v) => v.trim().isEmpty ? 'Name is required' : null,
                onSubmit: ctx.complete,
              ),
            );

            state.form.emailValue = await ctx.draw<String>(
              Input(
                state: state.form.email,
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
            if (state.form.emailValue!.contains('admin')) {
              state.form.passwordValue = await ctx.draw<String>(
                Input(
                  state: state.form.password,
                  message: 'Admin password?',
                  obscure: true,
                  validate: (v) => v.length < 6 ? 'Min 6 characters' : null,
                  onSubmit: ctx.complete,
                ),
              );
            }

            state.form.portValue = int.parse(await ctx.draw<String>(
              Input(
                state: state.form.port,
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
      if (state.form.chain.completed) {
        ctx.draw(
          Paragraph(
            '✓ Submission complete — ${state.form.chain.length} answer(s) recorded.',
            style: Style(fg: ctx.theme.colors.success, bold: true),
          ),
          Rect(
            ctx.area.x,
            ctx.area.y + state.form.chain.length,
            ctx.area.width,
            1,
          ),
        );

        ctx.exit();
      }
    },
  );
}
