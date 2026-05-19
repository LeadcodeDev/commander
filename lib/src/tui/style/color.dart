/// Color primitives used by Commander's TUI style system.
///
/// Colors are re-exported from `package:mansion` so that the encoder, the
/// theme, and any user code share a single representation. Mansion's
/// [Color] sealed class covers the three palettes:
///
/// - `Color4.*` — the 16 ANSI colors (also available via `Color.red`,
///   `Color.brightGreen`, …).
/// - `Color.from256(int)` — the 256-color (xterm) palette.
/// - `Color.fromRGB(r, g, b)` — 24-bit truecolor.
///
/// The [ColorMode] enum is local to Commander and drives terminal
/// capability detection + automatic downgrading inside `AnsiEncoder`.
library;

export 'package:mansion/mansion.dart' show Color, Color4, Color8, Color24, ColorReset;

/// Terminal color capability tier, used by `AnsiEncoder` to decide whether
/// to emit truecolor / 256-color / 16-color escape sequences (or none).
enum ColorMode {
  none,
  ansi16,
  indexed256,
  truecolor,
}
