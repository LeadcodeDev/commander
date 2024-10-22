import 'dart:io';

import 'package:commander_ui/src/application/components/board/board_screen.dart';
import 'package:commander_ui/src/io.dart';

final class BoardAction {
  final List<KeyStroke> triggers;
  final void Function(BoardScreen, Stdout) fn;

  const BoardAction(this.triggers, this.fn);
}
