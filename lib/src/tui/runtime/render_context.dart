import '../geometry/rect.dart';
import '../rendering/buffer.dart';
import '../theme/theme_data.dart';
import '../widget/widget.dart';
import 'async_registry.dart';
import 'event.dart';
import 'focus_controller.dart';
import 'key.dart';
import 'logger.dart';

class _HitZoneCollector implements HitZoneSink {
  final List<({Rect rect, Key key})> zones = [];

  @override
  void add(Rect rect, Key key) {
    zones.add((rect: rect, key: key));
  }

  void clear() => zones.clear();
}

class RenderContext implements HitZoneSink {
  final Buffer buffer;
  final Rect area;
  final ThemeData theme;
  final FocusController focus;
  final AsyncRegistry async_;
  final CommanderLogger logger;
  final void Function() requestRedraw;

  final _HitZoneCollector _hitZones = _HitZoneCollector();
  final List<({Widget widget, Rect area})> _overlays = [];

  RenderContext({
    required this.buffer,
    required this.area,
    required this.theme,
    required this.focus,
    required this.async_,
    required this.logger,
    required this.requestRedraw,
  });

  List<({Rect rect, Key key})> get hitZones => _hitZones.zones;
  List<({Widget widget, Rect area})> get overlays =>
      List.unmodifiable(_overlays);

  bool isFocused(Key id) => focus.isFocused(id);

  void resetFrame() {
    _hitZones.clear();
    _overlays.clear();
  }

  @override
  void add(Rect rect, Key key) => _hitZones.add(rect, key);

  void draw(Widget widget, Rect target) {
    final clipped = target.intersect(buffer.area);
    if (clipped.isEmpty) return;
    if (widget is FocusableWidget && !widget.isSkipped) {
      focus.register(
        widget.id,
        handler: (event) => widget.onKey(event, this),
      );
      widget.registerHitZones(clipped, this);
    }
    widget.render(clipped, buffer, this);
  }

  void drawOverlay(Widget widget, Rect target) {
    final clipped = target.intersect(buffer.area);
    if (clipped.isEmpty) return;
    _overlays.add((widget: widget, area: clipped));
  }

  void flushOverlays() {
    if (_overlays.isEmpty) return;
    final batch = List.of(_overlays);
    _overlays.clear();
    for (final o in batch) {
      draw(o.widget, o.area);
    }
  }

  void scope(Key id, void Function() drawScope) {
    focus.pushScope(id);
    try {
      drawScope();
    } finally {
      focus.popScope();
    }
  }
}
