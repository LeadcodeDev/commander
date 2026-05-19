import 'dart:io';

import '../style/color.dart';
import '../style/style.dart';

class AnsiEncoder {
  final ColorMode mode;

  const AnsiEncoder(this.mode);

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
      // Windows Terminal sets WT_SESSION; modern conhost (Win10 1909+) supports
      // truecolor when VT processing is enabled. ANSICON wraps cmd.exe with
      // 16-color ANSI support.
      if (env['WT_SESSION'] != null) return ColorMode.truecolor;
      if (env['TERM_PROGRAM'] != null) return ColorMode.truecolor;
      if (env['ANSICON'] != null) return ColorMode.ansi16;
      // Conservative default: most Windows 10+ shells support truecolor once
      // VT mode is enabled; legacy Windows would already fail at SetConsoleMode.
      return ColorMode.truecolor;
    }
    if (term.contains('256color')) return ColorMode.indexed256;
    if (term == 'xterm' || term.contains('color') || term.contains('screen')) {
      return ColorMode.ansi16;
    }
    // CI systems without explicit color hints: stay conservative.
    if (env['CI'] == 'true' || env['CI'] == '1') return ColorMode.ansi16;
    return ColorMode.ansi16;
  }

  String encodeStyle(Style style) {
    if (mode == ColorMode.none && !style.bold && !style.italic &&
        !style.underline && !style.dim && !style.reverse && !style.strikethrough) {
      return '';
    }
    final codes = <int>[];
    if (style.bold) codes.add(1);
    if (style.dim) codes.add(2);
    if (style.italic) codes.add(3);
    if (style.underline) codes.add(4);
    if (style.reverse) codes.add(7);
    if (style.strikethrough) codes.add(9);
    if (mode != ColorMode.none) {
      if (style.fg != null) {
        codes.addAll(_encodeColor(style.fg!, foreground: true));
      }
      if (style.bg != null) {
        codes.addAll(_encodeColor(style.bg!, foreground: false));
      }
    }
    if (codes.isEmpty) return '';
    return '\x1B[${codes.join(';')}m';
  }

  String reset() => '\x1B[0m';

  List<int> _encodeColor(Color color, {required bool foreground}) {
    final downgraded = _downgrade(color, mode);
    return switch (downgraded) {
      AnsiColorValue(:final color) => [
          foreground ? color.fgCode : color.bgCode,
        ],
      IndexedColor(:final index) => [
          foreground ? 38 : 48,
          5,
          index,
        ],
      TruecolorColor(:final r, :final g, :final b) => [
          foreground ? 38 : 48,
          2,
          r,
          g,
          b,
        ],
    };
  }

  Color _downgrade(Color color, ColorMode targetMode) {
    return switch (color) {
      AnsiColorValue() => color,
      IndexedColor(:final index) => switch (targetMode) {
          ColorMode.truecolor || ColorMode.indexed256 => color,
          ColorMode.ansi16 => _indexedToAnsi(index),
          ColorMode.none => color,
        },
      TruecolorColor(:final r, :final g, :final b) => switch (targetMode) {
          ColorMode.truecolor => color,
          ColorMode.indexed256 => Color.indexed(_rgbToIndexed(r, g, b)),
          ColorMode.ansi16 => _rgbToAnsi(r, g, b),
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

  Color _rgbToAnsi(int r, int g, int b) {
    const palette = <(AnsiColor, int, int, int)>[
      (AnsiColor.black, 0, 0, 0),
      (AnsiColor.red, 170, 0, 0),
      (AnsiColor.green, 0, 170, 0),
      (AnsiColor.yellow, 170, 85, 0),
      (AnsiColor.blue, 0, 0, 170),
      (AnsiColor.magenta, 170, 0, 170),
      (AnsiColor.cyan, 0, 170, 170),
      (AnsiColor.white, 170, 170, 170),
      (AnsiColor.brightBlack, 85, 85, 85),
      (AnsiColor.brightRed, 255, 85, 85),
      (AnsiColor.brightGreen, 85, 255, 85),
      (AnsiColor.brightYellow, 255, 255, 85),
      (AnsiColor.brightBlue, 85, 85, 255),
      (AnsiColor.brightMagenta, 255, 85, 255),
      (AnsiColor.brightCyan, 85, 255, 255),
      (AnsiColor.brightWhite, 255, 255, 255),
    ];
    var bestDist = 1 << 30;
    AnsiColor best = AnsiColor.white;
    for (final (c, pr, pg, pb) in palette) {
      final d = (pr - r) * (pr - r) + (pg - g) * (pg - g) + (pb - b) * (pb - b);
      if (d < bestDist) {
        bestDist = d;
        best = c;
      }
    }
    return Color.ansi(best);
  }

  Color _indexedToAnsi(int idx) {
    if (idx < 16) {
      return Color.ansi(AnsiColor.values[idx]);
    }
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
  static const String enableMouse = '\x1B[?1000h\x1B[?1002h\x1B[?1003h\x1B[?1006h';
  static const String disableMouse = '\x1B[?1006l\x1B[?1003l\x1B[?1002l\x1B[?1000l';

  static String moveTo(int x, int y) => '\x1B[${y + 1};${x + 1}H';
}
