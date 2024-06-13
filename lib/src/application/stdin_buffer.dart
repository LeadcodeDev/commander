import 'dart:async';
import 'dart:io';

class StdinBuffer {
  static final _controller = StreamController<List<int>>.broadcast();

  static void initialize() {
    stdin.listen((data) {
      _controller.add(data);
    });
  }

  static Stream<List<int>> get stream => _controller.stream;
}
