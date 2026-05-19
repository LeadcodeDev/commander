import 'dart:math';

import 'package:commander_ui/tui.dart';

class State {
  int frame = 0;
  double cpu = 30;
  double mem = 45;
  final logs = <String>[];
}

Future<void> main() => runTerminal<State>(
      initialState: State(),
      frameRate: const Duration(milliseconds: 250),
      onEvent: (s, event, handle) {
        if (event is KeyEvent && event.char == 'q') handle.stop();
        if (event is TickEvent) {
          s.frame++;
          final rnd = Random();
          s.cpu = (s.cpu + (rnd.nextDouble() * 20 - 10)).clamp(0, 100);
          s.mem = (s.mem + (rnd.nextDouble() * 10 - 5)).clamp(0, 100);
          if (rnd.nextDouble() < 0.4) {
            s.logs.add('[${DateTime.now().toIso8601String().substring(11, 19)}] tick ${s.frame}');
            if (s.logs.length > 50) s.logs.removeAt(0);
          }
        }
      },
      render: (ctx, state) {
        final rows = Layout.vertical([
          const Constraint.length(3),
          const Constraint.fill(1),
          const Constraint.length(1),
        ]).split(ctx.area);

        ctx.draw(
          Container(
            border: BorderStyle.rounded,
            title: ' Live Dashboard ',
            child: const Center(child: Text('Real-time metrics')),
          ),
          rows[0],
        );

        final body = Layout.horizontal([
          const Constraint.percentage(40),
          const Constraint.fill(1),
        ]).split(rows[1]);

        final leftRows = Layout.vertical([
          const Constraint.length(4),
          const Constraint.length(4),
          const Constraint.fill(1),
        ]).split(body[0]);

        ctx.draw(
          Container(
            border: BorderStyle.single,
            title: ' CPU ',
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Gauge(value: state.cpu, label: 'load'),
          ),
          leftRows[0],
        );

        ctx.draw(
          Container(
            border: BorderStyle.single,
            title: ' Memory ',
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Gauge(value: state.mem, label: 'used'),
          ),
          leftRows[1],
        );

        ctx.draw(
          Container(
            border: BorderStyle.single,
            title: ' Stats ',
            padding: const EdgeInsets.all(1),
            child: Paragraph(
              'Frame: ${state.frame}\nLogs: ${state.logs.length}',
            ),
          ),
          leftRows[2],
        );

        ctx.draw(
          Container(
            border: BorderStyle.single,
            title: ' Logs ',
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Paragraph(state.logs.reversed.take(20).join('\n')),
          ),
          body[1],
        );

        ctx.draw(const Text('q to quit', align: TextAlign.center), rows[2]);
      },
    );
