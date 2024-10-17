import 'dart:async';
import 'dart:io';

class StdinBuffer {
  static bool isInitialized = false;
  static final _controller = StreamController<List<int>>.broadcast();

  static void initialize() {
    if (isInitialized) {
      return;
    }

    isInitialized = true;
    stdin.listen((data) {
      _controller.add(data);
    });
  }

  static Stream<List<int>> get stream => _controller.stream;
}
