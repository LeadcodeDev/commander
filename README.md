# Commander

Commander is a Dart library for building terminal user interfaces in two complementary styles : a one-shot **prompt** API for CLI scripts, and a full **TUI** framework for stateful applications.

[![pub package](https://img.shields.io/pub/v/commander_ui.svg)](https://pub.dev/packages/commander_ui)
[![pub points](https://img.shields.io/pub/points/commander_ui)](https://pub.dev/packages/commander_ui/score)
[![pub likes](https://img.shields.io/pub/likes/commander_ui)](https://pub.dev/packages/commander_ui/score)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

```yaml
dependencies:
  commander_ui: ^3.0.0
```

> **3.0.0 is a breaking release.** The legacy `Commander` class and `package:commander_ui/inline.dart` are gone. Use `InlineCommander` from `package:commander_ui/prompt.dart` instead. See [CHANGELOG.md](CHANGELOG.md) for the migration cheat sheet.

---

## Two entry points, one runtime

| Library                            | Use case                                                                    | Mental model                                                                                             |
| ---------------------------------- | --------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `package:commander_ui/prompt.dart` | One-shot prompts inside a CLI script (`final name = await c.ask('?')`)      | Each call opens a small flow-mode TUI session, captures one value, restores the terminal.                |
| `package:commander_ui/tui.dart`    | Full applications: dashboards, multi-screen wizards, file explorers, REPLs. | Immediate-mode rendering driven by `runTerminal(...)`. You own state; the framework owns the frame loop. |

Both share the same runtime — `InlineCommander` is built on top of the TUI widgets, so prompts and full apps render through the exact same code path.

---

## Inline prompts (`prompt.dart`)

The 4-line entrypoint:

```dart
import 'package:commander_ui/prompt.dart';

Future<void> main() async {
  final commander = InlineCommander();

  final name = await commander.ask('Your name?');
  commander.success('Hello $name');

  await commander.dispose();
}
```

`commander.dispose()` releases the cached terminal. Successive prompts on the same `InlineCommander` share one terminal — no flicker, no `stdin: not a TTY` after the first call.

### Methods on `InlineCommander`

| Method                                                                           | Returns           | Backed by              |
| -------------------------------------------------------------------------------- | ----------------- | ---------------------- |
| `ask(message, {defaultValue, placeholder, obscure, validate})`                   | `Future<String>`  | `Input`                |
| `password(message, {validate})`                                                  | `Future<String>`  | `Input(obscure: true)` |
| `number(message, {min, max, defaultValue, allowDecimals, validate})`             | `Future<num>`     | `InputNumber`          |
| `select<T>(message, {options, defaultValue, display, visibleCount, filterable})` | `Future<T>`       | `Select` (single)      |
| `multiSelect<T>(message, {options, defaults, minSelections, maxSelections, …})`  | `Future<List<T>>` | `Select` (multi)       |
| `confirm(message, {defaultValue})`                                               | `Future<bool>`    | `Confirm`              |
| `task<T>(description, work)`                                                     | `Future<T>`       | `Async<T>` + `Spinner` |
| `success/info/warn/error(message)`                                               | `void`            | mansion-styled stdout  |

Throws `PromptCancelledException` on Ctrl-C.

Examples: `dart run example/inline/hello.dart`, `dart run example/inline/full.dart`.

---

## TUI framework (`tui.dart`)

```dart
import 'package:commander_ui/tui.dart';

class HelloState {}

Future<void> main() => runTerminal<HelloState>(
  initialState: HelloState(),
  onEvent: (state, event, handle) {
    if (event is KeyEvent && event.key == NamedKey.escape) handle.stop();
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

### Core principles

- **Immediate-mode rendering.** Each frame, `render(ctx, state)` describes the full UI. The framework diffs cell buffers and emits the minimal escape sequence.
- **No widget tree state.** Widgets are values. State lives in your own `AppState`. No `initState`/`dispose` lifecycle to learn.
- **Focus management built in.** Any widget with an `id: Key` becomes focusable. Tab cycles in render order; modals push focus scopes via `ctx.scope`.
- **Async without state plumbing.** `Async<T>`, `AsyncResult<T, E>`, `AsyncStream<T>` track futures/streams by `Key`, restart on key change, and render `onLoading`/`onSuccess`/`onError` declaratively.
- **Cross-platform.** Unix (termios + ANSI) and Windows (Console API) backends. Alternate-screen, full-screen, flow, or inline render modes.
- **Built on mansion.** Color encoding, ANSI escapes, cursor/screen control all go through `package:mansion` — a single source of truth for the wire format.

### Widget catalogue

| Category       | Widgets                                                                                                                                                                                   |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Display**    | `Text`, `Paragraph`, `Block`, `Container`, `Padding`, `Spacer`, `Divider`, `Each`, `Row`/`Column`, `Stack`, `Focusable`, `Screen`, `ScrollView`, `CodeBlock` (with optional `scrollable`) |
| **Input**      | `Input`, `TextField`, `TextArea`, `InputNumber`, `Checkbox`, `CheckboxGroup`, `RadioGroup`, `Switch`, `Confirm`, `Button`, `Slider`, `Range`, `DatePicker`, `TimePicker`                  |
| **List**       | `ListView`, `Select`, `Dropdown`, `Tabs`, `Tree`, `Table`                                                                                                                                 |
| **Feedback**   | `ProgressBar`, `Spinner`, `Gauge`                                                                                                                                                         |
| **Charts**     | `Sparkline`, `BarChart`                                                                                                                                                                   |
| **Async**      | `Async<T>`, `AsyncResult<T, E>`, `AsyncStream<T>`                                                                                                                                         |
| **Chain**      | `Chain.flow` — sequential async prompts inside a single `runTerminal`                                                                                                                     |
| **Navigation** | `TuiNavigator` — push/pop screens with focus restore                                                                                                                                      |

### Render modes

- `RenderMode.alternateScreen()` — owns the viewport, restores previous screen on exit (best for fullscreen apps).
- `RenderMode.fullScreen()` — clears the main buffer, no save/restore.
- `RenderMode.flow({height, minHeight, autoGrow})` — renders inline below the cursor, leaves output in scrollback (best for CLI prompts and short interactive sections).
- `RenderMode.inline({height})` — fixed-height inline region.

### Styling

Colors are mansion's — `Color.red`, `Color.brightGreen`, `Color.from256(196)`, `Color.fromRGB(r, g, b)`. The `Style` value bundles `fg`, `bg`, and attributes (`bold`, `italic`, `underline`, `dim`, `reverse`, `strikethrough`). Themes (`ThemeData`) hot-swap via `themeBuilder`.

### Testing

`TestTerminal` injects events and captures the rendered buffer:

```dart
import 'package:commander_ui/tui.dart';
import 'package:test/test.dart';

test('Input submits on Enter', () {
  final state = InputState();
  final widget = Input(id: Key.symbol(#i), message: 'Name?', state: state);

  widget.onKey(const KeyEvent(char: 'a'), _ctx());
  widget.onKey(const KeyEvent(key: NamedKey.enter), _ctx());

  expect(state.value, 'a');
  expect(state.submitted, isTrue);
});
```

For end-to-end driving, `runTerminal(terminal: TestTerminal(), allowNonInteractive: true)` plus `term.inject(KeyEvent(...))` drives a real frame loop without touching stdin.

### Examples

Runnable demos live in `example/tui/` and `example/inline/`:

| File                           | Demo                                                              |
| ------------------------------ | ----------------------------------------------------------------- |
| `tui/01_hello.dart`            | Static hello-world.                                               |
| `tui/02_layout.dart`           | Three-zone layout with nested rows / columns.                     |
| `tui/03_focus.dart`            | Form with Tab navigation and validation.                          |
| `tui/04_list.dart`             | Scrollable `ListView` of 50 items.                                |
| `tui/05_tabs.dart`             | `Tabs` widget with arrow-key switching.                           |
| `tui/06_async.dart`            | `Async<T>` rendering loading / success / error states.            |
| `tui/07_navigation.dart`       | `TuiNavigator` push/pop between screens.                          |
| `tui/08_dashboard.dart`        | Real-time dashboard with `frameRate`, gauges, logs.               |
| `tui/09_inline.dart`           | Inline mode (fzf-like) with filter + list.                        |
| `tui/10_themed.dart`           | `ThemeData` hot-swap (dark ↔ light).                              |
| `tui/11_tabs_inputs.dart`      | Tabs hosting focusable input widgets.                             |
| `tui/12_select.dart`           | `Select` single + multi with filter, validation.                  |
| `tui/13_checkbox_group.dart`   | `CheckboxGroup` toggling.                                         |
| `tui/14_switch.dart`           | `Switch` on/off indicator.                                        |
| `tui/15_table.dart`            | `Table` with sorting, filtering, multi-select.                    |
| `tui/16_screen.dart`           | `Screen` widget with title + body.                                |
| `tui/17_input.dart`            | `Chain.flow` sequential prompts.                                  |
| `tui/18_numeric_inputs.dart`   | `InputNumber`, `Slider`, `Range`.                                 |
| `tui/19_advanced_widgets.dart` | `TimePicker`, charts, `TextArea`, `Tree`, scrollable `CodeBlock`. |
| `inline/hello.dart`            | The 4-line `InlineCommander` baseline.                            |
| `inline/full.dart`             | Every `InlineCommander` method in sequence.                       |

---

## Compatibility

- Dart `^3.3.0`.
- Platforms: macOS, Linux, Windows 10 1909+ (Windows Terminal / PowerShell 7+).
- Runtime deps: `mansion` (ANSI sequences), `ffi` + `win32` (terminal modes), `collection`.

## Project documents

- [`SPEC.md`](SPEC.md) — full functional specification.
- [`MILESTONES.md`](MILESTONES.md) — implementation roadmap.
- [`SELECT_WIDGET_SPEC.md`](SELECT_WIDGET_SPEC.md), [`TABLE_WIDGET_SPEC.md`](TABLE_WIDGET_SPEC.md) — widget design notes.
- [`CHANGELOG.md`](CHANGELOG.md) — release history + migration notes.

## License

MIT — see [`LICENSE`](LICENSE).
