import 'dart:async';
import 'dart:io';

import 'package:commander_ui/src/application/terminals/terminal.dart';
import 'package:commander_ui/src/application/utils/terminal_tools.dart';
import 'package:commander_ui/src/domains/models/component.dart';
import 'package:commander_ui/src/io.dart';
import 'package:mansion/mansion.dart';

/// A component that asks the user to select one or more options.
final class Checkbox<T>
    with TerminalTools
    implements Component<Future<List<T>>> {
  final _completer = Completer<List<T>>();

  final Terminal _terminal;

  int _currentIndex = 0;

  late final String _message;
  late final T? _defaultValue;
  late final String _placeholder;
  late final bool _multiple;
  late final String Function(T)? _onDisplay;
  late final List<T> _options;
  final List<int> _selectedOptions = [];

  bool _keepAlive = true;

  Checkbox(this._terminal,
      {required String message,
      required List<T> options,
      T? defaultValue,
      String placeholder = '',
      bool multiple = false,
      String Function(T)? onDisplay}) {
    _message = message;
    _options = options;
    _defaultValue = defaultValue;
    _placeholder = placeholder;
    _multiple = multiple;
    _onDisplay = onDisplay;

    if (_defaultValue case T value) {
      _currentIndex = _options.indexOf(value);
    }
  }

  @override
  Future<List<T>> handle() async {
    saveCursorPosition();
    hideCursor();

    _render(isInitialRender: true);

    while (_keepAlive) {
      final key = readKey(_terminal);

      if (key.controlChar == ControlCharacter.arrowUp || key.char == 'k') {
        if (_currentIndex != 0) {
          _currentIndex = _currentIndex - 1;
          _render();
        }
      } else if (key.controlChar == ControlCharacter.arrowDown ||
          key.char == 'j') {
        if (_currentIndex < _options.length - 1) {
          _currentIndex = _currentIndex + 1;
          _render();
        }
      } else if (key.char == ' ') {
        _onSelect();
      } else if ([ControlCharacter.ctrlJ, ControlCharacter.ctrlM]
          .contains(key.controlChar)) {
        _onSubmit();
      }
    }

    return _completer.future;
  }

  void _render({bool isInitialRender = false}) {
    restoreCursorPosition();
    clearFromCursorToEnd();

    final buffer = StringBuffer();

    buffer.writeAnsiAll([
      SetStyles(Style.foreground(Color.yellow)),
      Print('?'),
      SetStyles.reset,
      Print(' $_message'),
      if (_placeholder.isNotEmpty) ...[
        Print(' : '),
        SetStyles(Style.foreground(Color.brightBlack)),
        Print('($_placeholder)'),
        SetStyles.reset,
      ],
      AsciiControl.lineFeed,
    ]);

    for (final choice in _options) {
      final index = _options.indexOf(choice);
      final isSelected = _selectedOptions.contains(index);

      buffer.writeAnsiAll([
        if (_currentIndex == index) SetStyles(Style.foreground(Color.white)),
        if (isSelected)
          SetStyles(Style.foreground(Color.white))
        else
          SetStyles(Style.foreground(Color.brightBlack)),
        Print(isSelected || _currentIndex == index ? '◉' : '◯'),
        if (_currentIndex == index) SetStyles.reset,
      ]);

      if (_currentIndex == index) {
        buffer.writeAnsi(SetStyles(Style.foreground(Color.white)));
      } else {
        buffer.writeAnsi(SetStyles(Style.foreground(Color.reset)));
      }

      buffer.writeAnsiAll([
        Print(' $choice'),
        if (_currentIndex == index) SetStyles.reset,
        AsciiControl.lineFeed,
      ]);
    }

    buffer.writeAnsiAll([
      AsciiControl.lineFeed,
      SetStyles(Style.foreground(Color.brightBlack)),
      Print(
          '(Type to filter, press ↑/↓ to navigate, space to select, enter to confirm)'),
      SetStyles.reset,
    ]);

    if (isInitialRender) {
      createSpace(_terminal, buffer.toString().split('\x0A').length);
    }

    stdout.write(buffer.toString());
  }

  void _onSelect() {
    if (_multiple) {
      _selectedOptions.add(_currentIndex);
    } else {
      _selectedOptions.clear();
      _selectedOptions.add(_currentIndex);
    }
    _render();
  }

  void _onSubmit() {
    final selectedOptions =
        _selectedOptions.map((index) => _options[index]).toList();

    restoreCursorPosition();
    clearFromCursorToEnd();
    showCursor();

    final buffer = StringBuffer();
    buffer.writeAnsiAll([
      SetStyles(Style.foreground(Color.green)),
      Print('✔'),
      SetStyles.reset,
      Print(' $_message '),
      SetStyles(Style.foreground(Color.brightBlack)),
      Print(selectedOptions
          .map((element) => _onDisplay?.call(element) ?? element.toString())
          .join(', ')),
      SetStyles.reset,
      AsciiControl.lineFeed,
    ]);

    stdout.write(buffer.toString());

    _completer.complete(selectedOptions);
    _keepAlive = false;
  }
}
