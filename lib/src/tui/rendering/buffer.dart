import '../geometry/rect.dart';
import '../geometry/size.dart';
import '../style/style.dart';
import 'cell.dart';

class Buffer {
  Size _size;
  late List<Cell> _cells;

  Buffer(this._size) {
    _cells = List.filled(_size.area, Cell.empty);
  }

  Size get size => _size;
  int get width => _size.width;
  int get height => _size.height;
  Rect get area => Rect(0, 0, width, height);

  void resize(Size newSize) {
    if (newSize == _size) return;
    _size = newSize;
    _cells = List.filled(newSize.area, Cell.empty);
  }

  void clear([Cell fill = Cell.empty]) {
    for (var i = 0; i < _cells.length; i++) {
      _cells[i] = fill;
    }
  }

  bool _inBounds(int x, int y) =>
      x >= 0 && x < width && y >= 0 && y < height;

  Cell get(int x, int y) {
    if (!_inBounds(x, y)) return Cell.empty;
    return _cells[y * width + x];
  }

  void set(int x, int y, Cell cell) {
    if (!_inBounds(x, y)) return;
    _cells[y * width + x] = cell;
  }

  void setChar(int x, int y, String char, {Style style = Style.none, int width = 1}) {
    if (!_inBounds(x, y)) return;
    _cells[y * this.width + x] = Cell(char: char, style: style, width: width);
    if (width > 1) {
      for (var i = 1; i < width; i++) {
        if (_inBounds(x + i, y)) {
          _cells[y * this.width + x + i] = Cell.continuation;
        }
      }
    }
  }

  void writeText(int x, int y, String text, {Style style = Style.none, int? maxWidth}) {
    if (y < 0 || y >= height) return;
    var cursor = x;
    final limit = maxWidth != null ? x + maxWidth : width;
    final runes = text.runes;
    for (final r in runes) {
      if (cursor >= limit || cursor >= width) break;
      if (r == 10 || r == 13) continue;
      final w = charWidth(r);
      if (w == 0) continue;
      if (cursor + w > limit || cursor + w > width) {
        if (cursor < limit) setChar(cursor, y, ' ', style: style);
        break;
      }
      setChar(cursor, y, String.fromCharCode(r), style: style, width: w);
      cursor += w;
    }
  }

  void fillRect(Rect rect, Cell cell) {
    final clipped = rect.intersect(area);
    if (clipped.isEmpty) return;
    for (var dy = 0; dy < clipped.height; dy++) {
      for (var dx = 0; dx < clipped.width; dx++) {
        set(clipped.x + dx, clipped.y + dy, cell);
      }
    }
  }

  void fillStyle(Rect rect, Style style) {
    final clipped = rect.intersect(area);
    if (clipped.isEmpty) return;
    for (var dy = 0; dy < clipped.height; dy++) {
      for (var dx = 0; dx < clipped.width; dx++) {
        final current = get(clipped.x + dx, clipped.y + dy);
        set(clipped.x + dx, clipped.y + dy,
            current.copyWith(style: style.merge(current.style)));
      }
    }
  }

  String toPlainString() {
    final sb = StringBuffer();
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final cell = get(x, y);
        if (cell.width == 0) continue;
        sb.write(cell.char);
      }
      if (y < height - 1) sb.writeln();
    }
    return sb.toString();
  }
}
