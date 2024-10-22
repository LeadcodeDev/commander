import 'dart:async';

import 'package:commander_ui/src/application/components/board/board_action.dart';
import 'package:commander_ui/src/application/components/board/board_header.dart';
import 'package:commander_ui/src/application/components/board/board_header_column.dart';
import 'package:commander_ui/src/application/components/board/board_header_item.dart';
import 'package:commander_ui/src/application/components/board/board_manager.dart';
import 'package:commander_ui/src/commander.dart';
import 'package:commander_ui/src/io.dart';
import 'package:commander_ui/src/level.dart';
import 'package:mansion/mansion.dart';

enum Screen implements ScreenView {
  home,
  page,
}

Future<void> main() async {
  final commander = Commander(level: Level.verbose);
  print('Hello World !');

  final board = commander.board();

  board.createScreen(Screen.page, title: 'Page 1', actions: [
    BoardAction([KeyStroke.control(ControlCharacter.escape)], (screen, output) {
      final homeScreen = screen.screens.get(Screen.home);

      screen.leave();
      homeScreen.enter();
    }),
    BoardAction([KeyStroke.control(ControlCharacter.arrowUp)], (screen, output) {
      print('Up');
    }),
    BoardAction([KeyStroke.control(ControlCharacter.arrowDown)], (screen, output) {
      print('Down');
    }),
  ]);

  int count = 0;
  void Function() update(BoardHeaderItem item) {
    final timer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
      item.text = 'Count: ${count++}';
    });

    return () => timer.cancel();
  }

  final home = board.createScreen(Screen.home,
      title: 'Coucou',
      header: BoardHeader(columns: [
        BoardHeaderColumn(header: [
          BoardHeaderItem(
              label: 'Context: ',
              text: 'oomade-dev',
              labelFormatter: firstColumnLabelFormatter,
              textFormatter: firstColumnTextFormatter),
          BoardHeaderItem(
              label: 'Cluster: ',
              text: 'oomade-dev',
              labelFormatter: firstColumnLabelFormatter,
              textFormatter: firstColumnTextFormatter),
          BoardHeaderItem(
              label: 'User: ',
              text: 'kubernetes-admin-oomade-dev',
              labelFormatter: firstColumnLabelFormatter,
              textFormatter: firstColumnTextFormatter),
          BoardHeaderItem(
              label: 'K9s Rev: ',
              text: 'v0.27.4',
              labelFormatter: firstColumnLabelFormatter,
              textFormatter: firstColumnTextFormatter),
          BoardHeaderItem(
              label: 'Refresh: ',
              text: count.toString(),
              labelFormatter: firstColumnLabelFormatter,
              textFormatter: firstColumnTextFormatter,
              updater: update),
        ]),
        BoardHeaderColumn(header: [
          BoardHeaderItem(
            label: '<0> ',
            text: 'all',
            labelFormatter: secondColumnLabelFormatter,
            textFormatter: secondColumnTextFormatter,
          ),
          BoardHeaderItem(
            label: '<1> ',
            text: 'staging',
            labelFormatter: secondColumnLabelFormatter,
            textFormatter: secondColumnTextFormatter,
          ),
          BoardHeaderItem(
            label: '<2> ',
            text: 'develop',
            labelFormatter: secondColumnLabelFormatter,
            textFormatter: secondColumnTextFormatter,
          ),
        ]),
      ]),
      actions: [
        BoardAction([KeyStroke.char('0')], (screen, output) async {
          final pageScreen = screen.screens.get(Screen.page);

          screen.leave();
          pageScreen.enter();
        }),
        BoardAction([KeyStroke.char('1')], (screen, output) async {
          output.writeln('Go to staging');
        }),
        BoardAction([KeyStroke.char('2')], (screen, output) async {
          output.writeln('Go to develop');
        }),
      ]);

  home.enter();
}

List<Sequence> firstColumnLabelFormatter(String label) {
  return <Sequence>[
    SetStyles(Style.foreground(Color.fromRGB(246, 150, 29))),
    Print(label),
    SetStyles.reset,
  ];
}

List<Sequence> firstColumnTextFormatter(String label) {
  return <Sequence>[
    SetStyles(Style.foreground(Color.brightWhite)),
    Print(label),
    SetStyles.reset,
  ];
}

List<Sequence> secondColumnLabelFormatter(String label) {
  return <Sequence>[
    SetStyles(Style.foreground(Color.fromRGB(195, 74, 155))),
    Print(label),
    SetStyles.reset,
  ];
}

List<Sequence> secondColumnTextFormatter(String label) {
  return <Sequence>[
    SetStyles(Style.foreground(Color.brightBlack)),
    Print(label),
    SetStyles.reset,
  ];
}
