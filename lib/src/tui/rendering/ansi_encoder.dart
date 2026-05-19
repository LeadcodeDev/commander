import 'dart:io';

import 'package:mansion/mansion.dart' as m;

import '../style/color.dart';
import '../style/style.dart';

/// Encodes Commander [Style] values into ANSI escape sequences.
///
/// Encoding itself is delegated to `package:mansion` (one
/// [m.SetStyles] sequence per call). What stays local is:
///
/// - Terminal capability detection ([detect]).
/// - Downgrading colors when the detected mode is narrower than what the
///   caller asked for (truecolor → 256 → 16 → none).
class AnsiEncoder {
  final ColorMode mode;

  const AnsiEncoder(this.mode);

  /// Returns the empty string when [style] is the default style, otherwise
  /// the matching `\x1B[…m` sequence built from a single mansion
  /// [m.SetStyles].
  String encodeStyle(Style style) {
    final hasAttrs = style.bold ||
        style.italic ||
        style.underline ||
        style.dim ||
        style.reverse ||
        style.strikethrough;
    final hasColors = mode != ColorMode.none &&
        (style.fg != null || style.bg != null);
    if (!hasAttrs && !hasColors) return '';

    final pieces = <m.Style>{};
    if (style.bold) pieces.add(m.Style.bold);
    if (style.dim) pieces.add(m.Style.dim);
    if (style.italic) pieces.add(m.Style.italic);
    if (style.underline) pieces.add(m.Style.underline);
    if (style.reverse) pieces.add(m.Style.invert);
    if (style.strikethrough) pieces.add(m.Style.strikeThrough);

    if (hasColors) {
      final fg = style.fg;
      if (fg != null) pieces.add(m.Style.foreground(_downgrade(fg, mode)));
      final bg = style.bg;
      if (bg != null) pieces.add(m.Style.background(_downgrade(bg, mode)));
    }

    if (pieces.isEmpty) return '';
    final buf = StringBuffer();
    m.SetStyles.from(pieces).writeAnsiString(buf);
    return buf.toString();
  }

  /// Reset all styles (delegated to mansion).
  String reset() {
    final buf = StringBuffer();
    m.SetStyles.reset.writeAnsiString(buf);
    return buf.toString();
  }

  /// Auto-detects terminal capabilities from `TERM`, `COLORTERM`, `NO_COLOR`,
  /// `WT_SESSION` and friends. Returns the broadest mode that the current
  /// terminal is expected to support.
  static ColorMode detect() {
    final env = Platform.environment;
    if (env['NO_COLOR'] != null) return ColorMode.none;
    if (!stdout.hasTerminal) return ColorMode.none;
    final term = env['TERM']?.toLowerCase() ?? '';
    if (term == 'dumb') return ColorMode.none;
    final colorterm = env['COLORTERM']?.toLowerCase();
    if (colorterm == 'truecolor' || colorterm == '24bit') {
      return ColorMode.truecolor;
    }
    if (Platform.isWindows) {
      if (env['WT_SESSION'] != null) return ColorMode.truecolor;
      if (env['TERM_PROGRAM'] != null) return ColorMode.truecolor;
      if (env['ANSICON'] != null) return ColorMode.ansi16;
      return ColorMode.truecolor;
    }
    if (term.contains('256color')) return ColorMode.indexed256;
    if (term == 'xterm' || term.contains('color') || term.contains('screen')) {
      return ColorMode.ansi16;
    }
    if (env['CI'] == 'true' || env['CI'] == '1') return ColorMode.ansi16;
    return ColorMode.ansi16;
  }

  /// Narrows [color] to the broadest representation supported by [target].
  /// Same algorithm as before, expressed against mansion's color types.
  Color _downgrade(Color color, ColorMode target) {
    return switch (color) {
      ColorReset() => color,
      Color4() => color,
      Color8(:final index) => switch (target) {
          ColorMode.truecolor || ColorMode.indexed256 => color,
          ColorMode.ansi16 => _indexedToAnsi(index),
          ColorMode.none => color,
        },
      Color24(:final red, :final green, :final blue) => switch (target) {
          ColorMode.truecolor => color,
          ColorMode.indexed256 => Color8.fromIndex(_rgbToIndexed(red, green, blue)),
          ColorMode.ansi16 => _rgbToAnsi(red, green, blue),
          ColorMode.none => color,
        },
    };
  }

  int _rgbToIndexed(int r, int g, int b) {
    if (r == g && g == b) {
      if (r < 8) return 16;
      if (r > 248) return 231;
      return 232 + ((r - 8) / 247 * 24).round();
    }
    final ri = (r / 255 * 5).round();
    final gi = (g / 255 * 5).round();
    final bi = (b / 255 * 5).round();
    return 16 + 36 * ri + 6 * gi + bi;
  }

  Color4 _rgbToAnsi(int r, int g, int b) {
    const palette = <(Color4, int, int, int)>[
      (Color4.black, 0, 0, 0),
      (Color4.red, 170, 0, 0),
      (Color4.green, 0, 170, 0),
      (Color4.yellow, 170, 85, 0),
      (Color4.blue, 0, 0, 170),
      (Color4.magenta, 170, 0, 170),
      (Color4.cyan, 0, 170, 170),
      (Color4.white, 170, 170, 170),
      (Color4.brightBlack, 85, 85, 85),
      (Color4.brightRed, 255, 85, 85),
      (Color4.brightGreen, 85, 255, 85),
      (Color4.brightYellow, 255, 255, 85),
      (Color4.brightBlue, 85, 85, 255),
      (Color4.brightMagenta, 255, 85, 255),
      (Color4.brightCyan, 85, 255, 255),
      (Color4.brightWhite, 255, 255, 255),
    ];
    var bestDist = 1 << 30;
    Color4 best = Color4.white;
    for (final (c, pr, pg, pb) in palette) {
      final d = (pr - r) * (pr - r) + (pg - g) * (pg - g) + (pb - b) * (pb - b);
      if (d < bestDist) {
        bestDist = d;
        best = c;
      }
    }
    return best;
  }

  Color _indexedToAnsi(int idx) {
    if (idx < 16) return Color4.values[idx];
    if (idx >= 232) {
      final v = ((idx - 232) * 247 / 24).round() + 8;
      return _rgbToAnsi(v, v, v);
    }
    final i = idx - 16;
    final r = (i ~/ 36) * 51;
    final g = ((i ~/ 6) % 6) * 51;
    final b = (i % 6) * 51;
    return _rgbToAnsi(r, g, b);
  }
}

class AnsiSequences {
  static const String reset = '\x1B[0m';
  static const String clear = '\x1B[2J';
  static const String clearLine = '\x1B[2K';
  static const String home = '\x1B[H';
  static const String hideCursor = '\x1B[?25l';
  static const String showCursor = '\x1B[?25h';
  static const String enterAlt = '\x1B[?1049h';
  static const String leaveAlt = '\x1B[?1049l';
  static const String enableMouse =
      '\x1B[?1000h\x1B[?1002h\x1B[?1003h\x1B[?1006h';
  static const String disableMouse =
      '\x1B[?1006l\x1B[?1003l\x1B[?1002l\x1B[?1000l';

  static String moveTo(int x, int y) => '\x1B[${y + 1};${x + 1}H';
}
