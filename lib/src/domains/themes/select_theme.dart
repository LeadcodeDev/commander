import 'package:commander_ui/commander_ui.dart';

abstract interface class SelectTheme {
  String get askPrefix;

  String get successPrefix;

  String get selectedIcon;

  String get unselectedIcon;

  String get helpMessage;

  List<Sequence> get selectedIconColor;

  List<Sequence> get unselectedIconColor;

  List<Sequence> get placeholderColorMessage;

  List<Sequence> get helpColorMessage;

  List<Sequence> get filterColorMessage;

  List<Sequence> get currentLineColor;

  List<Sequence> get selectedLineColor;

  List<Sequence> get defaultLineColor;

  List<Sequence> get successPrefixColor;

  List<Sequence> get askPrefixColor;

  List<Sequence> get resultMessageColor;
}
