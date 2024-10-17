import 'dart:async';
import 'dart:io';

import 'package:commander_ui/commander_ui.dart';
import 'package:mansion/mansion.dart';

enum Status {
  online,
  offline,
}

class Delayed with Tools implements Component<void> {
  final List<String> _loadingSteps = [
    '⠋',
    '⠙',
    '⠹',
    '⠸',
    '⠼',
    '⠴',
    '⠦',
    '⠧',
    '⠇',
    '⠏'
  ];
  int _currentStep = 0;
  Status _status = Status.online;

  final StringBuffer _symbol = StringBuffer();
  final StringBuffer _buffer = StringBuffer();

  Delayed() {
    stdout.writeAnsi(CursorPosition.save);
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (_currentStep == _loadingSteps.length - 1) {
        _currentStep = 0;
      }

      _symbol.clear();
      _symbol.writeAnsiAll([
        SetStyles(Style.foreground(Color.green)),
        Print(_loadingSteps[_currentStep]),
        SetStyles.reset
      ]);

      _currentStep += 1;
      _restoreScreen();
      _render();

      if (_status == Status.offline) {
        timer.cancel();
      }
    });
  }

  void step(String step) {
    _buffer.clear();
    _buffer.writeAnsiAll([
      SetStyles(Style.foreground(Color.brightBlack)),
      Print(step),
      SetStyles.reset
    ]);
  }

  void success(String message) {
    _status = Status.offline;
    Future.delayed(const Duration(milliseconds: 100), () {
      _restoreScreen();
      stdout.writeAnsiAll([
        SetStyles(Style.foreground(Color.green)),
        Print('✔ '),
        SetStyles.reset,
        Print(message),
        AsciiControl.lineFeed,
      ]);
    });
  }

  void error(String message) {
    _status = Status.offline;
    Future.delayed(const Duration(milliseconds: 100), () {
      _restoreScreen();
      stdout.writeAnsiAll([
        SetStyles(Style.foreground(Color.red)),
        Print('✖ '),
        SetStyles.reset,
        Print(message),
        AsciiControl.lineFeed,
      ]);
    });
  }

  void _restoreScreen() {
    stdout.writeAnsi(CursorPosition.restore);
    stdout.writeAnsi(Clear.afterCursor);
  }

  void _render() {
    stdout.write('$_symbol $_buffer');
  }
}
