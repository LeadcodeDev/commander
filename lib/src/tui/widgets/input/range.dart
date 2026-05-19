import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

enum RangeHandle { low, high }

class RangeState {
  num low;
  num high;
  RangeHandle active;
  RangeState({this.low = 0, this.high = 100, this.active = RangeHandle.low});
}

class Range implements FocusableWidget, SizedWidget {
  final Key? _id;
  @override
  Key get id => _id ?? ValueKey(state);

  final RangeState state;
  final num min;
  final num max;
  final num step;
  final num? pageStep;
  final void Function(num low, num high)? onChanged;

  final String trackChar;
  final String fillChar;
  final String handleChar;
  final String activeHandleChar;
  final Style? trackStyle;
  final Style? fillStyle;
  final Style? handleStyle;
  final Style? activeHandleStyle;
  final bool showValues;
  final String Function(num value)? formatValue;

  const Range({
    Key? id,
    required this.state,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.pageStep,
    this.onChanged,
    this.trackChar = '─',
    this.fillChar = '━',
    this.handleChar = '○',
    this.activeHandleChar = '●',
    this.trackStyle,
    this.fillStyle,
    this.handleStyle,
    this.activeHandleStyle,
    this.showValues = true,
    this.formatValue,
  })  : _id = id,
        assert(min < max, 'Range min must be < max'),
        assert(step > 0, 'Range step must be > 0');

  @override
  int get height => 1;

  @override
  bool get isSkipped => false;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) => sink.add(area, id);

  num _clamp(num v) => v < min ? min : (v > max ? max : v);

  void _adjust(num delta) {
    if (state.active == RangeHandle.low) {
      final next = _clamp(state.low + delta);
      if (next > state.high) return;
      if (next == state.low) return;
      state.low = next;
    } else {
      final next = _clamp(state.high + delta);
      if (next < state.low) return;
      if (next == state.high) return;
      state.high = next;
    }
    onChanged?.call(state.low, state.high);
  }

  void _toggleActive() {
    state.active =
        state.active == RangeHandle.low ? RangeHandle.high : RangeHandle.low;
  }

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    final big = pageStep ?? ((max - min) / 10);
    switch (event.key) {
      case NamedKey.arrowLeft:
      case NamedKey.arrowDown:
        _adjust(-step);
        return true;
      case NamedKey.arrowRight:
      case NamedKey.arrowUp:
        _adjust(step);
        return true;
      case NamedKey.pageDown:
        _adjust(-big);
        return true;
      case NamedKey.pageUp:
        _adjust(big);
        return true;
      case NamedKey.home:
        if (state.active == RangeHandle.low) {
          if (state.low == min) return true;
          state.low = min;
        } else {
          if (state.high == state.low) return true;
          state.high = state.low;
        }
        onChanged?.call(state.low, state.high);
        return true;
      case NamedKey.end:
        if (state.active == RangeHandle.high) {
          if (state.high == max) return true;
          state.high = max;
        } else {
          if (state.low == state.high) return true;
          state.low = state.high;
        }
        onChanged?.call(state.low, state.high);
        return true;
      case NamedKey.tab:
        _toggleActive();
        return true;
      default:
        if (event.char == ' ') {
          _toggleActive();
          return true;
        }
        return false;
    }
  }

  String _format(num v) {
    if (formatValue != null) return formatValue!(v);
    if (v is int || (v is double && v == v.roundToDouble())) {
      return v.toInt().toString();
    }
    return v.toStringAsFixed(2);
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    final focused = ctx.isFocused(id);

    final label =
        showValues ? ' ${_format(state.low)}–${_format(state.high)}' : '';
    final trackWidth = (area.width - label.length).clamp(1, area.width);
    if (trackWidth <= 0) return;

    final rangeSpan = max - min;
    final lowPos = ((state.low - min) / rangeSpan * (trackWidth - 1))
        .round()
        .clamp(0, trackWidth - 1);
    final highPos = ((state.high - min) / rangeSpan * (trackWidth - 1))
        .round()
        .clamp(0, trackWidth - 1);

    final track = trackStyle ?? Style(fg: ctx.theme.colors.muted);
    final fill = fillStyle ?? Style(fg: ctx.theme.colors.primary);
    final defaultHandle = Style(
      fg: focused ? ctx.theme.colors.primary : ctx.theme.colors.foreground,
    );
    final defaultActive = Style(
      fg: ctx.theme.colors.primary,
      bold: true,
    );
    final h = handleStyle ?? defaultHandle;
    final ah = activeHandleStyle ?? defaultActive;

    for (var i = 0; i < trackWidth; i++) {
      String ch;
      Style s;
      if (i == lowPos) {
        ch = state.active == RangeHandle.low && focused
            ? activeHandleChar
            : handleChar;
        s = state.active == RangeHandle.low && focused ? ah : h;
      } else if (i == highPos) {
        ch = state.active == RangeHandle.high && focused
            ? activeHandleChar
            : handleChar;
        s = state.active == RangeHandle.high && focused ? ah : h;
      } else if (i > lowPos && i < highPos) {
        ch = fillChar;
        s = fill;
      } else {
        ch = trackChar;
        s = track;
      }
      buffer.setChar(area.x + i, area.y, ch, style: s);
    }

    if (label.isNotEmpty) {
      buffer.writeText(area.x + trackWidth, area.y, label,
          style: ctx.theme.text.body, maxWidth: label.length);
    }
  }
}
