import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:commander_ui/src/domain/models/terminal.dart';
import 'package:commander_ui/src/infrastructure/models/control_mode.dart';
import 'package:commander_ui/src/infrastructure/models/input_mode.dart';
import 'package:commander_ui/src/infrastructure/models/local_mode.dart';
import 'package:ffi/ffi.dart';

class UnixTerminal implements Terminal {
  final _streamController = StreamController<List<int>>.broadcast();

  @override
  Stream<List<int>> get stream => _streamController.stream;

  late final DynamicLibrary _lib;
  late final Pointer<TermIOS> _origTermIOSPointer;
  late final TCGetAttrDart _tcgetattr;
  late final TCSetAttrDart _tcsetattr;

  UnixTerminal() {
    _lib = Platform.isMacOS
        ? DynamicLibrary.open('/usr/lib/libSystem.dylib')
        : DynamicLibrary.open('libc.so.6');

    _tcgetattr = _lib.lookupFunction<TCGetAttrNative, TCGetAttrDart>(
      'tcgetattr',
    );
    _tcsetattr = _lib.lookupFunction<TCSetAttrNative, TCSetAttrDart>(
      'tcsetattr',
    );

    _origTermIOSPointer = calloc<TermIOS>();
    _tcgetattr(_STDIN_FILENO, _origTermIOSPointer);

    stdin.listen(_streamController.add);
  }

  @override
  void enableRawMode() {
    final origTermIOS = _origTermIOSPointer.ref;
    final newTermIOSPointer = calloc<TermIOS>()
      ..ref.c_iflag = origTermIOS.c_iflag &
          ~(InputMode.brkint.value |
              InputMode.icrnl.value |
              InputMode.inpck.value |
              InputMode.istrip.value |
              InputMode.ixon.value)
      ..ref.c_oflag = origTermIOS.c_oflag & ~_OPOST
      ..ref.c_cflag = (origTermIOS.c_cflag & ~ControlMode.csize.value) | ControlMode.cs8.value
      ..ref.c_lflag = origTermIOS.c_lflag &
          ~(LocalMode.echo.value |
              LocalMode.icanon.value |
              LocalMode.iexten.value |
              LocalMode.isig.value)
      ..ref.c_cc = origTermIOS.c_cc
      ..ref.c_cc[LocalMode.vmin.value] = 0
      ..ref.c_cc[LocalMode.vtime.value] = 1
      ..ref.c_ispeed = origTermIOS.c_ispeed
      ..ref.c_oflag = origTermIOS.c_ospeed;

    _tcsetattr(_STDIN_FILENO, LocalMode.tcsanow.value, newTermIOSPointer);
    calloc.free(newTermIOSPointer);
  }

  @override
  void disableRawMode() {
    if (nullptr == _origTermIOSPointer.cast()) return;
    _tcsetattr(_STDIN_FILENO, LocalMode.tcsanow.value, _origTermIOSPointer);
  }
}

const int _OPOST = 0x00000001;

typedef tcflag_t = UnsignedLong;
typedef cc_t = UnsignedChar;
typedef speed_t = UnsignedLong;

// The default standard input file descriptor number which is 0.
const _STDIN_FILENO = 0;

// The number of elements in the control chars array.
const _NCSS = 20;

final class TermIOS extends Struct {
  @tcflag_t()
  external int c_iflag;

  @tcflag_t()
  external int c_oflag;

  @tcflag_t()
  external int c_cflag;

  @tcflag_t()
  external int c_lflag;

  @Array(_NCSS)
  external Array<cc_t> c_cc;

  @speed_t()
  external int c_ispeed;

  @speed_t()
  external int c_ospeed;
}

typedef TCGetAttrNative = Int32 Function(
  Int32 fildes,
  Pointer<TermIOS> termios,
);

typedef TCGetAttrDart = int Function(int fildes, Pointer<TermIOS> termios);

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
