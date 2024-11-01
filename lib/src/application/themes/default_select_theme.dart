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

  DefaultSelectTheme();

  factory DefaultSelectTheme.copyWith(
      {String? askPrefix,
      String? successPrefix,
      String? selectedIcon,
      String? unselectedIcon,
      String? helpMessage,
      List<Sequence>? selectedIconColor,
      List<Sequence>? unselectedIconColor,
      List<Sequence>? placeholderColorMessage,
      List<Sequence>? filterColorMessage,
      List<Sequence>? helpColorMessage,
      List<Sequence>? currentLineColor,
      List<Sequence>? selectedLineColor,
      List<Sequence>? defaultLineColor,
      List<Sequence>? successPrefixColor,
      List<Sequence>? askPrefixColor,
      List<Sequence>? resultMessageColor}) {
    final theme = DefaultSelectTheme();

    theme.askPrefix = askPrefix ?? theme.askPrefix;
    theme.successPrefix = successPrefix ?? theme.successPrefix;
    theme.selectedIcon = selectedIcon ?? theme.selectedIcon;
    theme.unselectedIcon = unselectedIcon ?? theme.unselectedIcon;
    theme.helpMessage = helpMessage ?? theme.helpMessage;
    theme.selectedIconColor = selectedIconColor ?? theme.selectedIconColor;
    theme.unselectedIconColor = unselectedIconColor ?? theme.unselectedIconColor;
    theme.placeholderColorMessage = placeholderColorMessage ?? theme.placeholderColorMessage;
    theme.filterColorMessage = filterColorMessage ?? theme.filterColorMessage;
    theme.helpColorMessage = helpColorMessage ?? theme.helpColorMessage;
    theme.currentLineColor = currentLineColor ?? theme.currentLineColor;
    theme.selectedLineColor = selectedLineColor ?? theme.selectedLineColor;
    theme.defaultLineColor = defaultLineColor ?? theme.defaultLineColor;
    theme.successPrefixColor = successPrefixColor ?? theme.successPrefixColor;
    theme.askPrefixColor = askPrefixColor ?? theme.askPrefixColor;
    theme.resultMessageColor = resultMessageColor ?? theme.resultMessageColor;

    return theme;
  }
}
