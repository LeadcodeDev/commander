/// Commander Prompt — one-shot interactive CLI prompts built on the TUI runtime.
///
/// Exposes [InlineCommander] for `ask`, `select`, `multiSelect`, `confirm`,
/// `number`, `password`, `task`, and the non-interactive status helpers
/// `success`, `info`, `warn`, `error`.
///
/// For a full declarative TUI framework, see `package:commander_ui/tui.dart`.
library;

export 'src/prompt/inline_commander.dart' show InlineCommander;
export 'src/prompt/run_one_shot.dart' show PromptCancelledException;
