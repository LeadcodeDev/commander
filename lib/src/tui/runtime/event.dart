import '../geometry/size.dart';

sealed class Event {
  const Event();
}

class KeyEvent extends Event {
  final String key;
  final bool ctrl;
  final bool alt;
  final bool shift;
  final List<int> raw;

  const KeyEvent({
    required this.key,
    this.ctrl = false,
    this.alt = false,
    this.shift = false,
    this.raw = const [],
  });

  @override
  String toString() {
    final mods = [
      if (ctrl) 'ctrl',
      if (alt) 'alt',
      if (shift) 'shift',
    ].join('+');
    return mods.isEmpty ? 'Key($key)' : 'Key($mods+$key)';
  }
}

typedef KeyPress = KeyEvent;

class MouseEvent extends Event {
  final int x;
  final int y;
  final MouseButton button;
  final MouseAction action;
  final bool ctrl;
  final bool alt;
  final bool shift;

  const MouseEvent({
    required this.x,
    required this.y,
    required this.button,
    required this.action,
    this.ctrl = false,
    this.alt = false,
    this.shift = false,
  });

  @override
  String toString() => 'Mouse(${button.name}.${action.name} @$x,$y)';
}

enum MouseButton { left, middle, right, none }
enum MouseAction { down, up, move, scrollUp, scrollDown }

class ResizeEvent extends Event {
  final Size newSize;
  const ResizeEvent(this.newSize);

  @override
  String toString() => 'Resize($newSize)';
}

class AsyncResolvedEvent extends Event {
  final Object key;
  const AsyncResolvedEvent(this.key);

  @override
  String toString() => 'AsyncResolved($key)';
}

class TickEvent extends Event {
  final int frame;
  const TickEvent(this.frame);

  @override
  String toString() => 'Tick(#$frame)';
}

class CustomEvent extends Event {
  final Object payload;
  const CustomEvent(this.payload);

  @override
  String toString() => 'Custom($payload)';
}
