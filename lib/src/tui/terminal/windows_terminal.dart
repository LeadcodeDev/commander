import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import '../geometry/size.dart';
import '../rendering/ansi_encoder.dart';
import '../runtime/event.dart';
import 'key_decoder.dart';
import 'terminal.dart';

// Windows console constants.
const int _stdInputHandle = -10;
const int _stdOutputHandle = -11;
const int _enableProcessedInput = 0x0001;
const int _enableLineInput = 0x0002;
const int _enableEchoInput = 0x0004;
const int _enableVirtualTerminalInput = 0x0200;
const int _enableVirtualTerminalProcessing = 0x0004;
const int _disableNewlineAutoReturn = 0x0008;

typedef _GetStdHandleNative = IntPtr Function(Uint32);
typedef _GetStdHandleDart = int Function(int);
typedef _GetConsoleModeNative = Int32 Function(IntPtr, Pointer<Uint32>);
typedef _GetConsoleModeDart = int Function(int, Pointer<Uint32>);
typedef _SetConsoleModeNative = Int32 Function(IntPtr, Uint32);
typedef _SetConsoleModeDart = int Function(int, int);

class _WinConsole {
  final _GetStdHandleDart getStdHandle;
  final _GetConsoleModeDart getConsoleMode;
  final _SetConsoleModeDart setConsoleMode;
  final int hIn;
  final int hOut;
  int? savedInMode;
  int? savedOutMode;

  _WinConsole._(this.getStdHandle, this.getConsoleMode, this.setConsoleMode,
      this.hIn, this.hOut);

  static _WinConsole? open() {
    try {
      final lib = DynamicLibrary.open('kernel32.dll');
      final getStd = lib
          .lookupFunction<_GetStdHandleNative, _GetStdHandleDart>('GetStdHandle');
      final getMode = lib.lookupFunction<_GetConsoleModeNative,
          _GetConsoleModeDart>('GetConsoleMode');
      final setMode = lib.lookupFunction<_SetConsoleModeNative,
          _SetConsoleModeDart>('SetConsoleMode');
      final hIn = getStd(_stdInputHandle);
      final hOut = getStd(_stdOutputHandle);
      return _WinConsole._(getStd, getMode, setMode, hIn, hOut);
    } catch (_) {
      return null;
    }
  }

  int? _readMode(int handle) {
    final ptr = calloc<Uint32>();
    try {
      if (getConsoleMode(handle, ptr) == 0) return null;
      return ptr.value;
    } finally {
      calloc.free(ptr);
    }
  }

  void enableVt() {
    final inMode = _readMode(hIn);
    if (inMode != null) {
      savedInMode = inMode;
      final newIn = (inMode |
              _enableVirtualTerminalInput) &
          ~(_enableLineInput | _enableEchoInput | _enableProcessedInput);
      setConsoleMode(hIn, newIn);
    }
    final outMode = _readMode(hOut);
    if (outMode != null) {
      savedOutMode = outMode;
      final newOut = outMode |
          _enableVirtualTerminalProcessing |
          _disableNewlineAutoReturn;
      setConsoleMode(hOut, newOut);
    }
  }

  void restore() {
    if (savedInMode != null) {
      setConsoleMode(hIn, savedInMode!);
      savedInMode = null;
    }
    if (savedOutMode != null) {
      setConsoleMode(hOut, savedOutMode!);
      savedOutMode = null;
    }
  }
}

class WindowsTerminal implements Terminal {
  Size _size;
  final StreamController<Event> _events = StreamController.broadcast();
  StreamSubscription<List<int>>? _stdinSub;
  final KeyDecoder _decoder = KeyDecoder();
  bool _streamStarted = false;
  bool _rawMode = false;
  bool _altScreen = false;
  bool _mouseEnabled = false;
  bool _cursorHidden = false;
  final _WinConsole? _console;

  WindowsTerminal()
      : _size = _querySize(),
        _console = _WinConsole.open() {
    stdout.write('\x1B[?1049l');
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
  }

  @override
  void enterRawMode() {
    if (_rawMode) return;
    _console?.enableVt();
    try {
      stdin.echoMode = false;
      stdin.lineMode = false;
    } catch (_) {}
    _rawMode = true;
  }

  @override
  void leaveRawMode() {
    if (!_rawMode) return;
    try {
      stdin.echoMode = true;
      stdin.lineMode = true;
    } catch (_) {}
    _console?.restore();
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
  Future<(int, int)> queryCursorPosition({
    Duration timeout = const Duration(milliseconds: 500),
  }) async {
    stdout.write('\x1B[6n');
    try {
      await stdout.flush();
    } catch (_) {}
    final buf = <int>[];
    final sw = Stopwatch()..start();
    while (sw.elapsed < timeout) {
      int b;
      try {
        b = stdin.readByteSync();
      } catch (_) {
        continue;
      }
      if (b < 0) continue;
      buf.add(b);
      if (b == 0x52) break;
    }
    final s = String.fromCharCodes(buf);
    final m = RegExp(r'\[(\d+);(\d+)R').firstMatch(s);
    if (m != null) {
      final row = int.parse(m.group(1)!) - 1;
      final col = int.parse(m.group(2)!) - 1;
      return (col, row);
    }
    return (0, 0);
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
    if (!_events.isClosed) await _events.close();
  }
}
