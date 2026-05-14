import 'dart:async';

import '../geometry/size.dart';
import '../runtime/event.dart';
import '../terminal/terminal.dart';

class TestTerminal implements Terminal {
  Size _size;
  final StreamController<Event> _events = StreamController.broadcast();
  final StringBuffer _output = StringBuffer();
  bool _rawMode = false;
  bool _altScreen = false;
  bool _mouseEnabled = false;
  bool _cursorHidden = false;

  TestTerminal({Size? initialSize})
      : _size = initialSize ?? const Size(80, 24);

  String get output => _output.toString();
  bool get rawMode => _rawMode;
  bool get altScreen => _altScreen;
  bool get mouseEnabled => _mouseEnabled;
  bool get cursorHidden => _cursorHidden;

  void clearOutput() => _output.clear();

  void inject(Event event) => _events.add(event);

  void resize(Size newSize) {
    _size = newSize;
    _events.add(ResizeEvent(newSize));
  }

  @override
  Size get size => _size;

  @override
  Stream<Event> get events => _events.stream;

  @override
  void enterRawMode() => _rawMode = true;
  @override
  void leaveRawMode() => _rawMode = false;
  @override
  void enterAlternateScreen() => _altScreen = true;
  @override
  void leaveAlternateScreen() => _altScreen = false;
  @override
  void hideCursor() => _cursorHidden = true;
  @override
  void showCursor() => _cursorHidden = false;
  @override
  void enableMouse() => _mouseEnabled = true;
  @override
  void disableMouse() => _mouseEnabled = false;
  @override
  void write(String data) => _output.write(data);
  @override
  void moveTo(int x, int y) => _output.write('\x1B[${y + 1};${x + 1}H');
  @override
  Future<void> flush() async {}

  @override
  Future<void> shutdown() async {
    if (!_events.isClosed) await _events.close();
  }
}
