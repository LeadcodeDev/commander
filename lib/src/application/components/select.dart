import 'dart:async';
import 'dart:io';

import 'package:commander_ui/src/application/terminals/terminal.dart';
import 'package:commander_ui/src/application/utils/terminal_tools.dart';
import 'package:commander_ui/src/domains/models/component.dart';
import 'package:commander_ui/src/io.dart';
import 'package:mansion/mansion.dart';

final class Select<T> with TerminalTools implements Component<T> {
  final _completer = Completer<T>();

  final Terminal _terminal;
  late int _displayCount;

  int _currentIndex = 0;
  T? _selectedOption;
  String _filter = '';

  late final String _message;
  late final T? _defaultValue;
  late final String _placeholder;
  late final List<T> _options;
  final List<T> _filteredOptions = [];

  Select(this._terminal,
      {required String message, required List<T> options, int displayCount = 5, T? defaultValue, String placeholder = ''}) {
    _message = message;
    _options = options;
    _displayCount = displayCount;
    _defaultValue = defaultValue;
    _placeholder = placeholder;

    if (_defaultValue case T value) {
      _currentIndex = _options.indexOf(value);
    }
  }

  @override
  Future<T> handle() async {
    saveCursorPosition();
    hideCursor();

    _render(isInitialRender: true);

    while (_selectedOption == null) {
      final key = readKey(_terminal);

      if (key.controlChar == ControlCharacter.arrowUp || key.char == 'k') {
        if (_currentIndex != 0) {
          _currentIndex = _currentIndex - 1;
        }
      } else if (key.controlChar == ControlCharacter.arrowDown || key.char == 'j') {
        if (_currentIndex < _options.length - 1) {
          _currentIndex = _currentIndex + 1;
        }
      } else if ([ControlCharacter.ctrlJ, ControlCharacter.ctrlM].contains(key.controlChar)) {
        _selectedOption = _filteredOptions[_currentIndex];
        _onSubmit();
        break;
      } else {
        if (RegExp(r'^[\p{L}\p{N}\p{P}\s\x7F]*$', unicode: true).hasMatch(key.char)) {
          _currentIndex = 0;

          if (key.controlChar == ControlCharacter.backspace && _filter.isNotEmpty) {
            _filter = _filter.substring(0, _filter.length - 1);
          } else if (key.controlChar != ControlCharacter.backspace) {
            _filter = _filter + key.char;
          }

          _render();
        }
      }

      _render();
    }

    return _completer.future;
  }

  List<T> _filterOptions() {
    return _options.where((item) {
      // final value = onDisplay?.call(item) ?? item.toString();
      return _options.isNotEmpty ? item.toString().toLowerCase().contains(_filter.toLowerCase()) : true;
    }).toList();
  }

  void _render({bool isInitialRender = false}) {
    restoreCursorPosition();
    clearFromCursorToEnd();

    final buffer = StringBuffer();

    buffer.writeAnsiAll([
      SetStyles(Style.foreground(Color.yellow)),
      Print('?'),
      SetStyles.reset,
      Print(' $_message : '),
      SetStyles(Style.foreground(Color.brightBlack)),
      Print(_filter.isEmpty ? _placeholder : _filter),
      SetStyles.reset,
      AsciiControl.lineFeed,
    ]);

    _filteredOptions.clear();
    _filteredOptions.addAll(_filterOptions());

    for (final choice in _filteredOptions) {
      final isCurrent = _filteredOptions.indexOf(choice) == _currentIndex;
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

    if (isInitialRender) {
      createSpace(_terminal, buffer.toString().split('\x0A').length);
    }

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
    _completer.complete(_selectedOption);
  }
}
