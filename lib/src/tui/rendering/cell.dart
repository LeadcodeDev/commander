import '../style/style.dart';

class Cell {
  final String char;
  final Style style;
  final int width;

  const Cell({this.char = ' ', this.style = Style.none, this.width = 1})
      : assert(width >= 0 && width <= 2,
            'Cell width must be 0 (continuation), 1, or 2'),
        assert(width != 0 || char == '',
            'Continuation cells must have empty char');

  static const Cell empty = Cell();

  static const Cell continuation = Cell(char: '', width: 0);

  Cell copyWith({String? char, Style? style, int? width}) => Cell(
        char: char ?? this.char,
        style: style ?? this.style,
        width: width ?? this.width,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cell &&
          other.char == char &&
          other.style == style &&
          other.width == width);

  @override
  int get hashCode => Object.hash(char, style, width);
}

int charWidth(int codePoint) {
  if (codePoint == 0) return 0;
  if (codePoint < 0x20 || (codePoint >= 0x7F && codePoint < 0xA0)) return 0;
  if (codePoint >= 0x1100 &&
      (codePoint <= 0x115F ||
          codePoint == 0x2329 ||
          codePoint == 0x232A ||
          (codePoint >= 0x2E80 && codePoint <= 0xA4CF && codePoint != 0x303F) ||
          (codePoint >= 0xAC00 && codePoint <= 0xD7A3) ||
          (codePoint >= 0xF900 && codePoint <= 0xFAFF) ||
          (codePoint >= 0xFE30 && codePoint <= 0xFE4F) ||
          (codePoint >= 0xFF00 && codePoint <= 0xFF60) ||
          (codePoint >= 0xFFE0 && codePoint <= 0xFFE6) ||
          (codePoint >= 0x20000 && codePoint <= 0x2FFFD) ||
          (codePoint >= 0x30000 && codePoint <= 0x3FFFD))) {
    return 2;
  }
  if (codePoint >= 0x1F300 && codePoint <= 0x1FAFF) return 2;
  return 1;
}
