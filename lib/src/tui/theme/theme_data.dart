import '../style/border.dart';
import '../style/color.dart';
import '../style/style.dart';

class ColorScheme {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color foreground;
  final Color error;
  final Color success;
  final Color warning;
  final Color info;
  final Color muted;

  const ColorScheme({
    this.primary = Color.cyan,
    this.secondary = Color.magenta,
    this.background = Color.black,
    this.foreground = Color.white,
    this.error = Color.red,
    this.success = Color.green,
    this.warning = Color.yellow,
    this.info = Color.brightBlue,
    this.muted = Color.brightBlack,
  });
}

class BorderTheme {
  final BorderStyle style;
  final BorderStyle focusedStyle;
  final Style strokeStyle;
  final Style focusedStrokeStyle;

  const BorderTheme({
    this.style = BorderStyle.single,
    this.focusedStyle = BorderStyle.double,
    this.strokeStyle = Style.none,
    this.focusedStrokeStyle = Style.none,
  });
}

class TextTheme {
  final Style title;
  final Style body;
  final Style caption;
  final Style code;

  const TextTheme({
    this.title = const Style(bold: true),
    this.body = Style.none,
    this.caption = const Style(dim: true),
    this.code = Style.none,
  });
}

class ThemeData {
  final ColorScheme colors;
  final BorderTheme borders;
  final TextTheme text;

  const ThemeData({
    this.colors = const ColorScheme(),
    this.borders = const BorderTheme(),
    this.text = const TextTheme(),
  });

  static const ThemeData dark = ThemeData();

  static const ThemeData light = ThemeData(
    colors: ColorScheme(
      background: Color.white,
      foreground: Color.black,
      muted: Color.brightBlack,
    ),
  );
}
