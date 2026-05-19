import 'package:commander_ui/tui.dart';

class Feature {
  final String name;
  final String description;
  const Feature(this.name, this.description);
}

const _features = [
  Feature('Auth', 'Authentication & session management'),
  Feature('Billing', 'Subscriptions and invoices'),
  Feature('Notifications', 'Email and push delivery'),
  Feature('Analytics', 'Event tracking and reports'),
  Feature('Search', 'Full-text indexing'),
];

class State {
  final groupState = CheckboxGroupState<Feature>();
}

Widget _row(Feature f, CheckboxItemState s) {
  final mark = s.isChecked ? '[x]' : '[ ]';
  final base = s.isActive ? const Style(bold: true) : Style.none;

  return Row(children: [
    Fixed(size: 4, child: Text(' $mark', style: base)),
    Fixed(size: 16, child: Text(f.name, style: base)),
    Expanded(child: Text(f.description, style: const Style(dim: true))),
  ]);
}

Future<void> main() => runTerminal<State>(
      initialState: State(),
      onEvent: (s, event, handle) {
        if (event is KeyEvent && event.char == 'q' && event.ctrl) {
          handle.stop();
        }
      },
      render: (ctx, state) {
        final rows = Layout.vertical([
          const Constraint.length(2),
          const Constraint.length(7),
          const Constraint.fill(1),
          const Constraint.length(1),
        ]).split(ctx.area);

        ctx.draw(
          const Text('Select features to enable'),
          rows[0],
        );

        ctx.draw(
          CheckboxGroup<Feature>(
            id: Key.symbol(#features),
            items: _features,
            state: state.groupState,
            defaultChecked: const [
              Feature('Auth', 'Authentication & session management'),
            ],
            builder: _row,
          ),
          rows[1],
        );

        final selected = state.groupState.checked.map((f) => f.name).toList()
          ..sort();

        ctx.draw(
          Paragraph(
            '↑/↓ navigate · Space toggle · Ctrl-Q quit.\n\n'
            'Currently enabled: ${selected.isEmpty ? "(none)" : selected.join(', ')}',
            style: ctx.theme.text.caption,
          ),
          rows[2],
        );

        ctx.draw(
          const Text('Ctrl-Q to quit', align: TextAlign.center),
          rows[3],
        );
      },
    );
