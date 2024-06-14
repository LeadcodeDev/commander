import 'dart:async';
import 'dart:io';

import 'package:commander_ui/src/commons/ansi_character.dart';
import 'package:commander_ui/src/commons/cli.dart';
import 'package:commander_ui/src/commons/color.dart';
import 'package:commander_ui/src/component.dart';
import 'package:commander_ui/src/key_down_event_listener.dart';
import 'package:commander_ui/src/result.dart';

/// A class that represents a switch component.
/// This component handles user input as a boolean value.
class Switch with Tools implements Component<Result<bool>> {
  final String answer;
  final bool? defaultValue;
  late bool value;
  String temporaryValue = '';
  String? errorMessage;
  late final String exitMessage;

  final List<String> allowedYesValues = ['yes', 'y'];
  final List<String> allowedNoValues = ['no', 'n'];

  final _completer = Completer<Result<bool>>();

  /// Creates a new instance of [Switch].
  ///
  /// * The [answer] parameter is the question that the user is asked.
  /// * The [defaultValue] parameter is the default value of the switch.
  /// * The [exitMessage] parameter is an optional message that is displayed when the user exits the input.
  Switch({
    required this.answer,
    this.defaultValue,
    String? exitMessage,
    List<String>? allowedYesValues,
    List<String>? allowedNoValues,
  }) {
    this.exitMessage = exitMessage ?? '${AsciiColors.red('✘')} Operation canceled by user';
    if (defaultValue != null) {
      value = defaultValue!;
    }
    this.allowedNoValues.addAll(allowedNoValues ?? []);
    this.allowedYesValues.addAll(allowedYesValues ?? []);
  }

  /// Handles the switch component and returns a [Future] that completes with the result of the switch.
  @override
  Future<Result<bool>> handle() async {
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
    // TODO add case when value isn't selected and default value was not provide
    if (![...allowedYesValues, ...allowedNoValues].contains(temporaryValue.trim())) {
      errorMessage = 'error';
      render();

      return;
    }

    saveCursorPosition();
    clearFromCursorToEnd();
    restoreCursorPosition();
    showInput();
    showCursor();

    dispose();

    if (allowedYesValues.contains(temporaryValue.trim())) {
      value = true;
    }

    if (allowedNoValues.contains(temporaryValue.trim())) {
      value = false;
    }

    final computedValue = value
        ? AsciiColors.lightGreen(allowedYesValues.first)
        : AsciiColors.lightRed(allowedNoValues.first);

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
      if (key == '\x7F' && temporaryValue.isNotEmpty) {
        temporaryValue = temporaryValue.substring(
            0, temporaryValue.length - 1); // Supprimer le dernier caractère
      } else if (key != '\x7F') {
        temporaryValue += key;
      }

      render();
    }
  }

  void render() async {
    final buffer = StringBuffer();

    buffer.writeln(
        '${AsciiColors.yellow('?')} $answer ${AsciiColors.dim('(${allowedYesValues.first}/${allowedNoValues.first})')} $temporaryValue');
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
