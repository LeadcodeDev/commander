class Size {
  final int width;
  final int height;

  const Size(this.width, this.height);

  const Size.zero()
      : width = 0,
        height = 0;

  int get area => width * height;
  bool get isEmpty => width <= 0 || height <= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Size && other.width == width && other.height == height);

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'Size($width×$height)';
}
