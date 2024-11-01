import 'package:commander_ui/commander_ui.dart';
import 'package:mansion/mansion.dart';

abstract interface class AskTheme {
    /// The prefix that will be displayed before the question.
    String get askPrefix;

    /// The suffix that will be displayed after a failed validation.
    String get errorSuffix;

    /// The suffix that will be displayed after a successful validation.
    String get successSuffix;

    /// A function that will be used to format the input when it is hidden.
    String Function(String? value) get secureFormatter;

    /// A function that will be used to format the default value.
    String Function(String? value) get defaultValueFormatter;

    /// A function that will be used to format the input.
    String? Function(String? value) get inputFormatter;

    /// The color of the prefix.
    List<Sequence> get askPrefixColor;

    /// The color of the prefix when the validation is successful.
    List<Sequence> get successPrefixColor;

    /// The color of the prefix when the validation fails.
    List<Sequence> get errorPrefixColor;

    /// The color of error messages when `validate` method is provided.
    List<Sequence> get validatorColorMessage;

    /// The color of the default value.
    List<Sequence> get defaultValueColorMessage;

    /// The color of the user text input.
    List<Sequence> get inputColor;
}
