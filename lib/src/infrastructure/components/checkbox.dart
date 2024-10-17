import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:commander_ui/commander_ui.dart';
import 'package:commander_ui/src/infrastructure/stdin_buffer.dart';
import 'package:mansion/mansion.dart';

/// A class that represents a checkbox component.
/// This component handles user selection from a list of options.
final class Checkbox<T> with Tools implements Component<T> {
  int currentIndex = 0;
  bool isRendering = false;

  final List<T> options;
  final List<int> _selectedIndexes = [];
  final String answer;
  final String? placeholder;
  final int? max;
  late final List<Sequence> noResultFoundMessage;
  late final List<Sequence> exitMessage;

  final String Function(T)? onDisplay;
  final FutureOr Function()? onExit;
  late final List<Sequence> Function(String) selectedLineStyle;
  late final List<Sequence> Function(String) unselectedLineStyle;
  late final List<Sequence> Function(String) highlightedSelectedLineStyle;
  late final List<Sequence> Function(String) highlightedUnselectedLineStyle;

  final _completer = Completer<List<T>>();

  /// Creates a new instance of [Checkbox].
  ///
  /// * The [answer] parameter is the question that the user is asked.
  /// * The [options] parameter is the list of options that the user can select from.
  /// * The [onDisplay] parameter is a function that transforms an option into a string for display.
  /// * The [placeholder] parameter is an optional placeholder for the input.
  /// * The [noResultFoundMessage] parameter is an optional message that is displayed when no results are found.
  /// * The [exitMessage] parameter is an optional message that is displayed when the user exits the input.
  /// * The [selectedLineStyle] parameter is a function that styles the selected line.
  /// * The [unselectedLineStyle] parameter is a function that styles the unselected line.
  /// * The [highlightedSelectedLineStyle] parameter is a function that styles the highlighted selected line.
  /// * The [highlightedUnselectedLineStyle] parameter is a function that styles the highlighted unselected line.
  Checkbox({
    required this.answer,
    required this.options,
    this.onDisplay,
    this.onExit,
    this.placeholder,
    this.max,
    List<Sequence>? noResultFoundMessage,
    List<Sequence>? exitMessage,
    List<Sequence> Function(String)? selectedLineStyle,
    List<Sequence> Function(String)? unselectedLineStyle,
    List<Sequence> Function(String)? highlightedSelectedLineStyle,
    List<Sequence> Function(String)? highlightedUnselectedLineStyle,
  }) {
    StdinBuffer.initialize();

    this.noResultFoundMessage = noResultFoundMessage ??
        [
          SetStyles(Style.foreground(Color.brightBlack)),
          Print('No result found'),
          SetStyles.reset,
        ];

    this.exitMessage = exitMessage ??
        [
          SetStyles(Style.foreground(Color.brightRed)),
          Print('✘'),
          SetStyles.reset,
          Print(' Operation canceled by user'),
          AsciiControl.lineFeed,
        ];

    this.selectedLineStyle = selectedLineStyle ??
        (line) => [
              SetStyles(Style.foreground(Color.brightGreen)),
              Print('•'),
              SetStyles(Style.foreground(Color.brightBlack)),
              Print(' $line'),
              SetStyles.reset,
            ];

    this.unselectedLineStyle = unselectedLineStyle ??
        (line) => [
              SetStyles(Style.foreground(Color.brightBlack)),
              Print('•'.padRight(2)),
              Print(line),
              SetStyles.reset,
            ];

    this.highlightedSelectedLineStyle = highlightedSelectedLineStyle ??
        (line) => [
              SetStyles(Style.foreground(Color.brightGreen)),
              Print('•'),
              SetStyles.reset,
              Print(' $line'),
            ];

    this.highlightedUnselectedLineStyle = highlightedUnselectedLineStyle ??
        (line) => [
              SetStyles(Style.foreground(Color.brightBlack)),
              Print('•'),
              SetStyles.reset,
              Print(' $line'),
            ];
  }

  /// Handles the select component and returns a [Future] that completes with the result of the selection.
  Future<List<T>> handle() async {
    saveCursorPosition();
    hideCursor();
    hideInput();

    KeyDownEventListener()
      ..match(AnsiCharacter.downArrow, _onKeyDown)
      ..match(AnsiCharacter.upArrow, _onKeyUp)
      ..match(AnsiCharacter.enter, _onSubmit)
      ..match(AnsiCharacter.space, _onSpace)
      ..onExit(_onExit);

    _render();

    return _completer.future;
  }

  void _onKeyUp(String key, void Function() dispose) {
    saveCursorPosition();
    if (currentIndex != 0) {
      currentIndex = currentIndex - 1;
    }
    _render();
  }

  void _onKeyDown(String key, void Function() dispose) {
    saveCursorPosition();
    if (currentIndex < options.length - 1) {
      currentIndex = currentIndex + 1;
    }
    _render();
  }

  void _onSubmit(String key, void Function() dispose) {
    restoreCursorPosition();
    clearFromCursorToEnd();
    showInput();

    dispose();

    final selectedValues = options
        .whereIndexed((index, _) => _selectedIndexes.contains(index))
        .toList();
    final values =
        selectedValues.map((value) => onDisplay?.call(value) ?? value).toList();

    stdout.writeAnsiAll([
      SetStyles(Style.foreground(Color.green)),
      Print('✔'),
      SetStyles.reset,
      Print(' $answer '),
      SetStyles(Style.foreground(Color.brightBlack)),
      Print(values.join(', ')),
      SetStyles.reset
    ]);

    stdout.writeln();

    saveCursorPosition();
    showCursor();

    final selectedOptions = options
        .whereIndexed((index, _) => _selectedIndexes.contains(index))
        .toList();
    _completer.complete(selectedOptions);
  }

  void _onExit(void Function() dispose) {
    dispose();

    restoreCursorPosition();
    clearFromCursorToEnd();
    showInput();

    stdout.writeAnsiAll(exitMessage);
    onExit?.call();
    exit(1);
  }

  void _onSpace(String key, void Function() dispose) {
    saveCursorPosition();

    if (max case int value when _selectedIndexes.length >= value) {
      return;
    }

    if (_selectedIndexes.contains(currentIndex)) {
      _selectedIndexes.remove(currentIndex);
    } else {
      _selectedIndexes.add(currentIndex);
    }

    _render();
  }

  void _render() async {
    isRendering = true;

    saveCursorPosition();

    final buffer = StringBuffer();
    final List<Sequence> copy = [];

    buffer.writeAnsiAll([
      SetStyles(Style.foreground(Color.yellow)),
      Print('?'),
      SetStyles.reset,
      Print(' $answer : '),
      SetStyles(Style.foreground(Color.brightBlack)),
      Print(placeholder ?? ''),
      SetStyles.reset,
    ]);

    copy.add(AsciiControl.lineFeed);

    for (int i = 0; i < options.length; i++) {
      final value = onDisplay?.call(options[i]) ?? options[i].toString();

      if (_selectedIndexes.contains(i)) {
        if (currentIndex == i) {
          copy.addAll(
              [...highlightedSelectedLineStyle(value), AsciiControl.lineFeed]);
        } else {
          copy.addAll([...selectedLineStyle(value), AsciiControl.lineFeed]);
        }
      } else {
        if (currentIndex == i) {
          copy.addAll([
            ...highlightedUnselectedLineStyle(value),
            AsciiControl.lineFeed
          ]);
        } else {
          copy.addAll([...unselectedLineStyle(value), AsciiControl.lineFeed]);
        }
      }
    }

    while (copy.isNotEmpty) {
      buffer.writeAnsi(copy.removeAt(0));
    }

    buffer.writeAnsiAll([
      AsciiControl.lineFeed,
      SetStyles(Style.foreground(Color.brightBlack)),
      Print(
          '(Type to filter, press ↑/↓ to navigate, space to select, enter to submit)'),
      SetStyles.reset,
    ]);

    final availableLines = await getAvailableLinesBelowCursor();
    final linesNeeded = buffer.toString().split('\n').length;

    if (availableLines < linesNeeded) {
      moveCursorUp(count: linesNeeded - availableLines);
      saveCursorPosition();
      clearFromCursorToEnd();
    }

    clearFromCursorToEnd();
    restoreCursorPosition();
    saveCursorPosition();

    stdout.write(buffer.toString());

    restoreCursorPosition();

    isRendering = false;
  }
}
