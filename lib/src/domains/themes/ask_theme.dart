import 'package:mansion/mansion.dart';

abstract interface class AskTheme {
    String get askPrefix;
    String get errorSuffix;
    String get successSuffix;

    String Function(String? value) get secureFormatter;
    String Function(String? value) get defaultValueFormatter;
    String? Function(String? value) get inputFormatter;

    List<Sequence> get successPrefixColor;
    List<Sequence> get errorPrefixColor;
    List<Sequence> get validatorColorMessage;
    List<Sequence> get askPrefixColor;
    List<Sequence> get defaultValueColorMessage;
    List<Sequence> get inputColor;
}
