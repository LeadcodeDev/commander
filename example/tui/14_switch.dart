import 'package:commander_ui/tui.dart' as tui;
import 'package:commander_ui/tui.dart';

class State {
  bool notifications = true;
  bool darkMode = false;
  bool telemetry = false;
}

Future<void> main() => runTerminal<State>(
      initialState: State(),
      onEvent: (s, event, handle) {
        if (event is KeyEvent && event.key == 'q' && event.ctrl) {
          handle.stop();
        }
      },
      render: (ctx, state) {
        final rows = Layout.vertical([
          const Constraint.length(2),
          const Constraint.length(1),
          const Constraint.length(1),
          const Constraint.length(1),
          const Constraint.fill(1),
          const Constraint.length(1),
        ]).split(ctx.area);

        ctx.draw(const Text('Settings'), rows[0]);

        ctx.draw(
          tui.Switch(
            id: Key.symbol(#notifications),
            checked: state.notifications,
            label: 'Notifications',
            onChanged: (v) => state.notifications = v,
          ),
          rows[1],
        );

        ctx.draw(
          tui.Switch(
            id: Key.symbol(#darkMode),
            checked: state.darkMode,
            label: 'Dark mode',
            onChanged: (v) => state.darkMode = v,
          ),
          rows[2],
        );

        ctx.draw(
          tui.Switch(
            id: Key.symbol(#telemetry),
            checked: state.telemetry,
            label: 'Send telemetry',
            onChanged: (v) => state.telemetry = v,
          ),
          rows[3],
        );

        ctx.draw(
          Paragraph(
            'Tab to focus · Space/Enter to toggle · Ctrl-Q to quit.\n\n'
            'notifications=${state.notifications} · darkMode=${state.darkMode} · telemetry=${state.telemetry}',
            style: ctx.theme.text.caption,
          ),
          rows[4],
        );

        ctx.draw(
          const Text('Ctrl-Q to quit', align: TextAlign.center),
          rows[5],
        );
      },
    );
