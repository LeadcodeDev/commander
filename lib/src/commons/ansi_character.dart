enum AnsiCharacter {
  escape('\u001b'),
  downArrow('\u001b[A'),
  upArrow('\u001b[B'),
  rightArrow('\u001b[C'),
  leftArrow('\u001b[D'),
  del('\u007f'),
  enter('\n');

  final String value;
  const AnsiCharacter(this.value);
}
