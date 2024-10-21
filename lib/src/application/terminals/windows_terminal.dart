import 'dart:ffi';

import 'package:commander_ui/src/application/terminals/terminal.dart';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class WindowsTerminal implements Terminal {
  WindowsTerminal() {
    outputHandle = GetStdHandle(STD_HANDLE.STD_OUTPUT_HANDLE);
    inputHandle = GetStdHandle(STD_HANDLE.STD_INPUT_HANDLE);
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

  @override
  (int, int) getCursorPosition() {
    final hConsoleOutput = GetStdHandle(STD_HANDLE.STD_OUTPUT_HANDLE);

    // Crée une structure pour stocker les informations de la console
    final info = calloc<CONSOLE_SCREEN_BUFFER_INFO>();

    // Appelle l'API Windows pour obtenir les informations sur le buffer de la console
    final success = GetConsoleScreenBufferInfo(hConsoleOutput, info);

    if (success != 0) {
      // Si l'appel réussit, récupère la position du curseur
      throw WindowsException(GetLastError());
    }

    final cursorPosition = info.ref.dwCursorPosition;


    // Libère la mémoire allouée pour la structure
    calloc.free(info);

    return (cursorPosition.X, cursorPosition.Y);
  }
}
