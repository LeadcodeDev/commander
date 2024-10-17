import 'dart:async';
import 'dart:io';

import 'package:commander_ui/commander_ui.dart';
import 'package:commander_ui/src/domain/models/terminal.dart';
import 'package:commander_ui/src/infrastructure/models/key_down.dart';
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
    Terminal.init().enableRawMode();

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
      ..match([KeyDown.downArrow], _onKeyDown)
      ..match([KeyDown.upArrow], _onKeyUp)
      ..match([KeyDown.delete], _onFilter)
      ..match([KeyDown.ctrlM, KeyDown.ctrlJ], _onSubmit)
      ..catchAll(_onTap)
      ..onExit(_onExit);

    render(initialRender: true);

    return _completer.future;
  }

  void _onKeyUp(KeyDown key, void Function() dispose) {
    saveCursorPosition();
    if (currentIndex != 0) {
      currentIndex = currentIndex - 1;
    }
    render();
  }

  void _onKeyDown(KeyDown key, void Function() dispose) {
    saveCursorPosition();
    if (currentIndex < options.length - 1) {
      currentIndex = currentIndex + 1;
    }
    render();
  }

  void _onFilter(KeyDown key, void Function() dispose) {
    if (filter.isNotEmpty) {
      filter = filter.substring(0, filter.length - 1);
    }
    render();
  }

  void _onSubmit(KeyDown key, void Function() dispose) {
    if (_filteredArr.isEmpty) return;

    restoreCursorPosition();
    clearFromCursorToEnd();
    showInput();

    dispose();

    if (_filteredArr.elementAtOrNull(currentIndex) == null) {
      throw Exception('No result found');
    }

    final value =
        onDisplay?.call(_filteredArr[currentIndex]) ?? _filteredArr[currentIndex].toString();

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

  void _onTap(KeyDown key, void Function() dispose) {
    if (RegExp(r'^[\p{L}\p{N}\p{P}\s]*$', unicode: true).hasMatch(key.char)) {
      currentIndex = 0;
      filter = filter + key.char;

      if (isRendering) {
        return;
      }

      render();
    }
  }

  void render({bool initialRender = false}) async {
    isRendering = true;

    final buffer = StringBuffer();
    final List<Sequence> copy = [];

    _filteredArr = options.where((item) {
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

    if (_filteredArr.isEmpty) {
      buffer.writeAnsiAll([
        AsciiControl.lineFeed,
        ...noResultFoundMessage,
        AsciiControl.lineFeed,
      ]);
    } else {
      copy.add(AsciiControl.lineFeed);

      int start = currentIndex - displayCount + 1 >= 0 ? currentIndex - displayCount + 1 : 0;
      if (currentIndex >= _filteredArr.length && _filteredArr.length > displayCount) {
        start = _filteredArr.length - displayCount;
      } else {}

      int end =
          start + displayCount <= _filteredArr.length ? start + displayCount : _filteredArr.length;

      for (int i = start; i < end; i++) {
        final value = onDisplay?.call(_filteredArr[i]) ?? _filteredArr[i].toString();
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

    if (initialRender) {
      final availableLines = await getAvailableLinesBelowCursor();
      final linesNeeded = buffer.toString().split('\x0A').length;

      final int requiredLines = linesNeeded - availableLines;

      if (!requiredLines.isNegative) {
        for (int i = 0; i < requiredLines; i++) {
          stdout.writeln();
        }
        moveCursorUp(count: linesNeeded);
      }

      saveCursorPosition();
    }

    restoreCursorPosition();
    clearFromCursorToEnd();

    stdout.write(buffer.toString());

    restoreCursorPosition();

    isRendering = false;
  }
}
