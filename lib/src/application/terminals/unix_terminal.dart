import 'dart:ffi';
import 'dart:io';

import 'package:commander_ui/src/application/ffi/control_mode.dart';
import 'package:commander_ui/src/application/ffi/local_mode.dart';
import 'package:commander_ui/src/application/ffi/output_mode.dart';
import 'package:commander_ui/src/application/ffi/input_mode.dart';
import 'package:ffi/ffi.dart';
import 'package:commander_ui/src/application/terminals/terminal.dart';

class UnixTerminal implements Terminal {
  late final DynamicLibrary _lib;
  late final Pointer<TermIOS> _origTermIOSPointer;
  late final TCGetAttrDart _tcGetAttr;
  late final TCSetAttrDart _tcSetAttr;

  UnixTerminal() {
    _lib = Platform.isMacOS
        ? DynamicLibrary.open('/usr/lib/libSystem.dylib')
        : DynamicLibrary.open('libc.so.6');

    _tcGetAttr =
        _lib.lookupFunction<TCGetAttrNative, TCGetAttrDart>('tcgetattr');
    _tcSetAttr =
        _lib.lookupFunction<TCSetAttrNative, TCSetAttrDart>('tcsetattr');

    _origTermIOSPointer = calloc<TermIOS>();
    _tcGetAttr(_STDIN_FILENO, _origTermIOSPointer);
  }

  @override
  void enableRawMode() {
    final origTermIOS = _origTermIOSPointer.ref;
    final newTermIOSPointer = calloc<TermIOS>()
      ..ref.c_iflag = origTermIOS.c_iflag &
          ~(InputMode.BRKINT |
              InputMode.ICRNL |
              InputMode.INPCK |
              InputMode.ISTRIP |
              InputMode.IXON)
      ..ref.c_oflag = origTermIOS.c_oflag & ~OutputMode.OPOST
      ..ref.c_cflag =
          (origTermIOS.c_cflag & ~ControlMode.cSize) | ControlMode.cS8
      ..ref.c_lflag = origTermIOS.c_lflag &
          ~(LocalMode.ECHO |
              LocalMode.ICANON |
              LocalMode.IEXTEN |
              LocalMode.ISIG)
      ..ref.c_cc = origTermIOS.c_cc
      ..ref.c_cc[LocalMode.VMIN] = 0
      ..ref.c_cc[LocalMode.VTIME] = 1
      ..ref.c_ispeed = origTermIOS.c_ispeed
      ..ref.c_oflag = origTermIOS.c_ospeed;

    _tcSetAttr(_STDIN_FILENO, LocalMode.TCSANOW, newTermIOSPointer);
    calloc.free(newTermIOSPointer);
  }

  @override
  void disableRawMode() {
    if (nullptr == _origTermIOSPointer.cast()) return;
    _tcSetAttr(_STDIN_FILENO, LocalMode.TCSANOW, _origTermIOSPointer);
  }

  @override
  (int, int) getCursorPosition() {
    stdout.write('\x1B[6n');

    final input = <int>[];
    int char = 0;

    while (char != 82) {
      char = stdin.readByteSync();
      input.add(char);
    }

    String response = String.fromCharCodes(input);
    RegExp regExp = RegExp(r'\[(\d+);(\d+)R');
    Match? match = regExp.firstMatch(response);

    if (match != null) {
      int row = int.parse(match.group(1)!);
      int col = int.parse(match.group(2)!);

      return (col, row);
    } else {
      throw Exception(
          'Impossible d\'extraire la position du curseur $input ${response.split('').map((a) => a).toList()} ${match?.group(1)}/${match?.group(2)}');
    }
  }
}

typedef tcflag_t = UnsignedLong;
typedef cc_t = UnsignedChar;
typedef speed_t = UnsignedLong;

// The default standard input file descriptor number which is 0.
const _STDIN_FILENO = 0;

// The number of elements in the control chars array.
const _NCSS = 20;

final class TermIOS extends Struct {
  @tcflag_t()
  external int c_iflag; // input flags
  @tcflag_t()
  external int c_oflag; // output flags
  @tcflag_t()
  external int c_cflag; // control flags
  @tcflag_t()
  external int c_lflag; // local flags
  @Array(_NCSS)
  external Array<cc_t> c_cc; // control chars
  @speed_t()
  external int c_ispeed; // input speed
  @speed_t()
  external int c_ospeed; // output speed
}

// int tcgetattr(int, struct termios *);
typedef TCGetAttrNative = Int32 Function(
  Int32 fildes,
  Pointer<TermIOS> termios,
);
typedef TCGetAttrDart = int Function(int fildes, Pointer<TermIOS> termios);

// int tcsetattr(int, int, const struct termios *);
typedef TCSetAttrNative = Int32 Function(
  Int32 fildes,
  Int32 optional_actions,
  Pointer<TermIOS> termios,
);
typedef TCSetAttrDart = int Function(
  int fildes,
  int optional_actions,
  Pointer<TermIOS> termios,
);
