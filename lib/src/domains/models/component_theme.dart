import 'package:commander_ui/src/domains/themes/ask_theme.dart';
import 'package:commander_ui/src/domains/themes/checkbox_theme.dart';
import 'package:commander_ui/src/domains/themes/select_theme.dart';
import 'package:commander_ui/src/domains/themes/swap_theme.dart';

final class ComponentTheme {
  final AskTheme? askTheme;
  final CheckboxTheme? checkboxTheme;
  final SwapTheme? switchTheme;
  final SelectTheme? selectTheme;

  ComponentTheme({this.askTheme, this.checkboxTheme, this.switchTheme, this.selectTheme});
}
