import 'dart:io';

import 'package:commander_ui/src/components/viewport.dart';
import 'package:mansion/mansion.dart';

Future<void> main() async {
  final file = File('example/table.dart');
  Viewport(
    title: [SetStyles(Style.bold), Print(file.path), SetStyles.reset, AsciiControl.lineFeed],
      content: await file.readAsString()
  );
}
