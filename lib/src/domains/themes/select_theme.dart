import 'package:commander_ui/commander_ui.dart';

abstract interface class SelectTheme {
  /// The prefix that will be displayed before the question.
  String get askPrefix;

  /// The prefix that will be displayed after confirm a selects.
  String get successPrefix;

  /// The icon that will be displayed before option.
  String get selectedIcon;

  /// The icon that will be displayed before option.
  String get unselectedIcon;

  /// The prefix that will be displayed after to help user.
  String get helpMessage;

  /// A function that will be used to format the selected icon.
  List<Sequence> get selectedIconColor;

  /// A function that will be used to format the unselected icon.
  List<Sequence> get unselectedIconColor;

  /// A function that will be used to format the placeholder.
  List<Sequence> get placeholderColorMessage;

  /// The color of the help message.
  List<Sequence> get helpColorMessage;

  /// The color of the filter message.
  List<Sequence> get filterColorMessage;

  /// The color of the line color
  List<Sequence> get currentLineColor;

  /// The color of the selected line.
  List<Sequence> get selectedLineColor;

  /// The color of the default line.
  List<Sequence> get defaultLineColor;

  /// The color of the success prefix.
  List<Sequence> get successPrefixColor;

  /// The color of the ask prefix.
  List<Sequence> get askPrefixColor;

  /// The color of the select results.
  List<Sequence> get resultMessageColor;
}
