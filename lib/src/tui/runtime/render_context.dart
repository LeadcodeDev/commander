import '../geometry/rect.dart';
import '../rendering/buffer.dart';
import '../style/color.dart';
import '../style/style.dart';
import '../theme/theme_data.dart';
import '../widget/widget.dart';
import 'async_registry.dart';
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
  final void Function() exit;

  final _HitZoneCollector _hitZones = _HitZoneCollector();
  final List<({Widget widget, Rect area})> _overlays = [];
  final Set<Key> _seenFocusables = <Key>{};
  String? _pendingTitle;
  int _maxDesiredHeight = 0;

  RenderContext({
    required this.buffer,
    required this.area,
    required this.theme,
    required this.focus,
    required this.async_,
    required this.logger,
    required this.requestRedraw,
    this.exit = _noop,
  });

  static void _noop() {}

  List<({Rect rect, Key key})> get hitZones => _hitZones.zones;
  List<({Widget widget, Rect area})> get overlays =>
      List.unmodifiable(_overlays);
  String? get pendingTitle => _pendingTitle;
  int get maxDesiredHeight => _maxDesiredHeight;

  void setTitle(String title) {
    _pendingTitle = title;
  }

  bool isFocused(Key id) => focus.isFocused(id);

  void resetFrame() {
    _hitZones.clear();
    _overlays.clear();
    _seenFocusables.clear();
    _pendingTitle = null;
    _maxDesiredHeight = 0;
  }

  @override
  void add(Rect rect, Key key) => _hitZones.add(rect, key);

  void draw(Widget widget, Rect target) {
    assert(
        target.width >= 0 && target.height >= 0,
        'RenderContext.draw: target rect must have non-negative size '
        '(got ${target.width}x${target.height})');
    if (target.bottom > _maxDesiredHeight) {
      _maxDesiredHeight = target.bottom;
    }
    final clipped = target.intersect(buffer.area);
    if (clipped.isEmpty) return;
    if (widget is FocusableWidget) {
      if (widget.isSkipped) {
        if (focus.current == widget.id) {
          focus.clear();
        }
      } else {
        assert(
            _seenFocusables.add(widget.id),
            'Duplicate FocusableWidget id in same frame: ${widget.id}. '
            'Each focusable widget must have a unique Key per frame.');
        focus.register(
          widget.id,
          handler: (event) {
            try {
              return widget.onKey(event, this);
            } catch (e, st) {
              logger.error('widget.onKey threw', error: e, stack: st);
              return false;
            }
          },
        );
        if (focus.current == null) {
          focus.focus(widget.id);
        }
        try {
          widget.registerHitZones(clipped, this);
        } catch (e, st) {
          logger.error('widget.registerHitZones threw', error: e, stack: st);
        }
      }
    }
    try {
      widget.render(clipped, buffer, this);
    } catch (e, st) {
      logger.error('widget.render threw', error: e, stack: st);
      _drawErrorBoundary(clipped, e);
    }
  }

  void _drawErrorBoundary(Rect area, Object error) {
    if (area.isEmpty) return;
    final msg = '[render error: $error]';
    final truncated =
        msg.length > area.width ? msg.substring(0, area.width) : msg;
    buffer.writeText(area.x, area.y, truncated,
        style: const Style(bg: Color.red, fg: Color.white, bold: true),
        maxWidth: area.width);
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
