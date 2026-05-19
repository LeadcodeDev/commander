import 'package:commander_ui/tui.dart';

class State {
  int counter = 0;
}

Future<String> fetchData() async {
  await Future.delayed(const Duration(seconds: 2));
  return 'Data fetched at ${DateTime.now()}';
}

Future<void> main() => runTerminal<State>(
      initialState: State(),
      onEvent: (s, event, handle) {
        if (event is KeyEvent) {
          if (event.char == 'q') handle.stop();
          if (event.char == 'r') {
            s.counter++;
            handle.requestRedraw();
          }
        }
      },
      render: (ctx, state) {
        ctx.draw(
          Container(
            border: BorderStyle.rounded,
            title: ' Async demo ',
            padding: const EdgeInsets.all(1),
            child: Column(
              children: [
                Async<String>(
                  key: Key('fetch-${state.counter}'),
                  future: fetchData,
                  onLoading: () => const Spinner(label: 'Loading...'),
                  onSuccess: (value) => Text('✓ $value',
                      style: const Style(fg: Color.green)),
                  onError: (e, _) => Text('✗ $e',
                      style: const Style(fg: Color.red)),
                ),
                const Spacer(),
                const Text('Press r to re-fetch · q to quit'),
              ],
            ),
          ),
          ctx.area,
        );
      },
    );
