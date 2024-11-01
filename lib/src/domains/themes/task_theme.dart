import 'package:commander_ui/commander_ui.dart';

abstract interface class TaskTheme {
  /// The loading symbols that will be displayed during the loading.
  List<String> get loadingSymbols;

  /// The color of the loading symbols.
  List<Sequence> get loadingSymbolColor;

  /// The prefix that will be displayed when successful.
  String get successPrefix;

  /// The prefix that will be displayed when error.
  String get errorPrefix;

  /// The prefix that will be displayed when error.
  String get warningPrefix;

  /// The color of the success prefix.
  List<Sequence> get successPrefixColor;

  /// The color of the error prefix.
  List<Sequence> get errorPrefixColor;

  /// The color of the warning prefix.
  List<Sequence> get warningPrefixColor;

  /// The color of the default color.
  List<Sequence> get defaultColor;
}
