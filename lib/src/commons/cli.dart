import 'dart:io';

import 'package:commander_ui/commander_ui.dart';

mixin Tools {
  /// Hide the cursor
  void hideCursor() => stdout.write('\x1B[?25l');

  /// Show the cursor
  void showCursor() => stdout.write('\x1B[?25h');

  /// Clear the entire screen
  void clearScreen() => stdout.write('\x1B[2J');

  /// Move the cursor up by a given number of lines
  void moveCursorUp({int count = 1}) => stdout.write('\x1b[${count}A');

  /// Move the cursor down by a given number of lines
  void moveCursorDown({int count = 1}) => stdout.write('\x1B[${count}B');

  /// Save the current cursor position
  void saveCursorPosition() => stdout.write('\x1B[s');

  /// Restore the cursor position to the last saved position
  void restoreCursorPosition() => stdout.write('\x1B[u');

  /// Clear the screen from the cursor's current position to the end of the screen
  void clearFromCursorToEnd() => stdout.write('\x1B[J');

  /// Move the cursor to the start of the screen (0,0)
  void moveToStart() => stdout.write('\x1B[0;0H');

  /// Generate a clickable text with a URL for terminals supporting hyperlinks
  String clickable({required String label, required String url}) {
    return '\x1B]8;;$url\x1B\\$label\x1B]8;;\x1B\\';
  }

  /// Move the cursor to a specific position (line, column)
  void moveCursorTo(int line, int column) => stdout.write('\x1B[$line;${column}H');

  /// Clear the entire current line where the cursor is
  void clearCurrentLine() => stdout.write('\x1B[2K');

  /// Clear from the cursor's current position to the start of the line
  void clearLineToStart() => stdout.write('\x1B[1K');

  /// Clear from the cursor's current position to the end of the line
  void clearLineToEnd() => stdout.write('\x1B[K');

  /// Scroll the screen up by a certain number of lines
  void scrollUp({int count = 1}) => stdout.write('\x1B[${count}S');

  /// Scroll the screen down by a certain number of lines
  void scrollDown({int count = 1}) => stdout.write('\x1B[${count}T');

  void hideInput() {
    if (!Platform.isWindows && stdin.hasTerminal) {
      stdin.echoMode = false;
      stdin.lineMode = false;
    }
  }

  void showInput() {
    if (!Platform.isWindows && stdin.hasTerminal) {
      stdin.lineMode = true;
      stdin.echoMode = true;
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

    final line = int.parse(match.group(1)!);
    final column = int.parse(match.group(2)!);

    return (line, column);
  }

  Future<int> getAvailableLinesBelowCursor() async {
    final (currentLine, _) = await getCurrentCursorPosition();
    return stdout.terminalLines - currentLine;
  }
}
