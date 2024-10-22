import 'dart:async';
import 'dart:io';

import 'package:commander_ui/src/application/components/board/board_action.dart';
import 'package:commander_ui/src/application/components/board/board_header.dart';
import 'package:commander_ui/src/application/components/board/board_header_item.dart';
import 'package:commander_ui/src/application/components/board/board_manager.dart';
import 'package:commander_ui/src/application/terminals/terminal.dart';
import 'package:commander_ui/src/application/utils/terminal_tools.dart';
import 'package:commander_ui/src/io.dart';
import 'package:mansion/mansion.dart';

final class BoardScreen<T extends ScreenView> {
  final _terminalToolBucket = TerminalToolBucket();
  final BoardManager _manager;
  final Stream<List<int>> _stream;

  final T uid;
  late final Terminal _terminal;

  late final Duration _refreshInterval;
  Timer? _refreshTimer;

  StreamSubscription? _subscription;
  final Map<Object, FutureOr<void> Function(Stdout)> _actions = {};
  bool isListenKey = true;

  String? _title;
  late BoardHeader _header;

  BoardGetScreen get screens => _manager;

  BoardScreen(this._manager, this._stream,
      {required this.uid,
      String? title,
      Duration refreshInterval = const Duration(seconds: 1),
      BoardHeader? header,
      List<BoardAction> actions = const [],
      required Terminal terminal}) {
    _title = title;
    _header = header ?? BoardHeader();
    _terminal = terminal;
    _refreshInterval = refreshInterval;

    assignActions(actions);
  }

  void setTitle(String title) {
    _title = title;
    stdout.writeAnsi(SetTitle(title));
  }

  void enter() {
    _activeColumnItemUpdaters();

    stdout.writeAnsiAll([
      AlternateScreen.enter,
      CursorVisibility.hide,
      CursorPosition.save,
    ]);

    if (_title case String value) {
      stdout.writeAnsi(SetTitle(value));
    }

    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      stdout.writeAnsiAll([
        CursorPosition.restore,
        Clear.all,
      ]);

      if (_header.columnLength > 0) {
        _drawHeader();
      }

      _drawBody();
    });

    if (_actions.isNotEmpty) {
      _subscription = _terminalToolBucket.readKeyAsync(_terminal, _stream, (key) {
        if (key.controlChar == ControlCharacter.ctrlC) {
          _exit();
        }

        final element = _actions.containsKey(key.controlChar);

        if (!element) {
          final action = _actions[key.char];
          _terminal.disableRawMode();
          action?.call(stdout);
          _terminal.enableRawMode();
        } else {
          final action = _actions[key.controlChar];
          _terminal.disableRawMode();
          action?.call(stdout);
          _terminal.enableRawMode();
        }
      });
    }
  }

  void leave() {
    isListenKey = false;
    _refreshTimer?.cancel();
    _subscription?.cancel();

    _clearColumnItems();

    stdout.writeAnsiAll([
      AlternateScreen.leave,
      CursorVisibility.show,
      CursorPosition.resetColumn,
    ]);
  }

  void assignActions(List<BoardAction> actions) {
    _actions.clear();

    for (final action in actions) {
      for (final trigger in action.triggers) {
        final key = switch (trigger) {
          KeyStroke(:final char) when char.isNotEmpty => char,
          KeyStroke(:final controlChar) => controlChar,
        };
        _actions[key] = (Stdout output) => action.fn(this, output);
      }
    }
  }

  List<List<int>> getHeaderLengths() {
    List<List<int>> lengths = List.filled(_header.columnLength, []);

    for (int columnIndex = 0; columnIndex < _header.columnLength; columnIndex++) {
      final column = _header.getColumnAt(columnIndex);
      lengths[columnIndex] = List.filled(column.itemCount, 0);

      for (int i = 0; i < column.itemCount; i++) {
        final element = column.header[i];
        if (element.length > lengths[columnIndex][i]) {
          lengths[columnIndex][i] = element.length;
        }
      }
    }

    return lengths;
  }

  void _drawHeader() {
    final lengths = getHeaderLengths();

    for (int columnIndex = 0; columnIndex < _header.columnLength; columnIndex++) {
      final column = _header.getColumnAt(columnIndex);
      for (int row = 0; row < column.itemCount; row++) {
        final item = column.header[row];

        final previousColumn = _header.getPreviousColumn(columnIndex);
        final columnLength = columnIndex != 0
            ? previousColumn!.maxLabelLength +
                lengths[columnIndex - 1].reduce((a, b) => a > b ? a : b) +
                previousColumn.headerSpace
            : 0;

        stdout.writeAnsi(CursorPosition.moveTo(row + 1, columnLength));

        stdout.writeAnsiAll(switch (item.labelFormatter) {
          List<Sequence> Function(String) format => format(item.label),
          null => [Print(item.label)],
        });

        stdout.writeAnsi(Print(''.padRight(column.maxLabelLength - item.label.length)));

        if (item.text case String text) {
          stdout.writeAnsiAll(switch (item.textFormatter) {
            List<Sequence> Function(String) format => format(text),
            null => [Print(text)],
          });
        }
      }
    }

    stdout.writeAnsiAll([AsciiControl.lineFeed, AsciiControl.lineFeed]);
  }

  void _drawBody() {
    // stdout.writeAnsi(AsciiControl.lineFeed);
    // output.writeAnsi(CursorPosition.moveTo(_header.maxColumnLength + 1, 0));
    // output.writeAnsi(Print('┌${'─' * (stdout.terminalColumns - 2)}┐'));
    // ┌──────────────────────────────────────────────────── Pods(prodv3)[35] ────────────────────────────────────────────────────┐
  }

  void _actionOnColumnItems(FutureOr Function(BoardHeaderItem) action) {
    for (int columnIndex = 0; columnIndex < _header.columnLength; columnIndex++) {
      final column = _header.getColumnAt(columnIndex);
      for (int row = 0; row < column.itemCount; row++) {
        final item = column.header[row];
        action(item);
      }
    }
  }

  void _clearColumnItems() => _actionOnColumnItems((item) {
    item.dispose?.call();
  });

  void _activeColumnItemUpdaters() => _actionOnColumnItems((item) {
    if (item.updater case Function()? Function(BoardHeaderItem) updater) {
      item.dispose = updater(item);
    }
  });

  void _exit() {
    leave();
    _terminal.disableRawMode();
    exit(0);
  }
}
