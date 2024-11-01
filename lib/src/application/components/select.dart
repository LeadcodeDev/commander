import 'dart:async';
import 'dart:io';

import 'package:commander_ui/src/application/terminals/terminal.dart';
import 'package:commander_ui/src/application/themes/default_select_theme.dart';
import 'package:commander_ui/src/application/utils/terminal_tools.dart';
import 'package:commander_ui/src/domains/models/component.dart';
import 'package:commander_ui/src/domains/themes/select_theme.dart';
import 'package:commander_ui/src/io.dart';
import 'package:mansion/mansion.dart';

/// A component that asks the user to select one option.
final class Select<T> with TerminalTools implements Component<Future<T>> {
  final _completer = Completer<T>();

  final Terminal _terminal;
  SelectTheme _theme;
  late int _displayCount;

  int _currentIndex = 0;
  T? _selectedOption;
  String _filter = '';

  late final String _message;
  late final T? _defaultValue;
  late final String _placeholder;
  late final String Function(T)? _onDisplay;
  late final List<T> _options;
  final List<T> _filteredOptions = [];

  Select(this._terminal,
      {required String message,
      required List<T> options,
      int displayCount = 5,
      T? defaultValue,
      String placeholder = '',
      String Function(T)? onDisplay,
      SelectTheme? theme})
      : _message = message,
        _options = options,
        _displayCount = displayCount,
        _defaultValue = defaultValue,
        _placeholder = placeholder,
        _onDisplay = onDisplay,
        _theme = theme ?? DefaultSelectTheme() {
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
      final key = readKey(_terminal, onExit: () {
        stdout.writeAnsiAll([
          CursorVisibility.show,
          CursorPosition.restore,
          Clear.afterCursor,
        ]);
      });

      if (key.controlChar == ControlCharacter.arrowUp || key.char == 'k') {
        if (_currentIndex != 0) {
          _currentIndex = _currentIndex - 1;
          _render();
        }
      } else if (key.controlChar == ControlCharacter.arrowDown || key.char == 'j') {
        if (_currentIndex < _filteredOptions.length - 1) {
          _currentIndex = _currentIndex + 1;
          _render();
        }
      } else if ([ControlCharacter.ctrlJ, ControlCharacter.ctrlM].contains(key.controlChar)) {
        _onSubmit();
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
    }

    return _completer.future;
  }

  List<T> _filterOptions() {
    return _options.where((item) {
      final value = _onDisplay?.call(item) ?? item.toString();
      return _options.isNotEmpty ? value.toLowerCase().contains(_filter.toLowerCase()) : true;
    }).toList();
  }

  void _render({bool isInitialRender = false}) {
    restoreCursorPosition();
    clearFromCursorToEnd();

    final buffer = StringBuffer();

    buffer.writeAnsiAll([
      ..._theme.askPrefixColor,
      Print(_theme.askPrefix),
      SetStyles.reset,
      Print(' $_message '),
      ..._filter.isEmpty ? _theme.placeholderColorMessage : _theme.filterColorMessage,
      _filter.isEmpty ? Print(_placeholder) : Print(_filter),
      SetStyles.reset,
      AsciiControl.lineFeed,
    ]);

    _filteredOptions.clear();
    _filteredOptions.addAll(_filterOptions());

    int start = _currentIndex - _displayCount >= 0 ? _currentIndex - _displayCount + 1 : 0;

    for (final choice in _filteredOptions.skip(start).take(_displayCount)) {
      final isCurrent = _filteredOptions.indexOf(choice) == _currentIndex;
      if (isCurrent) {
        buffer.writeAnsiAll([
          ..._theme.selectedIconColor,
          Print(_theme.selectedIcon),
        ]);
      } else {
        buffer.writeAnsi(Print(_theme.unselectedIcon));
      }

      buffer.writeAnsiAll([
        SetStyles.reset,
        Print(' ${_onDisplay?.call(choice) ?? choice.toString()}'),
        AsciiControl.lineFeed,
      ]);
    }

    buffer.writeAnsiAll([
      AsciiControl.lineFeed,
      ..._theme.helpColorMessage,
      Print(_theme.helpMessage),
      SetStyles.reset,
      AsciiControl.lineFeed,
    ]);

    if (isInitialRender) {
      createSpace(_terminal, buffer.toString().split('\x0A').length);
    }

    stdout.write(buffer.toString());
  }

  void _onSubmit() {
    if (_filteredOptions.isEmpty) return;
    _selectedOption = _filteredOptions[_currentIndex];

    final buffer = StringBuffer();

    restoreCursorPosition();
    clearFromCursorToEnd();
    showCursor();

    buffer.writeAnsiAll([
      ..._theme.successPrefixColor,
      Print(_theme.successPrefix),
      SetStyles.reset,
      Print(' $_message '),
      ..._theme.resultMessageColor,
      Print(_onDisplay?.call(_selectedOption as T) ?? _selectedOption.toString()),
      SetStyles.reset,
      AsciiControl.lineFeed,
    ]);

    stdout.write(buffer.toString());
    _completer.complete(_selectedOption);
  }
}
