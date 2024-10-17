import 'dart:async';
import 'dart:io';

import 'package:commander_ui/src/infrastructure/terminals/unix_terminal.dart';
import 'package:commander_ui/src/infrastructure/terminals/windows_terminal.dart';

abstract class Terminal {
  /// A terminal instance.
  static Terminal? terminal;

  Stream<List<int>> get stream;

  /// Enables raw mode for the terminal.
  void enableRawMode();

  /// Disables raw mode for the terminal.
  void disableRawMode();

  factory Terminal.init() {
    if (Terminal.terminal case Terminal terminal) {
      return terminal;
    }

    Terminal.terminal = switch(Platform.isWindows) {
      true => WindowsTerminal(),
      false => UnixTerminal(),
    };

    return Terminal.terminal!;
  }
}
