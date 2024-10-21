import 'dart:async';
import 'dart:io';

import 'package:commander_ui/src/application/terminals/terminal.dart';
import 'package:commander_ui/src/application/utils/terminal_tools.dart';
import 'package:commander_ui/src/domains/models/component.dart';
import 'package:commander_ui/src/io.dart';
import 'package:mansion/mansion.dart';

final class Swap<T> with TerminalTools implements Component<Future<bool>> {
  final _completer = Completer<bool>();

  final Terminal _terminal;
  late bool _value;

  late final String _message;
  late final bool _defaultValue;
  late final String _placeholder;

  bool _keepAlive = true;

  Swap(this._terminal,
      {required String message, bool defaultValue = false, String placeholder = ''}) {
    _message = message;
    _placeholder = placeholder;
    _defaultValue = defaultValue;

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
      final key = readKey(_terminal);

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
      SetStyles(Style.foreground(Color.yellow)),
      Print('?'),
      SetStyles.reset,
      Print(' $_message'),
      if (_placeholder.isNotEmpty) ...[
        SetStyles(Style.foreground(Color.brightBlack)),
        Print(' ($_placeholder)'),
        SetStyles.reset,
      ],
      Print(' : '),
    ]);

    final List<bool> values = [true, false];

    for (final value in values) {
      buffer.writeAnsiAll([
        SetStyles(Style.foreground(value == _value ? Color.reset : Color.brightBlack)),
        Print(value ? 'Yes' : ' No'),
        SetStyles.reset,
      ]);
    }

    buffer.writeAnsiAll([
      AsciiControl.lineFeed,
      SetStyles(Style.foreground(Color.brightBlack)),
      Print('(Press ←/→ to select, enter to confirm)'),
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
      SetStyles(Style.foreground(Color.green)),
      Print('✔'),
      SetStyles.reset,
      Print(' $_message '),
      SetStyles(Style.foreground(Color.brightBlack)),
      Print(_value ? 'Yes' : 'No'),
      SetStyles.reset,
      AsciiControl.lineFeed,
    ]);

    stdout.write(buffer.toString());

    _completer.complete(_value);
    _keepAlive = false;
  }
}
