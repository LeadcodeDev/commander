import 'dart:async';
import 'dart:io';

import 'package:commander_ui/commander_ui.dart';
import 'package:commander_ui/src/infrastructure/stdin_buffer.dart';
import 'package:mansion/mansion.dart';

/// A class that represents a select component.
/// This component handles user selection from a list of options.
final class Select<T> with Tools implements Component<T> {
  String filter = '';
  int currentIndex = 0;
  int displayCount;
  bool isRendering = false;

  final List<T> options;
  final String answer;
  final String? placeholder;
  late final List<Sequence> noResultFoundMessage;
  late final List<Sequence> exitMessage;
  final FutureOr Function()? onExit;

  final String Function(T)? onDisplay;
  late final List<Sequence> Function(String) selectedLineStyle;
  late final List<Sequence> Function(String) unselectedLineStyle;

  List<T> _filteredArr = [];

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
    this.displayCount = 5,
    this.onDisplay,
    this.placeholder,
    this.onExit,
    List<Sequence>? noResultFoundMessage,
    List<Sequence>? exitMessage,
    List<Sequence> Function(String)? selectedLineStyle,
    List<Sequence> Function(String)? unselectedLineStyle,
  }) {
    StdinBuffer.initialize();

    _filteredArr = options;

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
              Print('❯'),
              SetStyles.reset,
              Print(' $line'),
            ];

    this.unselectedLineStyle = unselectedLineStyle ??
        (line) => [
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
      ..match(AnsiCharacter.downArrow, _onKeyDown)
      ..match(AnsiCharacter.upArrow, _onKeyUp)
      ..match(AnsiCharacter.del, _onFilter)
      ..match(AnsiCharacter.enter, _onSubmit)
      ..catchAll(_onTap)
      ..onExit(_onExit);

    render();

    return _completer.future;
  }

  void _onKeyUp(String key, void Function() dispose) {
    saveCursorPosition();
    if (currentIndex != 0) {
      currentIndex = currentIndex - 1;
    }
    render();
  }

  void _onKeyDown(String key, void Function() dispose) {
    saveCursorPosition();
    if (currentIndex < options.length - 1) {
      currentIndex = currentIndex + 1;
    }
    render();
  }

  void _onFilter(String key, void Function() dispose) {
    if (filter.isNotEmpty) {
      filter = filter.substring(0, filter.length - 1);
    }
    render();
  }

  void _onSubmit(String key, void Function() dispose) {
    if (_filteredArr.isEmpty) return;

    restoreCursorPosition();
    clearFromCursorToEnd();
    showInput();

    dispose();

    if (_filteredArr.elementAtOrNull(currentIndex) == null) {
      throw Exception('No result found');
    }

    final value = onDisplay?.call(_filteredArr[currentIndex]) ??
        _filteredArr[currentIndex].toString();

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
    _completer.complete(_filteredArr[currentIndex]);
  }

  void _onExit(void Function() dispose) {
    dispose();

    restoreCursorPosition();
    clearFromCursorToEnd();
    showInput();
    showCursor();

    stdout.writeAnsiAll(exitMessage);
    onExit?.call();
    exit(1);
  }

  void _onTap(String key, void Function() dispose) {
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

    _filteredArr = options.where((item) {
      final value = onDisplay?.call(item) ?? item.toString();
      return filter.isNotEmpty
          ? value.toLowerCase().contains(filter.toLowerCase())
          : true;
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

    if (_filteredArr.isEmpty) {
      buffer.writeAnsiAll([
        AsciiControl.lineFeed,
        ...noResultFoundMessage,
        AsciiControl.lineFeed,
      ]);
    } else {
      copy.add(AsciiControl.lineFeed);

      int start = currentIndex - displayCount + 1 >= 0
          ? currentIndex - displayCount + 1
          : 0;
      if (currentIndex >= _filteredArr.length &&
          _filteredArr.length > displayCount) {
        start = _filteredArr.length - displayCount;
      } else {}

      int end = start + displayCount <= _filteredArr.length
          ? start + displayCount
          : _filteredArr.length;

      for (int i = start; i < end; i++) {
        final value =
            onDisplay?.call(_filteredArr[i]) ?? _filteredArr[i].toString();
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
