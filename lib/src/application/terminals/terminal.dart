import 'dart:io';

import 'package:commander_ui/src/application/terminals/unix_terminal.dart';
import 'package:commander_ui/src/application/terminals/windows_terminal.dart';


abstract class Terminal {
  /// Enables raw mode which allows us to process each keypress as it comes in.
  void enableRawMode();

  /// Disables raw mode and restores the terminal’s original attributes.
  void disableRawMode();

  /// Reads current cursor position.
  (int, int) getCursorPosition();

  /// Returns the appropriate terminal implementation based on the platform.
  factory Terminal() => Platform.isWindows ? WindowsTerminal() : UnixTerminal();
}
