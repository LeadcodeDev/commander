import 'dart:async';
import 'dart:io';

import 'package:commander_ui/src/application/terminals/terminal.dart';
import 'package:commander_ui/src/application/themes/default_task_theme.dart';
import 'package:commander_ui/src/application/utils/terminal_tools.dart';
import 'package:commander_ui/src/domains/models/component.dart';
import 'package:commander_ui/src/domains/themes/task_theme.dart';
import 'package:mansion/mansion.dart';

/// A component that represents a task.
final class Task with TerminalTools implements Component<Future<StepManager>> {
  final Terminal _terminal;
  final TaskTheme _theme;

  Task(this._terminal, {TaskTheme? theme})
      : _theme = theme ?? DefaultTaskTheme();

  @override
  Future<StepManager> handle() async {
    return StepManager(_terminal, _theme);
  }
}

/// A manager that handles the steps of a task.
final class StepManager with TerminalTools {
  final Terminal _terminal;
  final TaskTheme _theme;

  (int, int)? _position;
  Timer? _timer;
  int _loadingStep = 0;
  bool isInitialStep = true;
  int _lineCount = 0;

  StepManager(this._terminal, this._theme);

  /// Add new step to the task.
  Future<T> step<T>(String message, {FutureOr<T> Function()? callback}) {
    if (isInitialStep) {
      createSpace(_terminal, 1);
      _position = readCursorPosition(_terminal);
      isInitialStep = false;
    }

    final task = StepTask<T>(message, _theme, callback);

    stdout.writeAnsi(CursorVisibility.hide);
    if (_timer != null) {
      _timer?.cancel();
    }

    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      _drawLoader(() {
        final buffer = StringBuffer();

        buffer.writeAnsiAll([
          CursorPosition.moveToColumn(_position!.$1),
          ..._theme.loadingSymbolColor,
          Print(_theme.loadingSymbols[_loadingStep]),
          SetStyles.reset
        ]);

        task._render(buffer);
      });
    });

    return task._start();
  }

  /// Finishes the task with a success message.
  void success(String message) {
    final buffer = StringBuffer();

    if (Platform.isWindows) {
      _lineCount += 1;
    }

    buffer.writeAnsiAll([
      CursorPosition.moveTo(_position!.$2 + _lineCount, _position!.$1),
      ..._theme.successPrefixColor,
      Print(_theme.successPrefix),
      SetStyles.reset,
      ..._messageSequence(message),
    ]);

    _timer?.cancel();
    stdout.write(buffer.toString());
  }

  /// Finishes the task with an error message.
  void warn(String message) {
    final buffer = StringBuffer();

    if (Platform.isWindows) {
      _lineCount += 1;
    }

    buffer.writeAnsiAll([
      CursorPosition.moveTo(_position!.$2 + _lineCount, _position!.$1),
      ..._theme.warningPrefixColor,
      Print(_theme.warningPrefix),
      SetStyles.reset,
      ..._messageSequence(message),
    ]);

    _timer?.cancel();
    stdout.write(buffer.toString());
  }

  /// Finishes the task with an error message.
  void error(String message) {
    final buffer = StringBuffer();

    if (Platform.isWindows) {
      _lineCount += 1;
    }

    buffer.writeAnsiAll([
      CursorPosition.moveTo(_position!.$2 + _lineCount, _position!.$1),
      ..._theme.errorPrefixColor,
      Print(_theme.errorPrefix),
      SetStyles.reset,
      ..._messageSequence(message),
    ]);

    _timer?.cancel();
    stdout.write(buffer.toString());
  }

  List<Sequence> _messageSequence(String message) {
    return [
      Print(message),
      SetStyles.reset,
      CursorVisibility.show,
      AsciiControl.lineFeed,
      const CursorPosition.moveToColumn(0)
    ];
  }

  void _drawLoader(void Function() render) {
    if (_loadingStep == _theme.loadingSymbols.length - 1) {
      _loadingStep = 0;
    }

    render();
    _loadingStep += 1;
  }
}

/// A task step.
final class StepTask<T> {
  final _completer = Completer<T>();

  final TaskTheme _theme;
  final String _message;
  final FutureOr<void> Function()? _callback;

  StepTask(this._message, this._theme, this._callback);

  Future<T> _start() async {
    if (_callback case FutureOr<T> Function() callback) {
      final value = await callback();
      _completer.complete(value);
    } else {
      await Future.delayed(Duration(milliseconds: 100), _completer.complete);
    }

    return _completer.future;
  }

  void _render(StringBuffer buffer) {
    buffer.writeAnsiAll([
      ..._theme.defaultColor,
      Print(' $_message'),
      SetStyles.reset,
    ]);

    stdout.write(buffer.toString());
  }
}
