import 'dart:async';
import 'dart:io';

import 'package:commander_ui/src/application/stdin_buffer.dart';
import 'package:commander_ui/src/commons/ansi_character.dart';
import 'package:commander_ui/src/commons/cli.dart';
import 'package:commander_ui/src/commons/color.dart';
import 'package:commander_ui/src/component.dart';
import 'package:commander_ui/src/key_down_event_listener.dart';
import 'package:commander_ui/src/result.dart';

/// A class that represents an input component.
/// This component handles user input and provides validation and error handling.
class Input with Tools implements Component<Result<String>> {
  final String answer;
  final String? placeholder;
  final bool secure;
  late final String exitMessage;
  String value = '';
  String? errorMessage;
  late Result Function(String value) validate;

  final _completer = Completer<Result<String>>();

  /// * The [answer] parameter is the answer that the user provides.
  /// * The [placeholder] parameter is an optional placeholder for the input.
  /// * The [secure] parameter determines whether the input should be hidden.
  /// * The [validate] parameter is a function that validates the input.
  /// * The [exitMessage] parameter is an optional message that is displayed when the user exits the input.
  Input({
    required this.answer,
    this.placeholder,
    this.secure = false,
    Result Function(String value)? validate,
    String? exitMessage,
  }) {
    StdinBuffer.initialize();

    this.exitMessage = exitMessage ?? '${AsciiColors.red('✘')} Operation canceled by user';
    this.validate = validate ?? (value) => Ok(null);
  }

  /// Handles the input component and returns a [Future] that completes with the result of the input.
  @override
  Future<Result<String>> handle() async {
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
    final result = validate(value);
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

    final computedValue =
        secure ? AsciiColors.dim(generateValue()) : AsciiColors.lightGreen(generateValue());

    stdout.writeln('${AsciiColors.green('✔')} $answer · $computedValue');

    saveCursorPosition();
    _completer.complete(Ok(value));
  }

  void onExit(void Function() dispose) {
    dispose();

    restoreCursorPosition();
    clearFromCursorToEnd();
    showInput();

    stdout.writeln(exitMessage);
    exit(1);
  }

  void onTap(String key, void Function() dispose) {
    errorMessage = null;
    if (RegExp(r'^[\p{L}\p{N}\p{P}\s\x7F]*$', unicode: true).hasMatch(key)) {
      if (key == '\x7F' && value.isNotEmpty) {
        value = value.substring(0, value.length - 1); // Supprimer le dernier caractère
      } else if (key != '\x7F') {
        value = value + key; // Ajouter le caractère tapé
      }

      render();
    }
  }

  String generateValue() => secure ? value.replaceAll(RegExp(r'.'), '*') : value;

  void render() async {
    final buffer = StringBuffer();

    buffer.writeln('${AsciiColors.yellow('?')} $answer : ${AsciiColors.dim(generateValue())}');
    if (errorMessage != null) {
      buffer.writeln(AsciiColors.lightRed(errorMessage!));
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
