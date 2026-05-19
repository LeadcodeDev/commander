import 'event.dart';
import 'key.dart';

typedef KeyHandler = bool Function(KeyEvent event);

class _Scope {
  final Key? id;
  final List<Key> order = [];
  final Set<Key> seen = {};
  final Map<Key, KeyHandler> handlers = {};
  Key? current;
  Key? savedOnEnter;

  _Scope(this.id, this.savedOnEnter);
}

class FocusController {
  final List<_Scope> _stack = [_Scope(null, null)];
  bool _frameInProgress = false;

  _Scope get _active => _stack.last;

  Key? get current => _active.current;

  void resetFrame() {
    _frameInProgress = true;
    for (final s in _stack) {
      s.order.clear();
      s.seen.clear();
      s.handlers.clear();
    }
  }

  void register(Key id, {bool skip = false, KeyHandler? handler}) {
    if (!_frameInProgress) return;
    final scope = _active;
    if (skip) return;
    if (scope.seen.add(id)) {
      scope.order.add(id);
    }
    if (handler != null) {
      scope.handlers[id] = handler;
    }
  }

  void finalizeFrame() {
    _frameInProgress = false;
    for (final s in _stack) {
      if (s.current != null && !s.seen.contains(s.current)) {
        s.current = s.order.isNotEmpty ? s.order.first : null;
      } else if (s.current == null && s.order.isNotEmpty) {
        s.current = s.order.first;
      }
    }
  }

  bool isFocused(Key id) => _active.current == id;

  void focus(Key id) {
    final scope = _active;
    if (scope.seen.isEmpty || scope.seen.contains(id)) {
      scope.current = id;
    }
  }

  void clear() {
    _active.current = null;
  }

  void next() {
    final scope = _active;
    if (scope.order.isEmpty) return;
    final idx =
        scope.current == null ? -1 : scope.order.indexOf(scope.current!);
    final nextIdx = (idx + 1) % scope.order.length;
    scope.current = scope.order[nextIdx];
  }

  void previous() {
    final scope = _active;
    if (scope.order.isEmpty) return;
    final idx = scope.current == null ? 0 : scope.order.indexOf(scope.current!);
    final prevIdx = (idx - 1 + scope.order.length) % scope.order.length;
    scope.current = scope.order[prevIdx];
  }

  void pushScope(Key id) {
    final parent = _active;
    _stack.add(_Scope(id, parent.current));
  }

  void popScope() {
    if (_stack.length <= 1) return;
    _stack.removeLast();
  }

  Key? scopeId() => _active.id;

  int get scopeDepth => _stack.length - 1;

  bool contains(Key id) {
    for (final s in _stack) {
      if (s.seen.contains(id)) return true;
    }
    return false;
  }

  bool dispatchKey(KeyEvent event) {
    final scope = _active;
    final cur = scope.current;
    if (cur == null) return false;
    final handler = scope.handlers[cur];
    if (handler == null) return false;
    return handler(event);
  }
}
