import 'dart:io';

import 'package:commander/src/application/stdin_buffer.dart';

mixin Tools {
  static final a = '';

  void hideCursor() => stdout.write('\x1B[?25l');

  void showCursor() => stdout.write('\x1B[?25h');

  void clearScreen() => stdout.write('\x1B[2J');

  void moveCursorUp({int count = 1}) => stdout.write('\x1b[${count}A');

  void moveCursorDown({int count = 1}) => stdout.write('\x1B[${count}B');

  void saveCursorPosition() => stdout.write('\x1B[s');

  void restoreCursorPosition() => stdout.write('\x1B[u');

  void clearFromCursorToEnd() => stdout.write('\x1B[J');

  void moveToStart() => stdout.write('\x1B[0;0H');

  void hideInput() {
    if (stdin.hasTerminal) {
      stdin.echoMode = false;
      stdin.lineMode = false;
    }
  }

  void showInput() {
    if (stdin.hasTerminal) {
      stdin.echoMode = true;
      stdin.lineMode = true;
    }
  }

  /// Get the current cursor position
  /// return (currentLine, currentColumn)
  Future<(int, int)> getCurrentCursorPosition() async {
    stdout.write('\x1B[6n');

    List<int> response = await StdinBuffer.stream.first;
    String responseStr = String.fromCharCodes(response);

    RegExp cursorPosRegex = RegExp(r'\[(\d+);(\d+)R');
    Match? match = cursorPosRegex.firstMatch(responseStr);

    if (match == null) {
      throw Exception('Could not parse cursor position');
    }

    return (
    int.parse(match.group(1)!),
    int.parse(match.group(2)!)
    );
  }

  Future<int> getAvailableLinesBelowCursor() async {
    final (currentLine, _) = await getCurrentCursorPosition();
    return stdout.terminalLines - currentLine;
  }
}
