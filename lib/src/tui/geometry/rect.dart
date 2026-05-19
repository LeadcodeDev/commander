class Rect {
  final int x;
  final int y;
  final int width;
  final int height;

  const Rect(this.x, this.y, this.width, this.height);

  const Rect.zero()
      : x = 0,
        y = 0,
        width = 0,
        height = 0;

  int get right => x + width;
  int get bottom => y + height;
  int get left => x;
  int get top => y;
  int get area => width * height;
  bool get isEmpty => width <= 0 || height <= 0;

  bool contains(int px, int py) =>
      px >= x && px < right && py >= y && py < bottom;

  Rect intersect(Rect other) {
    final nx = x > other.x ? x : other.x;
    final ny = y > other.y ? y : other.y;
    final nr = right < other.right ? right : other.right;
    final nb = bottom < other.bottom ? bottom : other.bottom;

    if (nr <= nx || nb <= ny) return const Rect.zero();
    return Rect(nx, ny, nr - nx, nb - ny);
  }

  Rect inset({int top = 0, int right = 0, int bottom = 0, int left = 0}) {
    final w = width - left - right;
    final h = height - top - bottom;

    if (w <= 0 || h <= 0) return Rect(x + left, y + top, 0, 0);
    return Rect(x + left, y + top, w, h);
  }

  Rect insetAll(int v) => inset(top: v, right: v, bottom: v, left: v);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Rect &&
          other.x == x &&
          other.y == y &&
          other.width == width &&
          other.height == height);

  @override
  int get hashCode => Object.hash(x, y, width, height);

  @override
  String toString() => 'Rect($x, $y, $width×$height)';
}
