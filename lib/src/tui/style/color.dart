enum AnsiColor {
  black(30),
  red(31),
  green(32),
  yellow(33),
  blue(34),
  magenta(35),
  cyan(36),
  white(37),
  brightBlack(90),
  brightRed(91),
  brightGreen(92),
  brightYellow(93),
  brightBlue(94),
  brightMagenta(95),
  brightCyan(96),
  brightWhite(97);

  final int fgCode;
  const AnsiColor(this.fgCode);

  int get bgCode => fgCode + 10;
}

sealed class Color {
  const Color();

  factory Color.ansi(AnsiColor c) = AnsiColorValue;
  factory Color.indexed(int index) = IndexedColor;
  factory Color.rgb(int r, int g, int b) = TruecolorColor;

  static const Color black = AnsiColorValue(AnsiColor.black);
  static const Color red = AnsiColorValue(AnsiColor.red);
  static const Color green = AnsiColorValue(AnsiColor.green);
  static const Color yellow = AnsiColorValue(AnsiColor.yellow);
  static const Color blue = AnsiColorValue(AnsiColor.blue);
  static const Color magenta = AnsiColorValue(AnsiColor.magenta);
  static const Color cyan = AnsiColorValue(AnsiColor.cyan);
  static const Color white = AnsiColorValue(AnsiColor.white);
  static const Color gray = AnsiColorValue(AnsiColor.brightBlack);
  static const Color brightRed = AnsiColorValue(AnsiColor.brightRed);
  static const Color brightGreen = AnsiColorValue(AnsiColor.brightGreen);
  static const Color brightYellow = AnsiColorValue(AnsiColor.brightYellow);
  static const Color brightBlue = AnsiColorValue(AnsiColor.brightBlue);
  static const Color brightMagenta = AnsiColorValue(AnsiColor.brightMagenta);
  static const Color brightCyan = AnsiColorValue(AnsiColor.brightCyan);
  static const Color brightWhite = AnsiColorValue(AnsiColor.brightWhite);
}

final class AnsiColorValue extends Color {
  final AnsiColor color;
  const AnsiColorValue(this.color);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnsiColorValue && other.color == color);

  @override
  int get hashCode => color.hashCode;

  @override
  String toString() => 'Color.ansi(${color.name})';
}

final class IndexedColor extends Color {
  final int index;
  const IndexedColor(this.index)
      : assert(index >= 0 && index < 256);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IndexedColor && other.index == index);

  @override
  int get hashCode => index.hashCode;

  @override
  String toString() => 'Color.indexed($index)';
}

final class TruecolorColor extends Color {
  final int r;
  final int g;
  final int b;
  const TruecolorColor(this.r, this.g, this.b)
      : assert(r >= 0 && r < 256),
        assert(g >= 0 && g < 256),
        assert(b >= 0 && b < 256);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TruecolorColor &&
          other.r == r &&
          other.g == g &&
          other.b == b);

  @override
  int get hashCode => Object.hash(r, g, b);

  @override
  String toString() => 'Color.rgb($r,$g,$b)';
}

enum ColorMode {
  none,
  ansi16,
  indexed256,
  truecolor,
}
