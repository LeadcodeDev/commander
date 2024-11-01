import 'dart:async';
import 'dart:io';

import 'package:commander_ui/src/application/terminals/terminal.dart';
import 'package:commander_ui/src/application/themes/default_swap_theme.dart';
import 'package:commander_ui/src/application/utils/terminal_tools.dart';
import 'package:commander_ui/src/domains/models/component.dart';
import 'package:commander_ui/src/domains/themes/checkbox_theme.dart';
import 'package:commander_ui/src/domains/themes/swap_theme.dart';
import 'package:commander_ui/src/io.dart';
import 'package:mansion/mansion.dart';

/// A component that asks the user to swap between two options.
final class Swap<T> with TerminalTools implements Component<Future<bool>> {
  final _completer = Completer<bool>();

  final Terminal _terminal;
  final SwapTheme _theme;
  late bool _value;

  final String _message;
  final bool _defaultValue;
  final String? _placeholder;

  bool _keepAlive = true;

  Swap(this._terminal,
      {required String message,
      bool defaultValue = false,
      String? placeholder,
      SwapTheme? theme})
      : _message = message,
        _placeholder = placeholder,
        _defaultValue = defaultValue,
        _theme = theme ?? DefaultSwapTheme() {
    if (_defaultValue case bool value) {
      _value = value;
    }
  }

  @override
  Future<bool> handle() {
    saveCursorPosition();
    hideCursor();

    _render(isInitialRender: true);

    while (_keepAlive) {
      final key = readKey(_terminal, onExit: () {
        stdout.writeAnsiAll([
          CursorVisibility.show,
          CursorPosition.restore,
          Clear.afterCursor,
        ]);
      });

      if (key.controlChar == ControlCharacter.arrowLeft) {
        _value = true;
        _render();
      } else if (key.controlChar == ControlCharacter.arrowRight) {
        _value = false;
        _render();
      } else if ([ControlCharacter.ctrlJ, ControlCharacter.ctrlM].contains(key.controlChar)) {
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
      ..._theme.askPrefixColor,
      Print(_theme.askPrefix),
      SetStyles.reset,
      Print(' $_message'),
      if (_placeholder != null) ...[
        ..._theme.placeholderColorMessage,
        Print(_theme.placeholderFormatter(_placeholder)),
        SetStyles.reset,
      ],
      Print(' : '),
    ]);

    final List<bool> values = [true, false];

    for (final value in values) {
      buffer.writeAnsiAll([
        ...value == _value ? _theme.selected : _theme.unselected,
        Print(value ? 'Yes' : ' No'),
        SetStyles.reset,
      ]);
    }

    buffer.writeAnsiAll([
      AsciiControl.lineFeed,
      ..._theme.helpMessageColor,
      Print(_theme.helpMessage),
      SetStyles.reset,
    ]);

    if (isInitialRender) {
      createSpace(_terminal, buffer.toString().split('\x0A').length);
    }

    stdout.write(buffer.toString());
  }

  void _onSubmit() {
    restoreCursorPosition();
    clearFromCursorToEnd();
    showCursor();

    final buffer = StringBuffer();
    buffer.writeAnsiAll([
      ..._theme.successPrefixColor,
      Print(_theme.successPrefix),
      SetStyles.reset,
      Print(' $_message '),
      ..._theme.resultMessageColor,
      Print(_value ? 'Yes' : 'No'),
      SetStyles.reset,
      AsciiControl.lineFeed,
    ]);

    stdout.write(buffer.toString());

    _completer.complete(_value);
    _keepAlive = false;
  }
}
