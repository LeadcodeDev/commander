import 'dart:io';
import 'dart:math';

import 'package:commander_ui/src/application/utils/terminal_tools.dart';
import 'package:commander_ui/src/domains/models/component.dart';
import 'package:mansion/mansion.dart';

final class Table with TerminalTools implements Component<void> {
  final List<List<String>> data;
  final List<String> columns;
  final bool lineSeparator;
  final bool columnSeparator;

  /// Creates a new instance of [Table].
  Table({
    this.data = const [],
    this.columns = const [],
    this.lineSeparator = false,
    this.columnSeparator = false,
  });

  @override
  void handle() {
    _render();
  }

  void _render() async {
    saveCursorPosition();

    final buffer = StringBuffer();

    _drawLineSeparator(buffer,
        left: '┌',
        middle: columnSeparator ? '┬' : '─',
        right: '┐',
        separator: '─');
    _drawHeader(buffer);
    _drawLineSeparator(buffer,
        left: '├',
        middle: columnSeparator ? '┼' : '─',
        right: '┤',
        separator: '─');

    for (var row in data) {
      final currentIndex = data.indexOf(row);
      _drawLine(buffer, currentIndex, row);
    }

    _drawLineSeparator(buffer,
        left: '└',
        middle: columnSeparator ? '┴' : '─',
        right: '┘',
        separator: '─');

    clearFromCursorToEnd();
    restoreCursorPosition();
    saveCursorPosition();

    stdout.write(buffer.toString());
  }

  List<int> getMaxCellWidths() {
    final List combined = [...columns, ...data];
    return List.generate(columns.length, (col) {
      int maxWidth = 0;
      for (var row in combined) {
        if (row is List<String>) {
          for (final cell in row) {
            maxWidth = max(maxWidth, cell.length);
          }
        }

        if (row is String) {
          maxWidth = max(maxWidth, row.length);
        }
      }
      return maxWidth;
    });
  }

  void _drawLineSeparator(
      StringBuffer buffer, {
        required String left,
        required String middle,
        required String right,
        required String separator,
      }) {
    final maxColWidths = getMaxCellWidths();

    String line = left;
    for (int i = 0; i < maxColWidths.length; i++) {
      final isLast = i == maxColWidths.length - 1;

      line += separator * (maxColWidths[i] + 2);
      line += isLast ? right : middle;
    }

    buffer.writeln(line);
  }

  void _drawHeader(StringBuffer buffer) {
    final maxColWidths = getMaxCellWidths();
    final headerBuffer = StringBuffer();

    headerBuffer.write('│');

    for (var i = 0; i < columns.length; i++) {
      headerBuffer.writeAnsiAll([
        SetStyles(Style.bold),
        Print(' ${columns[i].padRight(maxColWidths[i])}'),
        SetStyles.reset,
      ]);

      if (i == columns.length - 1) {
        headerBuffer.writeAnsi(Print(' │'));
      } else {
        headerBuffer.writeAnsi(Print(columnSeparator ? ' │' : '  '));
      }
    }

    buffer.writeln(headerBuffer.toString());
  }

  void _drawLine(StringBuffer buffer, int currentIndex, List<String> row) {
    final maxColWidths = getMaxCellWidths();

    if (![0, data.length].contains(currentIndex) && lineSeparator) {
      _drawLineSeparator(buffer,
          left: '├',
          middle: lineSeparator
              ? columnSeparator
              ? '┼'
              : '─'
              : '┼',
          right: '┤',
          separator: '─');
    }

    String rowLine = '│';
    for (var i = 0; i < columns.length; i++) {
      rowLine += ' ${row[i].padRight(maxColWidths[i])}';

      if (i == columns.length - 1) {
        // headerBuffer.writeAnsi(Print(' │'));
        rowLine += ' │';
      } else {
        // headerBuffer.writeAnsi(Print(columnSeparator ? ' │' : '  '));
        rowLine += columnSeparator ? ' │' : '  ';
      }
    }

    buffer.writeln(rowLine);
  }
}
