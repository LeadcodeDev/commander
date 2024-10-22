import 'dart:io';

import 'package:commander_ui/src/domains/models/component.dart';
import 'package:mansion/mansion.dart';

/// A component that represents an alternate screen.
final class Screen implements Component<ScreenManager> {
  String? _title;

  Screen({String? title}) {
    _title = title;
  }

  @override
  ScreenManager handle() => ScreenManager(this);
}

final class ScreenManager {
  final Screen _screen;

  ScreenManager(this._screen);

  void setTitle(String title) {
    _screen._title = title;
    stdout.writeAnsi(SetTitle(title));
  }

  void enter() {
    stdout.writeAnsi(AlternateScreen.enter);
    if (_screen._title case String title) {
      stdout.writeAnsi(SetTitle(title));
    }
  }

  void leave() {
    stdout.writeAnsi(AlternateScreen.leave);
  }
}
