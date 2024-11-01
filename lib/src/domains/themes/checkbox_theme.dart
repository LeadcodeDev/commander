import 'package:commander_ui/commander_ui.dart';

abstract interface class CheckboxTheme {
  /// The prefix that will be displayed before the question.
  String get askPrefix;

  /// The prefix that will be displayed after confirm a selects.
  String get successPrefix;

  /// The prefix that will be displayed after to help user.
  String get helpMessage;

  /// The icon that will be displayed when the option is selected.
  String get selectedIcon;

  /// The icon that will be displayed when the option is unselected.
  String get unselectedIcon;

  /// A function that will be used to format the placeholder.
  String Function(String? value) get placeholderFormatter;

  /// The color of the current line.
  List<Sequence> get currentLineColor;

  /// The color of the selected line.
  List<Sequence> get selectedLineColor;

  /// The color of the default line.
  List<Sequence> get defaultLineColor;

  /// The color of the bottom help message.
  List<Sequence> get helpMessageColor;

  /// The color of the ask prefix.
  List<Sequence> get askPrefixColor;

  /// The color of the success prefix.
  List<Sequence> get successPrefixColor;

  /// The color of the checkbox results.
  List<Sequence> get resultMessageColor;

  /// The color of the placeholder.
  List<Sequence> get placeholderColorMessage;
}
