import 'dart:io';
import 'dart:math';

import 'package:commander_ui/commander_ui.dart';
import 'package:mansion/mansion.dart';

/// A class that represents a table component.
/// This component handles displaying a table with ASCII symbols.
final class Viewport with Tools implements Component {
  final List<Sequence>? title;
  final String content;
  final StringBuffer _buffer = StringBuffer();

  int _currentIndex = 0;

  /// Creates a new instance of [Table].
  Viewport({required this.content, this.title}) {
    StdinBuffer.initialize();

    hideCursor();
    hideInput();

    _buffer.write(content);

    stdout.writeAnsi(AlternateScreen.enter);
    _writeTitle();

    KeyDownEventListener()
      ..match(AnsiCharacter.downArrow, onKeyDown)
      ..match(AnsiCharacter.upArrow, onKeyUp)
      ..onExit(onExit);

    ProcessSignal.sigwinch.watch().listen((signal) {
      _currentIndex = 0;
      render();
    });

    render();
  }

  void _writeTitle() {
    if (title case List<Sequence> title) {
      final value = title.whereType<Print>().map((element) => element.text).join('');
      stdout.writeAnsi(SetTitle(value));
    }
  }

  Future<void> onKeyDown(String key, void Function() dispose) async {
    if (await contentIsOverflowing()) {
      if (_currentIndex != 0) {
        _currentIndex = _currentIndex - 1;
      }
      render();
    }
  }


  Future<void> onKeyUp(String key, void Function() dispose) async {
    if (await contentIsOverflowing()) {
      if (_currentIndex < content.split('\n').length - 1) {
        _currentIndex = _currentIndex + 1;
      }
      render();
    }
  }

  Future<bool> contentIsOverflowing() async {
    final lines = content.split('\n');
    final availableLines = await getAvailableLinesBelowCursor();

    return lines.length > availableLines;
  }

  void onExit(void Function() dispose) {
    dispose();

    stdout.writeAnsi(AlternateScreen.leave);

    showInput();
    showCursor();
    exit(0);
  }

  void render() async {
    saveCursorPosition();
    _buffer.clear();

    final List<String> copy = [];
    final lines = content.split('\n');

    final availableLines = await getAvailableLinesBelowCursor();
    final linesNeeded = lines.length;

    copy.addAll(lines.getRange(_currentIndex, min(_currentIndex + availableLines, lines.length)));

    while (copy.isNotEmpty) {
      _buffer.writeln(copy.removeAt(0));
    }

    if (availableLines < linesNeeded) {
      moveCursorUp(count: linesNeeded - availableLines);
      saveCursorPosition();
      clearFromCursorToEnd();
    }

    clearFromCursorToEnd();
    restoreCursorPosition();
    saveCursorPosition();

    stdout.write(_buffer.toString());

    restoreCursorPosition();
  }
}
