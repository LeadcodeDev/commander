import 'package:commander_ui/commander_ui.dart';

final class DefaultSwapTheme implements SwapTheme {
  @override
  String askPrefix = '?';

  @override
  String successPrefix = '✔';

  @override
  String helpMessage = '(Press ←/→ to select, enter to confirm)';

  @override
  String Function(String? value) placeholderFormatter =
      (String? value) => switch (value) {
            String value => ' ($value)',
            _ => '',
          };

  @override
  List<Sequence> selected = [SetStyles(Style.foreground(Color.brightBlack))];

  @override
  List<Sequence> unselected = [SetStyles(Style.foreground(Color.reset))];

  @override
  List<Sequence> placeholderColorMessage = [
    SetStyles(Style.foreground(Color.brightBlack))
  ];

  @override
  List<Sequence> askPrefixColor = [SetStyles(Style.foreground(Color.yellow))];

  @override
  List<Sequence> helpMessageColor = [
    SetStyles(Style.foreground(Color.brightBlack))
  ];

  @override
  List<Sequence> successPrefixColor = [
    SetStyles(Style.foreground(Color.green))
  ];

  @override
  List<Sequence> resultMessageColor = [
    SetStyles(Style.foreground(Color.brightBlack))
  ];

  DefaultSwapTheme();

  /// Creates a new [SwapTheme] with the provided values based on [DefaultSwapTheme].
  factory DefaultSwapTheme.copyWith(
      {String? askPrefix,
      String? successPrefix,
      String? helpMessage,
      String Function(String? value)? placeholderFormatter,
      List<Sequence>? selected,
      List<Sequence>? unselected,
      List<Sequence>? placeholderColorMessage,
      List<Sequence>? askPrefixColor,
      List<Sequence>? helpMessageColor,
      List<Sequence>? successPrefixColor,
      List<Sequence>? resultMessageColor}) {
    final theme = DefaultSwapTheme();

    theme.askPrefix = askPrefix ?? theme.askPrefix;
    theme.successPrefix = successPrefix ?? theme.successPrefix;
    theme.helpMessage = helpMessage ?? theme.helpMessage;
    theme.placeholderFormatter =
        placeholderFormatter ?? theme.placeholderFormatter;
    theme.selected = selected ?? theme.selected;
    theme.unselected = unselected ?? theme.unselected;
    theme.placeholderColorMessage =
        placeholderColorMessage ?? theme.placeholderColorMessage;
    theme.askPrefixColor = askPrefixColor ?? theme.askPrefixColor;
    theme.helpMessageColor = helpMessageColor ?? theme.helpMessageColor;
    theme.successPrefixColor = successPrefixColor ?? theme.successPrefixColor;
    theme.resultMessageColor = resultMessageColor ?? theme.resultMessageColor;

    return theme;
  }
}
