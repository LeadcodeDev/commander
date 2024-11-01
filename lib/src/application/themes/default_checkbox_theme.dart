import 'package:commander_ui/commander_ui.dart';
import 'package:commander_ui/src/domains/themes/checkbox_theme.dart';

final class DefaultCheckBoxTheme implements CheckboxTheme {
  @override
  String askPrefix = '?';

  @override
  String successPrefix = '✔';

  @override
  String selectedIcon = '◉';

  @override
  String unselectedIcon = '◯';

  @override
  String helpMessage =
      '(Press ↑/↓ to navigate, space to select, enter to confirm)';

  @override
  String Function(String? value) placeholderFormatter =
      (String? value) => switch (value) {
            String value => ' ($value)',
            _ => '',
          };

  @override
  List<Sequence> currentLineColor = [SetStyles(Style.foreground(Color.white))];

  @override
  List<Sequence> selectedLineColor = [SetStyles(Style.foreground(Color.white))];

  @override
  List<Sequence> defaultLineColor = [
    SetStyles(Style.foreground(Color.brightBlack))
  ];

  @override
  List<Sequence> helpMessageColor = [
    SetStyles(Style.foreground(Color.brightBlack))
  ];

  @override
  List<Sequence> successPrefixColor = [
    SetStyles(Style.foreground(Color.green))
  ];

  @override
  List<Sequence> askPrefixColor = [SetStyles(Style.foreground(Color.yellow))];

  @override
  List<Sequence> resultMessageColor = [
    SetStyles(Style.foreground(Color.brightBlack))
  ];

  @override
  List<Sequence> placeholderColorMessage = [
    SetStyles(Style.foreground(Color.brightBlack))
  ];

  DefaultCheckBoxTheme();

  /// Creates a new [CheckboxTheme] with the provided values based on [DefaultCheckBoxTheme].
  factory DefaultCheckBoxTheme.copyWith(
      {String? askPrefix,
      String? successPrefix,
      String? selectedIcon,
      String? unselectedIcon,
      String? helpMessage,
      String Function(String? value)? placeholderFormatter,
      List<Sequence>? currentLineColor,
      List<Sequence>? selectedLineColor,
      List<Sequence>? defaultLineColor,
      List<Sequence>? helpMessageColor,
      List<Sequence>? successPrefixColor,
      List<Sequence>? askPrefixColor,
      List<Sequence>? resultMessageColor,
      List<Sequence>? placeholderColorMessage}) {
    final theme = DefaultCheckBoxTheme();

    theme.askPrefix = askPrefix ?? theme.askPrefix;
    theme.successPrefix = successPrefix ?? theme.successPrefix;
    theme.selectedIcon = selectedIcon ?? theme.selectedIcon;
    theme.unselectedIcon = unselectedIcon ?? theme.unselectedIcon;
    theme.helpMessage = helpMessage ?? theme.helpMessage;
    theme.placeholderFormatter =
        placeholderFormatter ?? theme.placeholderFormatter;
    theme.currentLineColor = currentLineColor ?? theme.currentLineColor;
    theme.selectedLineColor = selectedLineColor ?? theme.selectedLineColor;
    theme.defaultLineColor = defaultLineColor ?? theme.defaultLineColor;
    theme.helpMessageColor = helpMessageColor ?? theme.helpMessageColor;
    theme.successPrefixColor = successPrefixColor ?? theme.successPrefixColor;
    theme.askPrefixColor = askPrefixColor ?? theme.askPrefixColor;
    theme.resultMessageColor = resultMessageColor ?? theme.resultMessageColor;
    theme.placeholderColorMessage =
        placeholderColorMessage ?? theme.placeholderColorMessage;

    return theme;
  }
}
