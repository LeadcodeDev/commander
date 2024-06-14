import 'dart:async';
import 'dart:io';

import 'package:commander_ui/src/commons/ansi_character.dart';
import 'package:commander_ui/src/commons/cli.dart';
import 'package:commander_ui/src/commons/color.dart';
import 'package:commander_ui/src/component.dart';
import 'package:commander_ui/src/key_down_event_listener.dart';
import 'package:commander_ui/src/result.dart';

final class Select<T, R extends dynamic> with Tools implements Component<Result<T>> {
  String filter = '';
  int currentIndex = 0;
  bool isRendering = false;

  final List<T> options;
  final String answer;
  final String? placeholder;
  late final String noResultFoundMessage;
  late final String exitMessage;

  final String Function(T)? onDisplay;
  late final String Function(String) selectedLineStyle;
  late final String Function(String) unselectedLineStyle;

  final _completer = Completer<Result<T>>();

  Select({
    required this.answer,
    required this.options,
    this.onDisplay,
    this.placeholder,
    String? noResultFoundMessage,
    String? exitMessage,
    String Function(String)? selectedLineStyle,
    String Function(String)? unselectedLineStyle,
  }) {
    this.noResultFoundMessage = noResultFoundMessage ?? AsciiColors.dim('No result found');
    this.exitMessage = exitMessage ?? '${AsciiColors.red('✘')} Operation canceled by user';
    this.selectedLineStyle = selectedLineStyle ?? (line) => '${AsciiColors.green('❯')} $selectedLineStyle(line)';
    this.unselectedLineStyle = unselectedLineStyle ?? (line) => '  $unselectedLineStyle(line)';
  }

  @override
  Future<Result<T>> handle() async {
    saveCursorPosition();
    hideCursor();
    hideInput();

    KeyDownEventListener()
      ..match(AnsiCharacter.downArrow, onKeyDown)
      ..match(AnsiCharacter.upArrow, onKeyUp)
      ..match(AnsiCharacter.del, onFilter)
      ..match(AnsiCharacter.enter, onSubmit)
      ..catchAll(onTap)
      ..onExit(onExit);

    render();

    return _completer.future;
  }

  void onKeyDown(String key, void Function() dispose) {
    saveCursorPosition();
    if (currentIndex != 0) {
      currentIndex = currentIndex - 1;
    }
    render();
  }

  void onKeyUp(String key, void Function() dispose) {
    saveCursorPosition();
    if (currentIndex < options.length - 1) {
      currentIndex = currentIndex + 1;
    }
    render();
  }

  void onFilter(String key, void Function() dispose) {
    if (filter.isNotEmpty) {
      filter = filter.substring(0, filter.length - 1);
    }
    render();
  }

  void onSubmit(String key, void Function() dispose) {
    restoreCursorPosition();
    clearFromCursorToEnd();
    showInput();

    dispose();

    if (options.elementAtOrNull(currentIndex) == null) {
      _completer.complete(Err('No result found'));
      return;
    }

    final value = onDisplay?.call(options[currentIndex]) ?? options[currentIndex].toString();

    stdout.writeln('${AsciiColors.green('✔')} $answer · ${AsciiColors.lightGreen(value)}');
    saveCursorPosition();
    showCursor();
    _completer.complete(Ok(options[currentIndex]));
  }

  void onExit(void Function() dispose) {
    dispose();

    restoreCursorPosition();
    clearFromCursorToEnd();
    showInput();

    stdout.writeln(exitMessage);
    _completer.complete(Err(exitMessage));
    exit(1);
  }

  void onTap(String key, void Function() dispose) {
    if (RegExp(r'^[\p{L}\p{N}\p{P}\s]*$', unicode: true).hasMatch(key)) {
      currentIndex = 0;
      filter = filter + key;

      if (isRendering) {
        return;
      }

      render();
    }
  }

  void render() async {
    isRendering = true;

    saveCursorPosition();

    final buffer = StringBuffer();
    final List<String> copy = [];

    List<T> filteredArr = options.where((item) {
      final value = onDisplay?.call(item) ?? item.toString();
      return filter.isNotEmpty
        ? value.toLowerCase().contains(filter.toLowerCase())
        : true;
    }).toList();

    buffer.writeln('${AsciiColors.yellow('?')} $answer : ${filter.isEmpty ? AsciiColors.dim(placeholder ?? '') : filter}');

    if (filteredArr.isEmpty) {
      buffer.writeln(noResultFoundMessage);
    } else {
      int start = currentIndex - 2 >= 0 ? currentIndex - 2 : 0;
      if (currentIndex >= filteredArr.length - 2) {
        start = filteredArr.length - 5;
      }
      int end = start + 5 <= filteredArr.length ? start + 5 : filteredArr.length;

      for (int i = start; i < end; i++) {
        final value = onDisplay?.call(filteredArr[i]) ?? filteredArr[i].toString();
        if (i == currentIndex) {
          copy.add(selectedLineStyle(value));
        } else {
          copy.add(unselectedLineStyle(value));
        }
      }

      while (copy.isNotEmpty) {
        buffer.writeln(copy.removeAt(0));
      }
    }

    final availableLines = await getAvailableLinesBelowCursor();
    final linesNeeded = buffer.toString().split('\n').length;

    if (availableLines < linesNeeded) {
      for (int i = 0; i < linesNeeded - availableLines; i++) {
        stdout.writeln();
      }

      moveCursorUp(count: linesNeeded - availableLines);
      saveCursorPosition();
    }

    clearFromCursorToEnd();
    restoreCursorPosition();
    saveCursorPosition();

    stdout.write(buffer.toString());

    restoreCursorPosition();

    isRendering = false;
  }
}
