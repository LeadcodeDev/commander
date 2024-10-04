import 'dart:io';

import 'package:commander_ui/src/commons/cli.dart';
import 'package:commander_ui/src/component.dart';
import 'package:mansion/mansion.dart' as mansion;

class AlternateScreen with Tools implements Component<void> {
  String? title;

  AlternateScreen({this.title});

  void setTitle(String title) {
    this.title = title;
    stdout.writeAnsi(mansion.SetTitle(title));
  }

  void start() {
    stdout.writeAnsi(mansion.AlternateScreen.enter);
    if (title case String title) {
      stdout.writeAnsi(mansion.SetTitle(title));
    }
  }

  void stop() {
    stdout.writeAnsi(mansion.AlternateScreen.leave);
  }
}
