import 'package:commander_ui/src/application/components/board/board_body_row.dart';

final class BoardBody {
  final List<String> header;
  final List<BoardBodyRow> _rows;

  int get rowLength => _rows.length;

  BoardBody({this.header = const [], List<BoardBodyRow> rows = const []}) : _rows = rows;

  BoardBodyRow getRowAt(int index) => _rows[index];

  BoardBodyRow? getPreviousRow(int index) => index > 0 ? _rows[index - 1] : null;

  int get maxColumnLength => _rows.isNotEmpty
      ? _rows
          .reduce((value, element) => value.itemCount > element.itemCount ? value : element)
          .itemCount
      : 0;
}
