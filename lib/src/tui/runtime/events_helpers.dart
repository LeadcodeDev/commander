import 'dart:async';

import 'event.dart';

class Events {
  static Stream<Event> tick(Duration interval) {
    var i = 0;
    final controller = StreamController<Event>();
    Timer? timer;
    controller.onListen = () {
      timer = Timer.periodic(interval, (_) {
        controller.add(TickEvent(++i));
      });
    };
    controller.onCancel = () {
      timer?.cancel();
    };
    return controller.stream;
  }

  static Stream<Event> custom<T>(Stream<T> source) =>
      source.map((v) => CustomEvent(v as Object));
}
