import '../geometry/rect.dart';
import '../rendering/buffer.dart';
import '../runtime/key.dart';
import '../runtime/event.dart';
import '../runtime/render_context.dart';

abstract interface class Widget {
  void render(Rect area, Buffer buffer, RenderContext ctx);
}

abstract interface class FocusableWidget implements Widget {
  Key get id;
  bool onKey(KeyEvent event, RenderContext ctx);
  bool get isSkipped => false;
  void registerHitZones(Rect area, HitZoneSink sink) {
    sink.add(area, id);
  }
}

abstract interface class HitZoneSink {
  void add(Rect area, Key key);
}
