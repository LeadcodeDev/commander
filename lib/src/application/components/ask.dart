import 'dart:async';
import 'dart:io';

import 'package:commander_ui/src/application/terminals/terminal.dart';
import 'package:commander_ui/src/application/themes/default_ask_theme.dart';
import 'package:commander_ui/src/application/utils/terminal_tools.dart';
import 'package:commander_ui/src/application/validators/chain_validator.dart';
import 'package:commander_ui/src/domains/models/chain_validator.dart';
import 'package:commander_ui/src/domains/models/component.dart';
import 'package:commander_ui/src/domains/themes/ask_theme.dart';
import 'package:mansion/mansion.dart';

/// A component that asks the user for input.
final class Ask<T> with TerminalTools implements Component<Future<T>> {
  final _completer = Completer<T>();

  final Terminal _terminal;
  final AskTheme _theme;

  final String _message;
  final String? _defaultValue;
  final bool _hidden;
  final Function(TextualChainValidator)? _validate;

  /// Creates a new instance of [Ask].
  bool get _hasDefault => _defaultValue != null && '$_defaultValue'.isNotEmpty;

  String get _resolvedDefaultValue => _hasDefault ? '$_defaultValue' : '';

  List<Sequence> get _baseDefaultSequence {
    return [
      ..._theme.defaultValueColorMessage,
      Print(' ($_defaultValue)'),
      SetStyles.reset,
    ];
  }

  Ask(this._terminal,
      {required String message,
      String? defaultValue,
      bool hidden = false,
      Function(TextualChainValidator)? validate,
      AskTheme? theme})
      : _message = message,
        _defaultValue = defaultValue,
        _hidden = hidden,
        _validate = validate,
        _theme = theme ?? DefaultAskTheme();

  @override
  Future<T> handle() {
    createSpace(_terminal, 1);
    saveCursorPosition();

    _defaultRendering();
    _waitResponse();

    return _completer.future;
  }

  void _waitResponse() {
    final input = _hidden ? readLineHiddenSync() : readLineSync();
    final response =
        input == null || input.isEmpty ? _resolvedDefaultValue : input;

    if (_validate != null) {
      final validator = ValidatorChain();
      _validate!(validator);

      final result = validator.execute(response);
      if (result case String error) {
        _onError(error);

        return;
      }
    }

    _onSuccess(response);
  }

  void _defaultRendering() {
    final buffer = StringBuffer();

    List<Sequence> askSequence = [
      ..._theme.askPrefixColor,
      Print('${_theme.askPrefix} '),
      SetStyles.reset,
    ];

    buffer.writeAnsiAll([
      ...askSequence,
      Print(_message),
      if (_hasDefault) ..._baseDefaultSequence,
      const CursorPosition.moveRight(1),
      ..._theme.inputColor,
    ]);

    stdout.write(buffer.toString());
  }

  void _onError(String error) {
    final buffer = StringBuffer();

    List<Sequence> errorSequence = [
      ..._theme.errorPrefixColor,
      Print('${_theme.errorSuffix} '),
      SetStyles.reset,
    ];

    buffer.writeAnsiAll([
      CursorPosition.restore,
      Clear.afterCursor,
      ...errorSequence,
      Print(_message),
      if (_hasDefault) ..._baseDefaultSequence,
      const CursorPosition.moveRight(1),
    ]);

    buffer.writeAnsiAll([
      AsciiControl.lineFeed,
      ..._theme.validatorColorMessage,
      Print(error),
      SetStyles.reset,
    ]);

    stdout.write(buffer.toString());

    stdout.writeAnsiAll([
      const CursorPosition.moveUp(1),
      CursorPosition.moveToColumn(_message.length + 2),
      const CursorPosition.moveRight(2),
      ..._theme.inputColor,
    ]);

    _waitResponse();
  }

  void _onSuccess(String response) {
    final buffer = StringBuffer();

    List<Sequence> successSequence = [
      ..._theme.successPrefixColor,
      Print('${_theme.successSuffix} '),
      SetStyles.reset,
    ];

    buffer.writeAnsiAll([
      CursorPosition.restore,
      Clear.afterCursor,
      ...successSequence,
      Print(_message),
      Print(' '),
      ..._theme.inputColor,
      Print(_hidden ? '******' : response),
      SetStyles.reset,
      AsciiControl.lineFeed,
    ]);

    stdout.write(buffer.toString());

    _completer.complete(response as T);
  }
}
