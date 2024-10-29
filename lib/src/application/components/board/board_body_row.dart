final class BoardBodyRow {
  final List<String> _columns;

  int get itemCount => _columns.length;

  String getColumnAt(int index) => _columns[index];

  int get maxLabelLength => _columns.map((e) => e.length).reduce((a, b) => a > b ? a : b);

  BoardBodyRow({List<String> columns = const []}) : _columns = columns;
}
