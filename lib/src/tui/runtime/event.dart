import '../geometry/size.dart';

sealed class Event {
  const Event();
}

enum NamedKey {
  enter,
  escape,
  tab,
  backspace,
  delete,
  insert,
  arrowUp,
  arrowDown,
  arrowLeft,
  arrowRight,
  home,
  end,
  pageUp,
  pageDown,
  f1,
  f2,
  f3,
  f4,
  f5,
  f6,
  f7,
  f8,
  f9,
  f10,
  f11,
  f12,
  unknown,
}

class KeyEvent extends Event {
  final NamedKey? key;
  final String? char;
  final bool ctrl;
  final bool alt;
  final bool shift;
  final List<int> raw;

  const KeyEvent({
    this.key,
    this.char,
    this.ctrl = false,
    this.alt = false,
    this.shift = false,
    this.raw = const [],
  }) : assert(key != null || char != null,
            'KeyEvent must have either key or char set');

  bool get isNamed => key != null;
  bool get isChar => char != null;

  bool matches(NamedKey named) => key == named;
  bool isChar_(String c) => char == c;

  @override
  String toString() {
    final mods = [
      if (ctrl) 'ctrl',
      if (alt) 'alt',
      if (shift) 'shift',
    ].join('+');
    final label = key?.name ?? char ?? '';
    return mods.isEmpty ? 'Key($label)' : 'Key($mods+$label)';
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
