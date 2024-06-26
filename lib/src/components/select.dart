import 'dart:async';
import 'dart:io';

import 'package:commander_ui/commander_ui.dart';
import 'package:mansion/mansion.dart';

/// A class that represents a select component.
/// This component handles user selection from a list of options.
final class Select<T> with Tools implements Component<T> {
  String filter = '';
  int currentIndex = 0;
  bool isRendering = false;

  final List<T> options;
  final String answer;
  final String? placeholder;
  late final List<Sequence> noResultFoundMessage;
  late final List<Sequence> exitMessage;

  final String Function(T)? onDisplay;
  late final List<Sequence> Function(String) selectedLineStyle;
  late final List<Sequence> Function(String) unselectedLineStyle;

  final _completer = Completer<T>();

  /// Creates a new instance of [Select].
  ///
  /// * The [answer] parameter is the question that the user is asked.
  /// * The [options] parameter is the list of options that the user can select from.
  /// * The [onDisplay] parameter is a function that transforms an option into a string for display.
  /// * The [placeholder] parameter is an optional placeholder for the input.
  /// * The [noResultFoundMessage] parameter is an optional message that is displayed when no results are found.
  /// * The [exitMessage] parameter is an optional message that is displayed when the user exits the input.
  /// * The [selectedLineStyle] parameter is a function that styles the selected line.
  /// * The [unselectedLineStyle] parameter is a function that styles the unselected line.
  Select({
    required this.answer,
    required this.options,
    this.onDisplay,
    this.placeholder,
    List<Sequence>? noResultFoundMessage,
    List<Sequence>? exitMessage,
    List<Sequence> Function(String)? selectedLineStyle,
    List<Sequence> Function(String)? unselectedLineStyle,
  }) {
    StdinBuffer.initialize();

    this.noResultFoundMessage = noResultFoundMessage ?? [
      SetStyles(Style.foreground(Color.brightBlack)),
      Print('No result found'),
      SetStyles.reset,
    ];

    this.exitMessage = exitMessage ?? [
      SetStyles(Style.foreground(Color.brightRed)),
      Print('✘'),
      SetStyles.reset,
      Print(' Operation canceled by user'),
    ];

    this.selectedLineStyle = selectedLineStyle ?? (line) => [
      SetStyles(Style.foreground(Color.brightGreen)),
      Print('❯'),
      SetStyles.reset,
      Print(' $line'),
    ];

    this.unselectedLineStyle = unselectedLineStyle ?? (line) => [
      Print(''.padRight(2)),
      Print(line),
    ];
  }

  /// Handles the select component and returns a [Future] that completes with the result of the selection.
  Future<T> handle() async {
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
      throw Exception('No result found');
    }

    final value = onDisplay?.call(options[currentIndex]) ?? options[currentIndex].toString();

    stdout.writeAnsiAll([
      SetStyles(Style.foreground(Color.green)),
      Print('✔'),
      SetStyles.reset,
      Print(' $answer '),
      SetStyles(Style.foreground(Color.brightBlack)),
      Print(value),
      SetStyles.reset
    ]);

    stdout.writeln();

    saveCursorPosition();
    showCursor();
    _completer.complete(options[currentIndex]);
  }

  void onExit(void Function() dispose) {
    dispose();

    restoreCursorPosition();
    clearFromCursorToEnd();
    showInput();

    stdout.writeln(exitMessage);
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
    final List<Sequence> copy = [];

    List<T> filteredArr = options.where((item) {
      final value = onDisplay?.call(item) ?? item.toString();
      return filter.isNotEmpty ? value.toLowerCase().contains(filter.toLowerCase()) : true;
    }).toList();

    buffer.writeAnsiAll([
      SetStyles(Style.foreground(Color.yellow)),
      Print('?'),
      SetStyles.reset,
      Print(' $answer : '),
      SetStyles(Style.foreground(Color.brightBlack)),
      Print(filter.isEmpty ? placeholder ?? '' : filter),
      SetStyles.reset,
    ]);

    if (filteredArr.isEmpty) {
      buffer.writeAnsiAll([
        AsciiControl.lineFeed,
        ...noResultFoundMessage,
        AsciiControl.lineFeed,
      ]);
    } else {
      copy.add(AsciiControl.lineFeed);
      int start = currentIndex - 2 >= 0 ? currentIndex - 2 : 0;
      if (currentIndex >= filteredArr.length - 2) {
        start = filteredArr.length - 5;
      }
      int end = start + 5 <= filteredArr.length ? start + 5 : filteredArr.length;

      for (int i = start; i < end; i++) {
        final value = onDisplay?.call(filteredArr[i]) ?? filteredArr[i].toString();
        if (i == currentIndex) {
          copy.addAll([...selectedLineStyle(value), AsciiControl.lineFeed]);
        } else {
          copy.addAll([...unselectedLineStyle(value), AsciiControl.lineFeed]);
        }
      }

      while (copy.isNotEmpty) {
        buffer.writeAnsi(copy.removeAt(0));
      }
    }

    buffer.writeAnsiAll([
      AsciiControl.lineFeed,
      SetStyles(Style.foreground(Color.brightBlack)),
      Print('(Type to filter, press ↑/↓ to navigate, enter to select)'),
      SetStyles.reset,
    ]);

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
