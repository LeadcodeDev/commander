import 'dart:io';

import 'package:commander_ui/commander_ui.dart';
import 'package:mansion/mansion.dart';

final class ProgressBar implements Component {
  int _currentValue = 0;
  final StringBuffer _buffer = StringBuffer();
  final int max;

  ProgressBar({required this.max}) {
    stdout.writeAnsi(CursorPosition.save);
    _render();
  }

  next({ List<Sequence>? message }) {
    if (message != null) {
      _buffer.clear();
      _buffer.writeAnsiAll(message);
    }
    if(_currentValue < max) {
      _currentValue++;
      _render();
    }
  }

  void done({List<Sequence>? message}) {
    _restoreScreen();
    if (message != null) {
      stdout.writeAnsiAll([...message, AsciiControl.lineFeed]);
    }
  }

  void _render() {
    _restoreScreen();
    final StringBuffer buffer = StringBuffer();

    buffer.writeAnsi(Print('${((100 / max) * _currentValue).toInt()}% '));

    for(int i = 0; i < _currentValue; i++) {
      buffer.writeAnsiAll([
        SetStyles(Style.foreground(Color.brightBlack)),
        Print('█'),
        SetStyles.reset,
      ]);
    }

    buffer.writeAnsiAll([
      CursorPosition.moveToColumn(max + 8),
      SetStyles(Style.foreground(Color.brightBlack)),
      Print(_buffer.toString()),
      SetStyles.reset,
    ]);

    stdout.write(buffer.toString());
    stdout.writeln();
  }

  void _restoreScreen() {
    stdout.writeAnsi(CursorPosition.restore);
    stdout.writeAnsi(Clear.afterCursor);
  }
}
