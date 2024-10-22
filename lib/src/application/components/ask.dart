import 'dart:async';
import 'dart:io';

import 'package:commander_ui/src/application/terminals/terminal.dart';
import 'package:commander_ui/src/application/utils/terminal_tools.dart';
import 'package:commander_ui/src/domains/models/component.dart';
import 'package:mansion/mansion.dart';

/// A component that asks the user for input.
final class Ask with TerminalTools implements Component<Future<String?>> {
  final _completer = Completer<String?>();

  final Terminal _terminal;

  late final String _message;
  late final String? _defaultValue;
  late final bool _hidden;
  late final String? Function(String value)? _validate;

  /// Creates a new instance of [Ask].
  bool get _hasDefault => _defaultValue != null && '$_defaultValue'.isNotEmpty;

  String get _resolvedDefaultValue => _hasDefault ? '$_defaultValue' : '';

  List<Sequence> get _baseDefaultSequence {
    return [
      SetStyles(Style.foreground(Color.brightBlack)),
      Print(' ($_defaultValue)'),
      SetStyles.reset,
      Print(' :'),
    ];
  }

  Ask(this._terminal,
      {required String message,
      String? defaultValue,
      bool hidden = false,
      String? Function(String value)? validate}) {
    _message = message;
    _defaultValue = defaultValue;
    _hidden = hidden;
    _validate = validate;
  }

  @override
  Future<String?> handle() {
    saveCursorPosition();

    createSpace(_terminal, 1);

    _defaultRendering();
    _waitResponse();

    return _completer.future;
  }

  void _waitResponse() {
    final input = _hidden ? readLineHiddenSync() : readLineSync();
    final response =
        input == null || input.isEmpty ? _resolvedDefaultValue : input;

    if (_validate != null) {
      final result = _validate!(response);
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
      SetStyles(Style.foreground(Color.yellow)),
      Print('? '),
      SetStyles.reset,
    ];

    buffer.writeAnsiAll([
      ...askSequence,
      Print(_message),
      if (_hasDefault) ..._baseDefaultSequence,
      const CursorPosition.moveRight(1),
      SetStyles(Style.foreground(Color.brightBlack)),
    ]);

    stdout.write(buffer.toString());
  }

  void _onError(String error) {
    final buffer = StringBuffer();

    List<Sequence> errorSequence = [
      SetStyles(Style.foreground(Color.brightRed)),
      Print('✘ '),
      SetStyles.reset,
    ];

    buffer.writeAnsiAll([
      ...errorSequence,
      Print(_message),
      if (_hasDefault) ..._baseDefaultSequence,
      const CursorPosition.moveRight(1),
    ]);

    buffer.writeAnsiAll([
      AsciiControl.lineFeed,
      SetStyles(Style.foreground(Color.brightRed)),
      Print(error),
      SetStyles.reset,
    ]);

    resetCursor();

    buffer.writeAnsi(
      SetStyles(Style.foreground(Color.brightBlack)),
    );
    stdout.write(buffer.toString());

    stdout.writeAnsiAll([
      const CursorPosition.moveUp(1),
      const CursorPosition.moveRight(2),
    ]);

    _waitResponse();
  }

  void _onSuccess(String response) {
    final buffer = StringBuffer();

    List<Sequence> successSequence = [
      SetStyles.reset,
      SetStyles(Style.foreground(Color.green)),
      Print('✔ '),
      SetStyles.reset,
    ];

    buffer.writeAnsiAll([
      ...successSequence,
      Print(_message),
      Print(' '),
      SetStyles(Style.foreground(Color.brightBlack)),
      Print(_hidden ? '******' : response),
      SetStyles.reset,
      AsciiControl.lineFeed,
    ]);

    resetCursor();
    stdout.write(buffer.toString());

    _completer.complete(response);
  }

  void resetCursor() {
    restoreCursorPosition();
    clearFromCursorToEnd();
  }
}
