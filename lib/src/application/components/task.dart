import 'dart:async';
import 'dart:io';

import 'package:commander_ui/src/application/terminals/terminal.dart';
import 'package:commander_ui/src/application/utils/terminal_tools.dart';
import 'package:commander_ui/src/domains/models/component.dart';
import 'package:mansion/mansion.dart';

final List<String> _loadingSteps = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

final class Task with TerminalTools implements Component<Future<StepManager>> {
  final Terminal _terminal;
  final bool _colored;

  Task(this._terminal, {bool colored = true}) : _colored = colored;

  @override
  Future<StepManager> handle() async {
    return StepManager(_terminal, _colored);
  }
}

final class StepManager with TerminalTools {
  final Terminal _terminal;
  (int, int)? _position;
  Timer? _timer;
  int _loadingStep = 0;
  bool isInitialStep = true;
  final bool _colored;

  StepManager(this._terminal, this._colored);

  Future<T> step<T>(String message, {FutureOr<T> Function()? callback}) {
    if (isInitialStep) {
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
          CursorPosition.moveTo(_position!.$2, _position!.$1),
          SetStyles(Style.foreground(Color.green)),
          Print(_loadingSteps[_loadingStep]),
          SetStyles.reset
        ]);

        task.render(buffer);
      });
    });

    return task.start();
  }

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
  }

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
  }

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
  }

  List<Sequence> _messageSequence(String message) {
    return [Print(message), SetStyles.reset, AsciiControl.lineFeed];
  }

  void _drawLoader(void Function() render) {
    if (_loadingStep == _loadingSteps.length - 1) {
      _loadingStep = 0;
    }

    render();
    _loadingStep += 1;
  }
}

final class StepTask<T> {
  final _completer = Completer<T>();

  final String _message;
  final FutureOr<void> Function()? _callback;

  StepTask(this._message, this._callback);

  Future<T> start() async {
    if (_callback case Future<void> Function() callback) {
      callback().then((value) {
        _completer.complete(value as T);
      });
    } else {
      await Future.delayed(Duration(milliseconds: 100), _completer.complete);
    }

    return _completer.future;
  }

  void render(StringBuffer buffer) {
    buffer.writeAnsiAll([
      SetStyles(Style.foreground(Color.brightBlack)),
      Print(' $_message'),
      SetStyles.reset,
      AsciiControl.lineFeed,
    ]);

    stdout.write(buffer.toString());
  }
}
