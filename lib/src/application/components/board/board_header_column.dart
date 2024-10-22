import 'package:commander_ui/src/application/components/board/board_header_item.dart';

final class BoardHeaderColumn {
  final List<BoardHeaderItem> header;
  final int headerSpace;

  int get itemCount => header.length;

  int get maxLabelLength => header
      .map((e) => e.label.length)
      .reduce((a, b) => a > b ? a : b);

  const BoardHeaderColumn({this.header = const [], this.headerSpace = 10});
}
