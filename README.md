# Commander

Commander is a Dart library for building terminal user interfaces — both inline interactive prompts and full-screen declarative TUI applications.

```yaml
dependencies:
  commander_ui: ^3.0.0
```

> **Heads up — 3.0.0 is a breaking release.** The legacy `Commander` class and `package:commander_ui/inline.dart` are gone. Replace `Commander()` with `InlineCommander()` and import `package:commander_ui/prompt.dart`. See [CHANGELOG.md](CHANGELOG.md) for the migration cheat sheet.

The package exposes two complementary APIs, each behind its own entry-point:

- **`package:commander_ui/prompt.dart`** — `InlineCommander`, one-shot interactive CLI prompts (`ask`, `select`, `multiSelect`, `confirm`, `number`, `password`, `task`) plus status helpers (`success`, `info`, `warn`, `error`). Built on top of the TUI runtime. Use it for scripts and short interactive flows.

- **`package:commander_ui/tui.dart`** — declarative TUI framework inspired by Ratatui (Rust). Use it to build full applications: dashboards, multi-screen wizards, file explorers, REPLs.

The two worlds share the same runtime but expose different ergonomics. Pick the one that fits the task.

---

## TUI quickstart

```dart
import 'package:commander_ui/tui.dart';

class HelloState {}

Future<void> main() => runTerminal<HelloState>(
      initialState: HelloState(),
      onEvent: (state, event, handle) {
        if (event is KeyEvent && event.key == 'q') handle.stop();
      },
      render: (ctx, state) {
        ctx.draw(
          Center(
            child: Container(
              border: BorderStyle.rounded,
              title: ' Commander TUI ',
              padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
              child: const Text('Hello, World!', align: TextAlign.center),
            ),
            width: 40,
            height: 5,
          ),
          ctx.area,
        );
      },
    );
```

Run with `dart run example/tui/01_hello.dart`.

### Core concepts

- **Immediate-mode rendering.** Each frame, your `render(ctx, state)` describes the full UI. The framework diffs cell buffers and emits the minimal escape sequence.
- **No widget tree state.** Widgets are values. State lives in your own `AppState`. Lifecycle methods (`initState`, `dispose`) don't exist by design.
- **Focus management built in.** Any widget with an `id: Key` becomes focusable. Tab cycles in render order; modals push focus scopes via `ctx.scope`. No code to write.
- **Async without state plumbing.** `Async<T>`, `AsyncResult<T, E>`, `AsyncStream<T>` track futures/streams by `Key`, restart on key change, and render `onLoading`/`onSuccess`/`onError` declaratively.
- **Cross-platform.** Unix (termios + ANSI) and Windows (Console API) backends. Alternate-screen or inline render modes.
- **No magic.** You own state and event handling indirectly via `runTerminal`. Events flow through your `onEvent` for anything the framework doesn't consume.

### Examples

Each example is a runnable `dart` file in `example/tui/`:

| File | Demo |
|------|------|
| `01_hello.dart` | Static hello-world. |
| `02_layout.dart` | Three-zone layout with nested rows / columns. |
| `03_focus.dart` | Form with Tab navigation and validation. |
| `04_list.dart` | Scrollable `ListView` of 50 items. |
| `05_tabs.dart` | `Tabs` widget with arrow-key switching. |
| `06_async.dart` | `Async<T>` rendering loading / success / error states. |
| `07_navigation.dart` | `TuiNavigator` with push/pop between screens. |
| `08_dashboard.dart` | Real-time dashboard with `frameRate`, gauges, logs. |
| `09_inline.dart` | Inline mode (fzf-like) with filter + list. |
| `10_themed.dart` | `ThemeData` hot-swap (dark ↔ light). |

### Key documents

- `SPEC.md` — full functional specification.
- `MILESTONES.md` — implementation roadmap.

---

## Inline prompts quickstart

```dart
import 'package:commander_ui/prompt.dart';

Future<void> main() async {
  final commander = InlineCommander();
  final name = await commander.ask('Your name?');
  commander.success('Hello $name');
  await commander.dispose();
}
```

Call `await commander.dispose()` at the end so the cached terminal subscription is released cleanly. Successive prompts on the same `InlineCommander` share one terminal — no flicker, and no "stdin: not a TTY" after the first call.

`InlineCommander` covers the common CLI prompt vocabulary:

| Method | Returns | Notes |
|---|---|---|
| `ask(message, {defaultValue, placeholder, obscure, validate})` | `Future<String>` | free-form text input |
| `password(message, {validate})` | `Future<String>` | same as `ask(obscure: true)` |
| `number(message, {min, max, defaultValue, allowDecimals, validate})` | `Future<num>` | bounded numeric input |
| `select<T>(message, {options, defaultValue, display, ...})` | `Future<T>` | single choice list |
| `multiSelect<T>(message, {options, defaults, minSelections, ...})` | `Future<List<T>>` | toggle multiple |
| `confirm(message, {defaultValue})` | `Future<bool>` | y/n keypress |
| `task<T>(description, work)` | `Future<T>` | spinner while awaiting a future |
| `success/info/warn/error(message)` | `void` | styled status line on stdout |

Run the examples with `dart run example/inline/hello.dart` and `dart run example/inline/full.dart`.

---

## Compatibility

- Dart `^3.3.0`.
- Platforms: macOS, Linux, Windows 10 1909+ (Windows Terminal / PowerShell 7+).
- No runtime dependencies for TUI mode beyond `dart:ffi` (used internally for termios on Unix).

## License

MIT — see `LICENSE`.
