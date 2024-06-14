import 'dart:io';

import 'package:commander_ui/commander_ui.dart';
import 'package:commander_ui/src/components/switch.dart';

Future<void> main() async {
  StdinBuffer.initialize();

  final input = Switch(answer: 'Do you love cat ?', defaultValue: true);

  final value = switch (await input.handle()) {
    Ok(:final value) => 'My value is $value',
    Err(:final error) => Exception('Error: $error'),
    _ => 'Unknown',
  };

  print(value);

  exit(0);
}
