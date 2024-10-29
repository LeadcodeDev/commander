import 'dart:async';
import 'dart:io';

import 'package:commander_ui/src/application/terminals/terminal.dart';
import 'package:commander_ui/src/application/utils/terminal_tools.dart';
import 'package:commander_ui/src/domains/models/component.dart';
import 'package:mansion/mansion.dart';

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

/// A component that represents a task.
final class Task with TerminalTools implements Component<Future<StepManager>> {
  final Terminal _terminal;
  final bool _colored;

  Task(this._terminal, {bool colored = true}) : _colored = colored;

  @override
  Future<StepManager> handle() async {
    return StepManager(_terminal, _colored);
  }
}

/// A manager that handles the steps of a task.
final class StepManager with TerminalTools {
  final Terminal _terminal;
  (int, int)? _position;
  Timer? _timer;
  int _loadingStep = 0;
  bool isInitialStep = true;
  final bool _colored;

  StepManager(this._terminal, this._colored);

  /// Add new step to the task.
  Future<T> step<T>(String message, {FutureOr<T> Function()? callback}) {
    if (isInitialStep) {
      _terminal.enableRawMode();
      createSpace(_terminal, 1);
      _position = readCursorPosition(_terminal);
      isInitialStep = false;
    }

    final task = StepTask<T>(message, callback);

    stdout.writeAnsi(CursorVisibility.hide);
    if (_timer != null) {
      _timer?.cancel();
    }

    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      _drawLoader(() {
        final buffer = StringBuffer();

        buffer.writeAnsiAll([
          CursorPosition.moveToColumn(_position!.$1),
          SetStyles(Style.foreground(Color.green)),
          Print(_loadingSteps[_loadingStep]),
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

    buffer.writeAnsiAll([
      CursorPosition.moveTo(_position!.$2, _position!.$1),
      SetStyles(Style.foreground(Color.green)),
      Print('✔ '),
      if (!_colored) SetStyles.reset,
      ..._messageSequence(message),
    ]);

    _timer?.cancel();
    stdout.write(buffer.toString());
    _terminal.disableRawMode();
  }

  /// Finishes the task with an error message.
  void warn(String message) {
    final buffer = StringBuffer();

    buffer.writeAnsiAll([
      CursorPosition.moveTo(_position!.$2, _position!.$1),
      SetStyles(Style.foreground(Color.yellow)),
      Print('⚠ '),
      if (!_colored) SetStyles.reset,
      ..._messageSequence(message),
    ]);

    _timer?.cancel();
    stdout.write(buffer.toString());
    _terminal.disableRawMode();
  }

  /// Finishes the task with an error message.
  void error(String message) {
    final buffer = StringBuffer();

    buffer.writeAnsiAll([
      CursorPosition.moveTo(_position!.$2, _position!.$1),
      SetStyles(Style.foreground(Color.red)),
      Print('✘ '),
      if (!_colored) SetStyles.reset,
      ..._messageSequence(message),
    ]);

    _timer?.cancel();
    stdout.write(buffer.toString());
    _terminal.disableRawMode();
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
    if (_loadingStep == _loadingSteps.length - 1) {
      _loadingStep = 0;
    }

    render();
    _loadingStep += 1;
  }
}

/// A task step.
final class StepTask<T> {
  final _completer = Completer<T>();

  final String _message;
  final FutureOr<void> Function()? _callback;

  StepTask(this._message, this._callback);

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
      SetStyles(Style.foreground(Color.brightBlack)),
      Print(' $_message'),
      SetStyles.reset,
    ]);

    stdout.write(buffer.toString());
  }
}
