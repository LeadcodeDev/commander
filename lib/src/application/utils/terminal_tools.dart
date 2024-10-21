import 'dart:convert';
import 'dart:io';

import 'package:commander_ui/src/application/errors/no_terminal_attached_error.dart';
import 'package:commander_ui/src/application/terminals/terminal.dart';
import 'package:commander_ui/src/io.dart';
import 'package:mansion/mansion.dart';

mixin TerminalTools {
  /// Hide the cursor
  void hideCursor() => stdout.write('\x1B[?25l');

  /// Show the cursor
  void showCursor() => stdout.write('\x1B[?25h');

  /// Clear the entire screen
  void clearScreen() => stdout.write('\x1B[2J');

  /// Move the cursor up by a given number of lines
  void moveCursorUp(int count) => stdout.write('\x1b[${count}A');

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

  void createSpace(Terminal terminal, int linesNeeded) {
    final (x, y) = readCursorPosition(terminal);
    stdout.writeAnsi(const CursorPosition.moveLeft(0));

    final availableLines = stdout.terminalLines - y;

    final int requiredLines = linesNeeded - availableLines;

    if (!requiredLines.isNegative) {
      for (int i = 0; i < linesNeeded; i++) {
        stdout.writeln();
      }

      stdout.writeAnsi(CursorPosition.moveUp(linesNeeded));
    }

    saveCursorPosition();
  }

  String? readLineSync() {
    _ensureTerminalAttached();
    return stdin.readLineSync()?.trim();
  }

  String readLineHiddenSync() {
    _ensureTerminalAttached();
    const lineFeed = 10;
    const carriageReturn = 13;
    const delete = 127;
    final value = <int>[];

    try {
      stdin
        ..echoMode = false
        ..lineMode = false;
      int char;
      do {
        char = stdin.readByteSync();
        if (char != lineFeed && char != carriageReturn) {
          final shouldDelete = char == delete && value.isNotEmpty;
          shouldDelete ? value.removeLast() : value.add(char);
        }
      } while (char != lineFeed && char != carriageReturn);
    } finally {
      stdin
        ..lineMode = true
        ..echoMode = true;
    }
    stdout.writeln();
    return utf8.decode(value);
  }

  void _ensureTerminalAttached() {
    if (!stdout.hasTerminal) throw NoTerminalAttachedError();
  }

  KeyStroke readKey(Terminal terminal) {
    _ensureTerminalAttached();
    terminal.enableRawMode();
    final key = _readKey();
    terminal.disableRawMode();

    if (key.controlChar == ControlCharacter.ctrlC) exit(130);
    return key;
  }

  (int, int) readCursorPosition(Terminal terminal) {
    _ensureTerminalAttached();

    terminal.enableRawMode();
    final position = terminal.getCursorPosition();
    terminal.disableRawMode();

    return position;
  }

  KeyStroke _readKey() {
    KeyStroke keyStroke;
    int charCode;
    var codeUnit = 0;

    while (codeUnit <= 0) {
      codeUnit = stdin.readByteSync();
    }

    if (codeUnit >= 0x01 && codeUnit <= 0x1a) {
      // Ctrl+A thru Ctrl+Z are mapped to the 1st-26th entries in the
      // enum, so it's easy to convert them across
      keyStroke = KeyStroke.control(ControlCharacter.values[codeUnit]);
    } else if (codeUnit == 0x1b) {
      // escape sequence (e.g. \x1b[A for up arrow)
      keyStroke = KeyStroke.control(ControlCharacter.escape);

      final escapeSequence = <String>[];

      charCode = stdin.readByteSync();
      if (charCode == -1) return keyStroke;

      escapeSequence.add(String.fromCharCode(charCode));

      if (charCode == 127) {
        keyStroke = KeyStroke.control(ControlCharacter.wordBackspace);
      } else if (escapeSequence[0] == '[') {
        charCode = stdin.readByteSync();
        if (charCode == -1) return keyStroke;

        escapeSequence.add(String.fromCharCode(charCode));

        switch (escapeSequence[1]) {
          case 'A':
            keyStroke = KeyStroke.control(ControlCharacter.arrowUp);
          case 'B':
            keyStroke = KeyStroke.control(ControlCharacter.arrowDown);
          case 'C':
            keyStroke = KeyStroke.control(ControlCharacter.arrowRight);
          case 'D':
            keyStroke = KeyStroke.control(ControlCharacter.arrowLeft);
          case 'H':
            keyStroke = KeyStroke.control(ControlCharacter.home);
          case 'F':
            keyStroke = KeyStroke.control(ControlCharacter.end);
          default:
            if (escapeSequence[1].codeUnits[0] > '0'.codeUnits[0] &&
                escapeSequence[1].codeUnits[0] < '9'.codeUnits[0]) {
              charCode = stdin.readByteSync();
              if (charCode == -1) return keyStroke;

              escapeSequence.add(String.fromCharCode(charCode));
              if (escapeSequence[2] != '~') {
                keyStroke = KeyStroke.control(
                  ControlCharacter.unknown,
                );
              } else {
                switch (escapeSequence[1]) {
                  case '1':
                    keyStroke = KeyStroke.control(
                      ControlCharacter.home,
                    );
                  case '3':
                    keyStroke = KeyStroke.control(
                      ControlCharacter.delete,
                    );
                  case '4':
                    keyStroke = KeyStroke.control(
                      ControlCharacter.end,
                    );
                  case '5':
                    keyStroke = KeyStroke.control(
                      ControlCharacter.pageUp,
                    );
                  case '6':
                    keyStroke = KeyStroke.control(
                      ControlCharacter.pageDown,
                    );
                  case '7':
                    keyStroke = KeyStroke.control(
                      ControlCharacter.home,
                    );
                  case '8':
                    keyStroke = KeyStroke.control(
                      ControlCharacter.end,
                    );
                  default:
                    keyStroke = KeyStroke.control(
                      ControlCharacter.unknown,
                    );
                }
              }
            } else {
              keyStroke = KeyStroke.control(ControlCharacter.unknown);
            }
        }
      } else if (escapeSequence[0] == 'O') {
        charCode = stdin.readByteSync();
        if (charCode == -1) return keyStroke;
        escapeSequence.add(String.fromCharCode(charCode));
        assert(
        escapeSequence.length == 2,
        'escape sequence consist of 2 characters',
        );
        switch (escapeSequence[1]) {
          case 'H':
            keyStroke = KeyStroke.control(ControlCharacter.home);
          case 'F':
            keyStroke = KeyStroke.control(ControlCharacter.end);
          case 'P':
            keyStroke = KeyStroke.control(ControlCharacter.F1);
          case 'Q':
            keyStroke = KeyStroke.control(ControlCharacter.F2);
          case 'R':
            keyStroke = KeyStroke.control(ControlCharacter.F3);
          case 'S':
            keyStroke = KeyStroke.control(ControlCharacter.F4);
          default:
        }
      } else if (escapeSequence[0] == 'b') {
        keyStroke = KeyStroke.control(ControlCharacter.wordLeft);
      } else if (escapeSequence[0] == 'f') {
        keyStroke = KeyStroke.control(ControlCharacter.wordRight);
      } else {
        keyStroke = KeyStroke.control(ControlCharacter.unknown);
      }
    } else if (codeUnit == 0x7f) {
      keyStroke = KeyStroke.control(ControlCharacter.backspace);
    } else if (codeUnit == 0x00 || (codeUnit >= 0x1c && codeUnit <= 0x1f)) {
      keyStroke = KeyStroke.control(ControlCharacter.unknown);
    } else {
      // assume other characters are printable
      keyStroke = KeyStroke.char(String.fromCharCode(codeUnit));
    }
    return keyStroke;
  }
}
