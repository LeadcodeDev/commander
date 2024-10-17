import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:commander_ui/src/domain/models/terminal.dart';
import 'package:commander_ui/src/infrastructure/models/key_down.dart';

void main() {
  final terminal = Terminal.init();
  terminal.enableRawMode();

  stdin.echoMode = false;
  stdin.lineMode = false;

  print('Press any key. Press ESC to exit.');
  stdin.echoMode = false;
  stdin.lineMode = false;

  terminal.stream.listen((List<int> input) {
    print(input);
    KeyDown key = KeyDown.fromInput(input);
    if (key == KeyDown.ctrlC) {
      terminal.disableRawMode();
      exit(0);
    }
    print(key);
  });
}
