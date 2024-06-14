import 'dart:async';
import 'dart:io';

import 'package:commander_ui/src/commons/ansi_character.dart';
import 'package:commander_ui/src/commons/cli.dart';
import 'package:commander_ui/src/commons/color.dart';
import 'package:commander_ui/src/component.dart';
import 'package:commander_ui/src/key_down_event_listener.dart';
import 'package:commander_ui/src/result.dart';

class Input with Tools implements Component<Result<String>> {
  final String answer;
  final String? placeholder;
  late final String exitMessage;
  String value = '';
  String? errorMessage;
  late Result Function(String value) validate;

  final _completer = Completer<Result<String>>();

  Input({
    required this.answer,
    this.placeholder,
    Result Function(String value)? validate,
    String? exitMessage,
  }) {
    this.exitMessage = exitMessage ?? '${AsciiColors.red('✘')} Operation canceled by user';
    this.validate = validate ?? (value) => Ok(null);
  }

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

    restoreCursorPosition();
    clearFromCursorToEnd();
    showInput();

    dispose();

    stdout.writeln('${AsciiColors.green('✔')} $answer · ${AsciiColors.lightGreen(value)}');
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

  void render() async {
    final buffer = StringBuffer();

    buffer.writeln('${AsciiColors.yellow('?')} $answer : ${AsciiColors.dim(value)}');
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
