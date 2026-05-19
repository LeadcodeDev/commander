import 'dart:async';

class TuiNavigator<R> {
  final List<R> _stack;
  final StreamController<void> _changes = StreamController.broadcast();

  TuiNavigator({required R initial}) : _stack = [initial];

  R get current => _stack.last;
  List<R> get history => List.unmodifiable(_stack);
  int get depth => _stack.length;
  Stream<void> get onChange => _changes.stream;

  void push(R route) {
    _stack.add(route);
    _changes.add(null);
  }

  R? pop() {
    if (_stack.length <= 1) return null;
    final out = _stack.removeLast();
    _changes.add(null);
    return out;
  }

  void replace(R route) {
    _stack.removeLast();
    _stack.add(route);
    _changes.add(null);
  }

  void reset(R route) {
    _stack
      ..clear()
      ..add(route);
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}
