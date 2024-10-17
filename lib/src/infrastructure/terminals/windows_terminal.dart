import 'dart:async';
import 'dart:io';

import 'package:commander_ui/src/domain/models/terminal.dart';
import 'package:win32/win32.dart';

final class WindowsTerminal implements Terminal {
  final _streamController = StreamController<List<int>>.broadcast();

  @override
  Stream<List<int>> get stream => _streamController.stream;

  WindowsTerminal() {
    outputHandle = GetStdHandle(STD_HANDLE.STD_OUTPUT_HANDLE);
    inputHandle = GetStdHandle(STD_HANDLE.STD_INPUT_HANDLE);

    stdin.listen(_streamController.add);
  }

  late final int inputHandle;
  late final int outputHandle;

  @override
  void enableRawMode() {
    const dwMode = (~CONSOLE_MODE.ENABLE_ECHO_INPUT) &
    (~CONSOLE_MODE.ENABLE_PROCESSED_INPUT) &
    (~CONSOLE_MODE.ENABLE_LINE_INPUT) &
    (~CONSOLE_MODE.ENABLE_WINDOW_INPUT);
    SetConsoleMode(inputHandle, dwMode);
  }

  @override
  void disableRawMode() {
    const dwMode = CONSOLE_MODE.ENABLE_ECHO_INPUT |
    CONSOLE_MODE.ENABLE_EXTENDED_FLAGS |
    CONSOLE_MODE.ENABLE_INSERT_MODE |
    CONSOLE_MODE.ENABLE_LINE_INPUT |
    CONSOLE_MODE.ENABLE_MOUSE_INPUT |
    CONSOLE_MODE.ENABLE_PROCESSED_INPUT |
    CONSOLE_MODE.ENABLE_QUICK_EDIT_MODE |
    CONSOLE_MODE.ENABLE_VIRTUAL_TERMINAL_INPUT;

    SetConsoleMode(inputHandle, dwMode);
  }
}
