import 'package:commander_ui/src/domains/themes/ask_theme.dart';
import 'package:mansion/mansion.dart';

final class DefaultAskTheme implements AskTheme {
  @override
  String askPrefix = '?';

  @override
  String errorSuffix = '✘';

  @override
  String successSuffix = '✔';

  @override
  String Function(String? value) secureFormatter =
      (String? value) => value?.replaceAll(RegExp(r'.'), '*') ?? '';

  @override
  String Function(String? value) defaultValueFormatter =
      (String? value) => switch (value) {
            String value => ' ($value)',
            _ => '',
          };

  @override
  String? Function(String? value) inputFormatter = (String? value) => value;

  @override
  List<Sequence> successPrefixColor = [
    SetStyles.reset,
    SetStyles(Style.foreground(Color.green))
  ];

  @override
  List<Sequence> errorPrefixColor = [
    SetStyles(Style.foreground(Color.brightRed))
  ];

  @override
  List<Sequence> askPrefixColor = [SetStyles(Style.foreground(Color.yellow))];

  @override
  List<Sequence> validatorColorMessage = [
    SetStyles(Style.foreground(Color.brightRed))
  ];

  @override
  List<Sequence> defaultValueColorMessage = [
    SetStyles(Style.foreground(Color.brightBlack))
  ];

  @override
  List<Sequence> inputColor = [SetStyles(Style.foreground(Color.brightBlack))];

  DefaultAskTheme();

  /// Creates a new [AskTheme] with the provided values based on [DefaultAskTheme].
  factory DefaultAskTheme.copyWith(
      {String? askPrefix,
      String? errorSuffix,
      String? successSuffix,
      String Function(String? value)? secureFormatter,
      String Function(String? value)? defaultValueFormatter,
      String? Function(String? value)? inputFormatter,
      List<Sequence>? successPrefixColor,
      List<Sequence>? errorPrefixColor,
      List<Sequence>? validatorColorMessage,
      List<Sequence>? askPrefixColor,
      List<Sequence>? defaultValueColorMessage,
      List<Sequence>? inputColor}) {
    final theme = DefaultAskTheme();

    theme.askPrefix = askPrefix ?? theme.askPrefix;
    theme.errorSuffix = errorSuffix ?? theme.errorSuffix;
    theme.successSuffix = successSuffix ?? theme.successSuffix;
    theme.secureFormatter = secureFormatter ?? theme.secureFormatter;
    theme.defaultValueFormatter =
        defaultValueFormatter ?? theme.defaultValueFormatter;
    theme.inputFormatter = inputFormatter ?? theme.inputFormatter;
    theme.successPrefixColor = successPrefixColor ?? theme.successPrefixColor;
    theme.errorPrefixColor = errorPrefixColor ?? theme.errorPrefixColor;
    theme.validatorColorMessage =
        validatorColorMessage ?? theme.validatorColorMessage;
    theme.askPrefixColor = askPrefixColor ?? theme.askPrefixColor;
    theme.defaultValueColorMessage =
        defaultValueColorMessage ?? theme.defaultValueColorMessage;
    theme.inputColor = inputColor ?? theme.inputColor;

    return theme;
  }
}
