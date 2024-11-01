import 'package:commander_ui/commander_ui.dart';
import 'package:commander_ui/src/domains/themes/select_theme.dart';

final class DefaultSelectTheme implements SelectTheme {
  @override
  String askPrefix = '?';

  @override
  String successPrefix = '✔';

  @override
  String selectedIcon = '❯';

  @override
  String unselectedIcon = ' ';

  @override
  String helpMessage = '(Type to filter, press ↑/↓ to navigate, enter to select)';

  @override
  List<Sequence> selectedIconColor = [SetStyles(Style.foreground(Color.brightGreen))];

  @override
  List<Sequence> unselectedIconColor = [];

  @override
  List<Sequence> placeholderColorMessage = [SetStyles(Style.foreground(Color.brightBlack))];

  @override
  List<Sequence> filterColorMessage = [SetStyles(Style.foreground(Color.brightBlack))];

  @override
  List<Sequence> helpColorMessage = [SetStyles(Style.foreground(Color.brightBlack))];

  @override
  List<Sequence> currentLineColor = [SetStyles(Style.foreground(Color.white))];

  @override
  List<Sequence> selectedLineColor = [SetStyles(Style.foreground(Color.white))];

  @override
  List<Sequence> defaultLineColor = [SetStyles(Style.foreground(Color.brightBlack))];

  @override
  List<Sequence> successPrefixColor = [SetStyles(Style.foreground(Color.green))];

  @override
  List<Sequence> askPrefixColor = [SetStyles(Style.foreground(Color.yellow))];

  @override
  List<Sequence> resultMessageColor = [SetStyles(Style.foreground(Color.brightBlack))];
}
