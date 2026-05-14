enum BorderStyle {
  none,
  ascii,
  single,
  double,
  rounded,
  thick;

  BorderChars get chars => switch (this) {
        BorderStyle.none => const BorderChars(
            ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '),
        BorderStyle.ascii => const BorderChars(
            '+', '+', '+', '+', '-', '-', '|', '|'),
        BorderStyle.single => const BorderChars(
            '┌', '┐', '└', '┘', '─', '─', '│', '│'),
        BorderStyle.double => const BorderChars(
            '╔', '╗', '╚', '╝', '═', '═', '║', '║'),
        BorderStyle.rounded => const BorderChars(
            '╭', '╮', '╰', '╯', '─', '─', '│', '│'),
        BorderStyle.thick => const BorderChars(
            '┏', '┓', '┗', '┛', '━', '━', '┃', '┃'),
      };
}

class BorderChars {
  final String topLeft;
  final String topRight;
  final String bottomLeft;
  final String bottomRight;
  final String top;
  final String bottom;
  final String left;
  final String right;

  const BorderChars(
    this.topLeft,
    this.topRight,
    this.bottomLeft,
    this.bottomRight,
    this.top,
    this.bottom,
    this.left,
    this.right,
  );
}

enum BorderSides {
  all,
  none,
  topBottom,
  leftRight;

  bool get hasTop => this == all || this == topBottom;
  bool get hasBottom => this == all || this == topBottom;
  bool get hasLeft => this == all || this == leftRight;
  bool get hasRight => this == all || this == leftRight;
}
