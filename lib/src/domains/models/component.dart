import 'dart:async';

abstract interface class Component<T> {
  FutureOr<T> handle();
}
