import 'dart:io';

import 'package:commander_ui/src/domain/models/terminal.dart';
import 'package:commander_ui/src/infrastructure/models/key_down.dart';

mixin TerminalTools {
  Terminal get terminal => _switch((terminal) => terminal);

  void enableRawMode() => _switch((terminal) => terminal.enableRawMode());

  void disableRawMode() => _switch((terminal) => terminal.disableRawMode);

  T _switch<T>(T Function(Terminal) payload) => switch (Terminal.terminal) {
        Terminal terminal => payload(terminal),
        _ => throw Exception('Terminal not initialized'),
      };

  KeyDown readKey() {
    enableRawMode();
    final key = _readKey();
    disableRawMode();

    if (key == KeyDown.ctrlC) exit(0);

    return key;
  }

  KeyDown _readKey() {
    var codeUnit = 0;
    int charCode;

    while (codeUnit <= 0) {
      codeUnit = stdin.readByteSync();
    }

    final List<String> es = [];
    KeyDown key = KeyDown.fromInput([codeUnit]);

    if (key == KeyDown.escape) {
      charCode = stdin.readByteSync();
      es.add(String.fromCharCode(charCode));

      if (es[0] == '[') {
        charCode = stdin.readByteSync();
        es.add(String.fromCharCode(charCode));
      }

      key = switch (es[1]) {
        String value when value == 'A' => KeyDown.upArrow,
        String value when value == 'B' => KeyDown.downArrow,
        String value when value == 'C' => KeyDown.rightArrow,
        String value when value == 'D' => KeyDown.leftArrow,
        _ => KeyDown.unknown,
      };
    }

    return key;
  }
}
