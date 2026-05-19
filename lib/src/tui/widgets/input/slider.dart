import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

class SliderState {
  num value;
  SliderState({this.value = 0});
}

class Slider implements FocusableWidget, SizedWidget {
  final Key? _id;
  @override
  Key get id => _id ?? ValueKey(state);

  final SliderState state;
  final num min;
  final num max;
  final num step;
  final num? pageStep;
  final void Function(num value)? onChanged;

  final String trackChar;
  final String fillChar;
  final String handleChar;
  final Style? trackStyle;
  final Style? fillStyle;
  final Style? handleStyle;
  final bool showValue;
  final String Function(num value)? formatValue;

  const Slider({
    Key? id,
    required this.state,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.pageStep,
    this.onChanged,
    this.trackChar = '─',
    this.fillChar = '━',
    this.handleChar = '●',
    this.trackStyle,
    this.fillStyle,
    this.handleStyle,
    this.showValue = true,
    this.formatValue,
  })  : _id = id,
        assert(min < max, 'Slider min must be < max'),
        assert(step > 0, 'Slider step must be > 0');

  @override
  int get height => 1;

  @override
  bool get isSkipped => false;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) => sink.add(area, id);

  num _clamp(num v) => v < min ? min : (v > max ? max : v);

  void _set(num v) {
    final clamped = _clamp(v);
    if (clamped == state.value) return;
    state.value = clamped;
    onChanged?.call(clamped);
  }

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    final big = pageStep ?? ((max - min) / 10);
    switch (event.key) {
      case NamedKey.arrowLeft:
        _set(state.value - step);
        return true;
      case NamedKey.arrowRight:
        _set(state.value + step);
        return true;
      case NamedKey.arrowDown:
        _set(state.value - step);
        return true;
      case NamedKey.arrowUp:
        _set(state.value + step);
        return true;
      case NamedKey.pageDown:
        _set(state.value - big);
        return true;
      case NamedKey.pageUp:
        _set(state.value + big);
        return true;
      case NamedKey.home:
        _set(min);
        return true;
      case NamedKey.end:
        _set(max);
        return true;
      default:
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

    final label = showValue ? ' ${_format(state.value)}' : '';
    final trackWidth = (area.width - label.length).clamp(1, area.width);
    if (trackWidth <= 0) return;

    final ratio = (state.value - min) / (max - min);
    final handlePos =
        (ratio * (trackWidth - 1)).round().clamp(0, trackWidth - 1);

    final track = trackStyle ?? Style(fg: ctx.theme.colors.muted);
    final fill = fillStyle ?? Style(fg: ctx.theme.colors.primary);
    final handle = handleStyle ??
        Style(
          fg: focused ? ctx.theme.colors.primary : ctx.theme.colors.foreground,
          bold: focused,
        );

    for (var i = 0; i < trackWidth; i++) {
      if (i == handlePos) {
        buffer.setChar(area.x + i, area.y, handleChar, style: handle);
      } else if (i < handlePos) {
        buffer.setChar(area.x + i, area.y, fillChar, style: fill);
      } else {
        buffer.setChar(area.x + i, area.y, trackChar, style: track);
      }
    }

    if (label.isNotEmpty) {
      buffer.writeText(area.x + trackWidth, area.y, label,
          style: ctx.theme.text.body, maxWidth: label.length);
    }
  }
}
