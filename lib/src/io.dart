export 'package:io/io.dart' show ExitCode;

/// Non-printable characters that can be entered from the keyboard.
///
enum ControlCharacter {
  /// null
  none,

  /// Start of heading
  ctrlA,

  /// Start of text
  ctrlB,

  /// End of text
  ctrlC,

  /// End of xmit/file
  ctrlD,

  /// Enquiry
  ctrlE,

  /// Acknowledge
  ctrlF,

  /// Bell
  ctrlG,

  /// Backspace
  ctrlH,

  /// Horizontal tab
  ctrlI,

  /// Line feed (return)
  ctrlJ,

  /// Vertical tab
  ctrlK,

  /// Form feed
  ctrlL,

  /// Carriage feed (enter)
  ctrlM,

  /// Shift out
  ctrlN,

  /// Shift in
  ctrlO,

  /// Data line escape
  ctrlP,

  /// Device control 1
  ctrlQ,

  /// Device control 2
  ctrlR,

  /// Device control 3
  ctrlS,

  /// Device control 4
  ctrlT,

  /// Neg acknowledge
  ctrlU,

  /// Synchronous idle
  ctrlV,

  /// End of xmit block
  ctrlW,

  /// Cancel
  ctrlX,

  /// End of medium
  ctrlY,

  /// Substitute (suspend)
  ctrlZ,

  /// Left arrow
  arrowLeft,

  /// Right arrow
  arrowRight,

  /// Up arrow
  arrowUp,

  /// Down arrow
  arrowDown,

  /// Page up
  pageUp,

  /// Page down
  pageDown,

  /// Word left
  wordLeft,

  /// Word right
  wordRight,

  /// Home
  home,

  /// End
  end,

  /// Escape
  escape,

  /// Delete
  delete,

  /// Backspace
  backspace,

  /// Word backspace
  wordBackspace,

  /// Function 1
  // ignore: constant_identifier_names
  F1,

  /// Function 2
  // ignore: constant_identifier_names
  F2,

  /// Function 3
  // ignore: constant_identifier_names
  F3,

  /// Function 4
  // ignore: constant_identifier_names
  F4,

  /// Unknown control character
  unknown
}

/// {@template key_stroke}
/// A representation of a keystroke.
/// {@endtemplate}
class KeyStroke {
  /// {@macro key_stroke}
  const KeyStroke({
    this.char = '',
    this.controlChar = ControlCharacter.unknown,
  });

  /// {@macro key_stroke}
  factory KeyStroke.char(String char) {
    assert(char.length == 1, 'characters must be a single unit');
    return KeyStroke(
      char: char,
      controlChar: ControlCharacter.none,
    );
  }

  /// {@macro key_stroke}
  factory KeyStroke.control(ControlCharacter controlChar) {
    return KeyStroke(controlChar: controlChar);
  }

  /// The printable character.
  final String char;

  /// The control character value.
  final ControlCharacter controlChar;
}
