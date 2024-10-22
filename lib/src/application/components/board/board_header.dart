import 'package:commander_ui/src/application/components/board/board_header_column.dart';

final class BoardHeader {
  final List<BoardHeaderColumn> _columns;

  int get columnLength => _columns.length;

  BoardHeader({List<BoardHeaderColumn> columns = const []}) : _columns = columns;

  BoardHeaderColumn getColumnAt(int index) => _columns[index];

  BoardHeaderColumn? getPreviousColumn(int index) => index > 0 ? _columns[index - 1] : null;

  int get maxColumnLength => _columns.isNotEmpty
      ? _columns
          .reduce((value, element) => value.itemCount > element.itemCount ? value : element)
          .itemCount
      : 0;
}
