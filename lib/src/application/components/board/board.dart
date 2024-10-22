import 'dart:io';

import 'package:commander_ui/src/application/components/board/board_manager.dart';
import 'package:commander_ui/src/application/terminals/terminal.dart';
import 'package:commander_ui/src/domains/models/component.dart';

final class Board implements Component<BoardManager> {
  final Stream<List<int>> _stream = stdin.asBroadcastStream();
  final Terminal _terminal;

  Board(this._terminal);

  @override
  BoardManager handle() => BoardManager(_terminal, _stream);
}
