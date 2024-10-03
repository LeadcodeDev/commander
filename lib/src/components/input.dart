import 'dart:async';
import 'dart:io';

import 'package:commander_ui/src/application/stdin_buffer.dart';
import 'package:commander_ui/src/commons/ansi_character.dart';
import 'package:commander_ui/src/commons/cli.dart';
import 'package:commander_ui/src/component.dart';
import 'package:commander_ui/src/key_down_event_listener.dart';
import 'package:commander_ui/src/result.dart';
import 'package:mansion/mansion.dart';

/// A class that represents an input component.
/// This component handles user input and provides validation and error handling.
class Input with Tools implements Component<String> {
  final String answer;
  final String? placeholder;
  final bool secure;
  final bool hidden;
  late final List<Sequence> exitMessage;
  String value = '';
  String defaultValue;
  String? errorMessage;
  late Result Function(String value) validate;

  final _completer = Completer<String>();

  /// * The [answer] parameter is the answer that the user provides.
  /// * The [placeholder] parameter is an optional placeholder for the input.
  /// * The [secure] parameter determines whether the input should be hidden.
  /// * The [validate] parameter is a function that validates the input.
  /// * The [exitMessage] parameter is an optional message that is displayed when the user exits the input.
  Input({
    required this.answer,
    this.placeholder,
    this.secure = false,
    this.hidden = false,
    this.defaultValue = '',
    Result Function(String value)? validate,
    List<Sequence>? exitMessage,
  }) {
    StdinBuffer.initialize();

    this.exitMessage = exitMessage ??
        [
          SetStyles(Style.foreground(Color.brightRed)),
          Print('✘'),
          SetStyles.reset,
          Print(' Operation canceled by user'),
          AsciiControl.lineFeed
        ];

    this.validate = validate ?? (value) => Ok(null);
  }

  /// Handles the input component and returns a [Future] that completes with the result of the input.
  Future<String> handle() async {
    saveCursorPosition();
    hideCursor();
    hideInput();

    KeyDownEventListener()
      ..match(AnsiCharacter.enter, onSubmit)
      ..catchAll(onTap)
      ..onExit(onExit);

    render();

    return _completer.future;
  }

  void onSubmit(String key, void Function() dispose) {
    final result = validate(value.isEmpty ? defaultValue : value);
    if (result case Err(:final String error)) {
      errorMessage = error;
      render();

      return;
    }

    saveCursorPosition();
    clearFromCursorToEnd();
    restoreCursorPosition();
    showInput();
    showCursor();

    dispose();

    stdout.writeAnsiAll([
      SetStyles(Style.foreground(Color.green)),
      Print('✔'),
      SetStyles.reset,
      Print(' $answer '),
      SetStyles(Style.foreground(Color.brightBlack)),
      Print(defaultValue.isNotEmpty
          ? defaultValue
          : placeholder ?? generateValue()),
      SetStyles.reset,
    ]);

    stdout.writeln();

    saveCursorPosition();
    _completer.complete(value.isEmpty ? defaultValue : value);
  }

  void onExit(void Function() dispose) {
    dispose();

    restoreCursorPosition();
    clearFromCursorToEnd();
    showInput();
    showCursor();

    stdout.writeAnsiAll(exitMessage);
    exit(1);
  }

  void onTap(String key, void Function() dispose) {
    errorMessage = null;
    if (RegExp(r'^[\p{L}\p{N}\p{P}\s\x7F]*$', unicode: true).hasMatch(key)) {
      if (key == '\x7F' && value.isNotEmpty) {
        value = value.substring(0, value.length - 1);
      } else if (key != '\x7F') {
        value = value + key;
      }

      render();
    }
  }

  String generateValue() => secure
      ? value.replaceAll(RegExp(r'.'), '*')
      : !hidden
          ? value
          : '';

  void render() async {
    final buffer = StringBuffer();
    buffer.writeAnsiAll([
      SetStyles(Style.foreground(Color.yellow)),
      Print('?'),
      SetStyles.reset,
      Print(' $answer '),
      SetStyles(Style.foreground(Color.brightBlack)),
      Print(value.isEmpty && errorMessage == null
          ? defaultValue.isNotEmpty
              ? defaultValue
              : placeholder ?? generateValue()
          : generateValue()),
      SetStyles.reset,
    ]);

    if (errorMessage != null) {
      buffer.writeAnsiAll([
        SetStyles(Style.foreground(Color.brightRed)),
        Print(errorMessage!),
        SetStyles.reset,
      ]);
    }

    final availableLines = await getAvailableLinesBelowCursor();
    final linesNeeded = buffer.toString().split('\n').length;

    if (availableLines < linesNeeded) {
      for (int i = 0; i < linesNeeded - availableLines; i++) {
        stdout.writeln();
      }

      moveCursorUp(count: linesNeeded - availableLines);
      saveCursorPosition();
    }

    clearFromCursorToEnd();
    restoreCursorPosition();
    saveCursorPosition();
    stdout.write(buffer.toString());
    restoreCursorPosition();
  }
}
