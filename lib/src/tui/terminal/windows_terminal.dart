import 'dart:async';
import 'dart:io';

import '../geometry/size.dart';
import '../rendering/ansi_encoder.dart';
import '../runtime/event.dart';
import 'key_decoder.dart';
import 'terminal.dart';

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

  WindowsTerminal() : _size = _querySize() {
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
