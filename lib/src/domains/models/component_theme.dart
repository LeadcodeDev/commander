import 'package:commander_ui/src/domains/themes/ask_theme.dart';
import 'package:commander_ui/src/domains/themes/checkbox_theme.dart';
import 'package:commander_ui/src/domains/themes/number_theme.dart';
import 'package:commander_ui/src/domains/themes/select_theme.dart';
import 'package:commander_ui/src/domains/themes/swap_theme.dart';
import 'package:commander_ui/src/domains/themes/task_theme.dart';

final class ComponentTheme {
  final AskTheme? askTheme;
  final NumberTheme? numberTheme;
  final CheckboxTheme? checkboxTheme;
  final SwapTheme? switchTheme;
  final SelectTheme? selectTheme;
  final TaskTheme? taskTheme;

  ComponentTheme(
      {this.askTheme,
      this.numberTheme,
      this.checkboxTheme,
      this.switchTheme,
      this.selectTheme,
      this.taskTheme});
}
