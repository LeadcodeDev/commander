import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../geometry/size.dart';
import '../rendering/ansi_encoder.dart';
import '../runtime/event.dart';
import 'key_decoder.dart';
import 'terminal.dart';

const int _STDIN_FILENO = 0;
const int _NCCS = 20;
const int _TCSAFLUSH = 2;

const int _BRKINT = 0x2;
const int _ICRNL = 0x100;
const int _INPCK = 0x10;
const int _ISTRIP = 0x20;
const int _IXON = 0x200;
const int _OPOST = 0x1;
const int _CS8 = 0x300;
const int _CSIZE = 0x300;
const int _ECHO = 0x8;
const int _ICANON = 0x100;
const int _IEXTEN = 0x400;
const int _ISIG = 0x80;
const int _VMIN = 16;
const int _VTIME = 17;

final class _Termios extends Struct {
  @UnsignedLong()
  external int c_iflag;
  @UnsignedLong()
  external int c_oflag;
  @UnsignedLong()
  external int c_cflag;
  @UnsignedLong()
  external int c_lflag;
  @Array(_NCCS)
  external Array<UnsignedChar> c_cc;
  @UnsignedLong()
  external int c_ispeed;
  @UnsignedLong()
  external int c_ospeed;
}

typedef _TcGetAttrNative = Int32 Function(Int32, Pointer<_Termios>);
typedef _TcSetAttrNative = Int32 Function(Int32, Int32, Pointer<_Termios>);
typedef _TcGetAttrDart = int Function(int, Pointer<_Termios>);
typedef _TcSetAttrDart = int Function(int, int, Pointer<_Termios>);

class UnixTerminal implements Terminal {
  final DynamicLibrary _lib;
  final _TcGetAttrDart _tcgetattr;
  final _TcSetAttrDart _tcsetattr;
  final Pointer<_Termios> _origPtr;

  bool _rawMode = false;
  bool _altScreen = false;
  bool _mouseEnabled = false;
  bool _cursorHidden = false;
  Size _size;

  final StreamController<Event> _events = StreamController.broadcast();
  StreamSubscription<List<int>>? _stdinSub;
  StreamSubscription<ProcessSignal>? _resizeSub;
  StreamSubscription<ProcessSignal>? _intSub;
  StreamSubscription<ProcessSignal>? _termSub;
  final KeyDecoder _decoder = KeyDecoder();
  bool _streamStarted = false;

  UnixTerminal()
      : _lib = Platform.isMacOS
            ? DynamicLibrary.open('/usr/lib/libSystem.dylib')
            : DynamicLibrary.open('libc.so.6'),
        _tcgetattr = (Platform.isMacOS
                ? DynamicLibrary.open('/usr/lib/libSystem.dylib')
                : DynamicLibrary.open('libc.so.6'))
            .lookupFunction<_TcGetAttrNative, _TcGetAttrDart>('tcgetattr'),
        _tcsetattr = (Platform.isMacOS
                ? DynamicLibrary.open('/usr/lib/libSystem.dylib')
                : DynamicLibrary.open('libc.so.6'))
            .lookupFunction<_TcSetAttrNative, _TcSetAttrDart>('tcsetattr'),
        _origPtr = calloc<_Termios>(),
        _size = _querySize() {
    _tcgetattr(_STDIN_FILENO, _origPtr);
  }

  static Size _querySize() {
    try {
      return Size(stdout.terminalColumns, stdout.terminalLines);
    } catch (_) {
      return const Size(80, 24);
    }
  }

  @override
  Size get size => _size;

  @override
  Stream<Event> get events {
    _startStream();
    return _events.stream;
  }

  void _startStream() {
    if (_streamStarted) return;
    _streamStarted = true;
    _stdinSub = stdin.listen((bytes) {
      for (final ev in _decoder.decode(bytes)) {
        _events.add(ev);
      }
    });
    try {
      _resizeSub = ProcessSignal.sigwinch.watch().listen((_) {
        final newSize = _querySize();
        if (newSize != _size) {
          _size = newSize;
          _events.add(ResizeEvent(newSize));
        }
      });
    } catch (_) {}
    _intSub = ProcessSignal.sigint.watch().listen((_) async {
      await shutdown();
      exit(130);
    });
    _termSub = ProcessSignal.sigterm.watch().listen((_) async {
      await shutdown();
      exit(143);
    });
  }

  @override
  void enterRawMode() {
    if (_rawMode) return;
    final orig = _origPtr.ref;
    final newPtr = calloc<_Termios>();
    final n = newPtr.ref;
    n.c_iflag = orig.c_iflag & ~(_BRKINT | _ICRNL | _INPCK | _ISTRIP | _IXON);
    n.c_oflag = orig.c_oflag & ~_OPOST;
    n.c_cflag = (orig.c_cflag & ~_CSIZE) | _CS8;
    n.c_lflag = orig.c_lflag & ~(_ECHO | _ICANON | _IEXTEN | _ISIG);
    for (var i = 0; i < _NCCS; i++) {
      n.c_cc[i] = orig.c_cc[i];
    }
    n.c_cc[_VMIN] = 0;
    n.c_cc[_VTIME] = 1;
    n.c_ispeed = orig.c_ispeed;
    n.c_ospeed = orig.c_ospeed;
    _tcsetattr(_STDIN_FILENO, _TCSAFLUSH, newPtr);
    calloc.free(newPtr);
    stdin.echoMode = false;
    stdin.lineMode = false;
    _rawMode = true;
  }

  @override
  void leaveRawMode() {
    if (!_rawMode) return;
    _tcsetattr(_STDIN_FILENO, _TCSAFLUSH, _origPtr);
    try {
      stdin.echoMode = true;
      stdin.lineMode = true;
    } catch (_) {}
    _rawMode = false;
  }

  @override
  void enterAlternateScreen() {
    if (_altScreen) return;
    stdout.write(AnsiSequences.enterAlt);
    _altScreen = true;
  }

  @override
  void leaveAlternateScreen() {
    if (!_altScreen) return;
    stdout.write(AnsiSequences.leaveAlt);
    _altScreen = false;
  }

  @override
  void hideCursor() {
    if (_cursorHidden) return;
    stdout.write(AnsiSequences.hideCursor);
    _cursorHidden = true;
  }

  @override
  void showCursor() {
    if (!_cursorHidden) return;
    stdout.write(AnsiSequences.showCursor);
    _cursorHidden = false;
  }

  @override
  void enableMouse() {
    if (_mouseEnabled) return;
    stdout.write(AnsiSequences.enableMouse);
    _mouseEnabled = true;
  }

  @override
  void disableMouse() {
    if (!_mouseEnabled) return;
    stdout.write(AnsiSequences.disableMouse);
    _mouseEnabled = false;
  }

  @override
  void write(String data) => stdout.write(data);

  @override
  void moveTo(int x, int y) => stdout.write(AnsiSequences.moveTo(x, y));

  @override
  void setTitle(String title) {
    final safe = title.replaceAll('\x07', '').replaceAll('\x1B', '');
    stdout.write('\x1B]0;$safe\x07');
  }

  @override
  Future<void> flush() => stdout.flush();

  @override
  Future<void> shutdown() async {
    try {
      disableMouse();
      showCursor();
      leaveAlternateScreen();
      leaveRawMode();
      await stdout.flush();
    } catch (_) {}
    await _stdinSub?.cancel();
    await _resizeSub?.cancel();
    await _intSub?.cancel();
    await _termSub?.cancel();
    if (!_events.isClosed) await _events.close();
    try {
      calloc.free(_origPtr);
    } catch (_) {}
  }
}

extension on Uint8List {
  // placeholder for future use
}
