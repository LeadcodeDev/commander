import 'dart:async';
import 'dart:io';

import 'package:commander_ui/src/application/terminals/terminal.dart';
import 'package:commander_ui/src/application/utils/terminal_tools.dart';
import 'package:commander_ui/src/io.dart';
import 'package:mansion/mansion.dart';

final class Select<T> with TerminalTools {
  final _completer = Completer<T>();

  final Terminal _terminal;
  late int _displayCount;

  int _currentIndex = 0;
  T? _selectedOption;

  late final String _message;
  late final T? _defaultValue;
  late final List<T> _options;

  Select(this._terminal,
      {required String message, required List<T> options, int displayCount = 5, T? defaultValue}) {
    _message = message;
    _options = options;
    _displayCount = displayCount;
    _defaultValue = defaultValue;

    if (_defaultValue case T value) {
      _currentIndex = _options.indexOf(value);
    }
  }

  Future<T> handle() async {
    saveCursorPosition();
    hideCursor();

    _render();

    while (_selectedOption == null) {
      final key = readKey(_terminal);

      if (key.controlChar == ControlCharacter.arrowUp || key.char == 'k') {
        if (_currentIndex != 0) {
          _currentIndex = _currentIndex - 1;
        }
      }

      if (key.controlChar == ControlCharacter.arrowDown || key.char == 'j') {
        if (_currentIndex < _options.length - 1) {
          _currentIndex = _currentIndex + 1;
        }
      }

      if ([ControlCharacter.ctrlJ, ControlCharacter.ctrlM].contains(key.controlChar)) {
        _selectedOption = _options[_currentIndex];
        _onSubmit();
        break;
      }

      _render();
    }

    return _completer.future;
  }

  void _render() {
    restoreCursorPosition();
    clearFromCursorToEnd();

    showCursor();

    final buffer = StringBuffer();

    buffer.writeAnsiAll([
      SetStyles(Style.foreground(Color.yellow)),
      Print('?'),
      SetStyles.reset,
      Print(' $_message : '),
      SetStyles(Style.foreground(Color.brightBlack)),
      // Print(filter.isEmpty ? placeholder ?? '' : filter),
      SetStyles.reset,
      AsciiControl.lineFeed,
    ]);

    for (final choice in _options) {
      final isCurrent = _options.indexOf(choice) == _currentIndex;
      if (isCurrent) {
        buffer.writeAnsiAll([
          SetStyles(Style.foreground(Color.brightGreen)),
          Print('❯'),
        ]);
      } else {
        buffer.writeAnsi(Print(' '));
      }

      buffer.writeAnsiAll([
        SetStyles.reset,
        Print(' $choice'),
        AsciiControl.lineFeed,
      ]);
    }

    buffer.writeAnsiAll([
      AsciiControl.lineFeed,
      SetStyles(Style.foreground(Color.brightBlack)),
      Print('(Type to filter, press ↑/↓ to navigate, enter to select)'),
      SetStyles.reset,
    ]);

    createSpace(_terminal, buffer.toString().split('\x0A').length);

    stdout.write(buffer.toString());
  }

  void _onSubmit() {
    final buffer = StringBuffer();

    restoreCursorPosition();
    clearFromCursorToEnd();
    showCursor();

    buffer.writeAnsiAll([
      SetStyles(Style.foreground(Color.green)),
      Print('✔'),
      SetStyles.reset,
      Print(' $_message '),
      SetStyles(Style.foreground(Color.brightBlack)),
      Print(_selectedOption as String),
      SetStyles.reset,
      AsciiControl.lineFeed,
    ]);

    stdout.write(buffer.toString());
    _completer.complete(_options.first);
  }
}
