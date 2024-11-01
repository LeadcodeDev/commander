import 'package:commander_ui/commander_ui.dart';

final class DefaultTaskTheme implements TaskTheme {
  @override
  List<String> loadingSymbols = [
    '⠋',
    '⠙',
    '⠹',
    '⠸',
    '⠼',
    '⠴',
    '⠦',
    '⠧',
    '⠇',
    '⠏'
  ];

  @override
  List<Sequence> loadingSymbolColor = [
    SetStyles(Style.foreground(Color.green))
  ];

  @override
  String successPrefix = '✔ ';

  @override
  String errorPrefix = '✘ ';

  @override
  String warningPrefix = '⚠ ';

  @override
  List<Sequence> successPrefixColor = [
    SetStyles(Style.foreground(Color.green))
  ];

  @override
  List<Sequence> errorPrefixColor = [SetStyles(Style.foreground(Color.red))];

  @override
  List<Sequence> warningPrefixColor = [
    SetStyles(Style.foreground(Color.yellow))
  ];

  @override
  List<Sequence> defaultColor = [
    SetStyles(Style.foreground(Color.brightBlack))
  ];

  DefaultTaskTheme();

  factory DefaultTaskTheme.copyWith(
      {List<String>? loadingSymbols,
      List<Sequence>? loadingSymbolColor,
      String? successPrefix,
      String? errorPrefix,
      String? warningPrefix,
      List<Sequence>? successPrefixColor,
      List<Sequence>? errorPrefixColor,
      List<Sequence>? warningPrefixColor,
      List<Sequence>? defaultColor}) {
    final theme = DefaultTaskTheme();

    theme.loadingSymbols = loadingSymbols ?? theme.loadingSymbols;
    theme.loadingSymbolColor = loadingSymbolColor ?? theme.loadingSymbolColor;
    theme.successPrefix = successPrefix ?? theme.successPrefix;
    theme.errorPrefix = errorPrefix ?? theme.errorPrefix;
    theme.warningPrefix = warningPrefix ?? theme.warningPrefix;
    theme.successPrefixColor = successPrefixColor ?? theme.successPrefixColor;
    theme.errorPrefixColor = errorPrefixColor ?? theme.errorPrefixColor;
    theme.warningPrefixColor = warningPrefixColor ?? theme.warningPrefixColor;
    theme.defaultColor = defaultColor ?? theme.defaultColor;

    return theme;
  }
}
