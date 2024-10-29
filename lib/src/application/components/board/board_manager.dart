import 'package:commander_ui/src/application/components/board/board_action.dart';
import 'package:commander_ui/src/application/components/board/board_body.dart';
import 'package:commander_ui/src/application/components/board/board_header.dart';
import 'package:commander_ui/src/application/components/board/board_screen.dart';
import 'package:commander_ui/src/application/terminals/terminal.dart';

abstract interface class ScreenView {}

abstract interface class BoardCreateScreen {
  BoardScreen createScreen<T extends ScreenView>(T uid,
      {String? title,
      BoardHeader? header,
      required BoardBody Function() body,
      List<BoardAction> actions = const []});
}

abstract interface class BoardGetScreen {
  BoardScreen get<T extends ScreenView>(T uid);
}

final class BoardManager implements BoardCreateScreen, BoardGetScreen {
  final Terminal _terminal;
  final Stream<List<int>> _stream;
  final List<BoardScreen> screens = [];

  BoardManager(this._terminal, this._stream);

  @override
  BoardScreen get<T extends ScreenView>(T uid) =>
      screens.firstWhere((element) => element.uid == uid);

  @override
  BoardScreen createScreen<T extends ScreenView>(ScreenView uid,
      {String? title,
      Duration refreshInterval = const Duration(milliseconds: 500),
      BoardHeader? header,
      required BoardBody Function() body,
      List<BoardAction> actions = const []}) {
    final screen = BoardScreen(this, _stream,
        uid: uid,
        title: title,
        refreshInterval: refreshInterval,
        header: header,
        actions: actions,
        terminal: _terminal,
        body: body);
    screens.add(screen);

    return screen;
  }
}
