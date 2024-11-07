import 'dart:async';
import 'dart:io';

import 'package:commander_ui/src/application/terminals/terminal.dart';
import 'package:commander_ui/src/application/themes/default_number_theme.dart';
import 'package:commander_ui/src/application/utils/terminal_tools.dart';
import 'package:commander_ui/src/application/validators/chain_validator.dart';
import 'package:commander_ui/src/domains/models/chain_validator.dart';
import 'package:commander_ui/src/domains/models/component.dart';
import 'package:commander_ui/src/domains/themes/number_theme.dart';
import 'package:commander_ui/src/io.dart';
import 'package:mansion/mansion.dart';

/// A component that asks the user for input.
final class Number<T extends num>
    with TerminalTools
    implements Component<Future<T>> {
  final _completer = Completer<T>();

  final Terminal _terminal;
  final NumberTheme _theme;

  final String _message;
  double _value = 0.0;
  final double _interval;
  final Function(NumberChainValidator)? _validate;
  final String? Function(T?) _onDisplay;

  String? normalizeValue(double value) {
    return _onDisplay(switch (T) {
      int => value.toInt() as T,
      _ => value as T,
    });
  }

  Number(this._terminal,
      {required String message,
      T? defaultValue,
      T? interval,
      Function(NumberChainValidator)? validate,
      String? Function(T?)? onDisplay,
      NumberTheme? theme})
      : _message = message,
        _value = double.parse(defaultValue != null ? '$defaultValue' : '0.0'),
        _interval = double.parse(interval != null ? '$interval' : '1.0'),
        _validate = validate,
        _onDisplay = (onDisplay ?? (value) => value.toString()),
        _theme = theme ?? DefaultNumberTheme();

  @override
  Future<T> handle() {
    createSpace(_terminal, 1);
    stdout.writeAnsiAll([CursorPosition.save, CursorVisibility.hide]);

    _render();
    _waitResponse();

    return _completer.future;
  }

  void _waitResponse() {
    final key = readKey(_terminal);

    if (key.controlChar == ControlCharacter.arrowUp || key.char == 'k') {
      _value += _interval;
    } else if (key.controlChar == ControlCharacter.arrowDown ||
        key.char == 'j') {
      _value -= _interval;
    } else if ([ControlCharacter.ctrlJ, ControlCharacter.ctrlM]
        .contains(key.controlChar)) {
      if (_validate != null) {
        final validator = ValidatorChain();
        _validate!(validator);

        final result = validator.execute(_value);
        if (result case String error) {
          _onError(error);

          return;
        }
      }

      return _onSuccess();
    }

    _render();
    _waitResponse();
  }

  void _render() {
    final buffer = StringBuffer();

    List<Sequence> askSequence = [
      ..._theme.askPrefixColor,
      Print('${_theme.askPrefix} '),
      SetStyles.reset,
    ];

    buffer.writeAnsiAll([
      CursorPosition.restore,
      Clear.afterCursor,
      ...askSequence,
      Print(_message),
      const CursorPosition.moveRight(1),
      ..._theme.inputColor,
      Print('${normalizeValue(_value)}'),
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
      Print('${normalizeValue(_value)}'),
    ]);

    _waitResponse();
  }

  void _onSuccess() {
    final buffer = StringBuffer();

    List<Sequence> successSequence = [
      ..._theme.successPrefixColor,
      Print('${_theme.successSuffix} '),
      SetStyles.reset,
    ];

    buffer.writeAnsiAll([
      CursorPosition.restore,
      Clear.untilEndOfLine,
      Clear.afterCursor,
      ...successSequence,
      Print(_message),
      Print(' '),
      ..._theme.inputColor,
      Print('${normalizeValue(_value)}'),
      SetStyles.reset,
      AsciiControl.lineFeed,
      CursorVisibility.show,
    ]);

    stdout.write(buffer.toString());

    return switch (T) {
      int => _completer.complete(_value.toInt() as T),
      _ => _completer.complete(_value as T),
    };
  }
}
