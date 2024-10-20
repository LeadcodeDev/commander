
final class AnsiCharacter {
  // ANSI escape sequences for directional arrows
  static AnsiCharacter get escape => AnsiCharacter(['\u001b']);
  static AnsiCharacter get downArrow => AnsiCharacter(['\u001b[B']);
  static AnsiCharacter get upArrow => AnsiCharacter(['\u001b[A']);
  static AnsiCharacter get rightArrow => AnsiCharacter(['\u001b[C']);
  static AnsiCharacter get leftArrow => AnsiCharacter(['\u001b[D']);

  // Sequences for special keys
  static AnsiCharacter get backspace => AnsiCharacter(['\u007f']); // '\u001b[D' est incorrect pour backspace
  static AnsiCharacter get del => AnsiCharacter(['\u001b[3~']);
  static AnsiCharacter get space => AnsiCharacter(['\u0020']);
  static AnsiCharacter get enter => AnsiCharacter(['\x0D', '\x0A']);
  static AnsiCharacter get insert => AnsiCharacter(['\u001b[2~']);
  static AnsiCharacter get home => AnsiCharacter(['\u001b[H']);
  static AnsiCharacter get end => AnsiCharacter(['\u001b[F']);
  static AnsiCharacter get pageUp => AnsiCharacter(['\u001b[5~']);
  static AnsiCharacter get pageDown => AnsiCharacter(['\u001b[6~']);

  // Function keys
  static AnsiCharacter get f1 => AnsiCharacter(['\u001bOP']);
  static AnsiCharacter get f2 => AnsiCharacter(['\u001bOQ']);
  static AnsiCharacter get f3 => AnsiCharacter(['\u001bOR']);
  static AnsiCharacter get f4 => AnsiCharacter(['\u001bOS']);
  static AnsiCharacter get f5 => AnsiCharacter(['\u001b[15~']);
  static AnsiCharacter get f6 => AnsiCharacter(['\u001b[17~']);
  static AnsiCharacter get f7 => AnsiCharacter(['\u001b[18~']);
  static AnsiCharacter get f8 => AnsiCharacter(['\u001b[19~']);
  static AnsiCharacter get f9 => AnsiCharacter(['\u001b[20~']);
  static AnsiCharacter get f10 => AnsiCharacter(['\u001b[21~']);
  static AnsiCharacter get f11 => AnsiCharacter(['\u001b[23~']);
  static AnsiCharacter get f12 => AnsiCharacter(['\u001b[24~']);

  final List<String> values;
  const AnsiCharacter(this.values);

  bool matches(String input) {
    return values.contains(input);
  }
}
