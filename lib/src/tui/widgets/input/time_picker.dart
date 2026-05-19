import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

enum TimeField { hour, minute, second, ampm }

class TimePickerState {
  int hour;
  int minute;
  int second;
  TimeField active;
  bool submitted;
  TimePickerState({
    this.hour = 0,
    this.minute = 0,
    this.second = 0,
    this.active = TimeField.hour,
    this.submitted = false,
  });
}

class TimePicker implements FocusableWidget, SizedWidget {
  final Key? _id;
  @override
  Key get id => _id ?? ValueKey(state);

  final TimePickerState state;
  final bool use24Hour;
  final bool showSeconds;
  final int hourStep;
  final int minuteStep;
  final int secondStep;
  final void Function(int h, int m, int s)? onChanged;
  final void Function(int h, int m, int s)? onSubmit;

  final Style? fieldStyle;
  final Style? activeFieldStyle;
  final Style? separatorStyle;

  const TimePicker({
    Key? id,
    required this.state,
    this.use24Hour = true,
    this.showSeconds = false,
    this.hourStep = 1,
    this.minuteStep = 1,
    this.secondStep = 1,
    this.onChanged,
    this.onSubmit,
    this.fieldStyle,
    this.activeFieldStyle,
    this.separatorStyle,
  })  : _id = id,
        assert(hourStep > 0 && minuteStep > 0 && secondStep > 0);

  @override
  int get height => 1;

  @override
  bool get isSkipped => false;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) => sink.add(area, id);

  void _adjust(int direction) {
    switch (state.active) {
      case TimeField.hour:
        state.hour = (state.hour + direction * hourStep) % 24;
        if (state.hour < 0) state.hour += 24;
      case TimeField.minute:
        final total = state.hour * 60 + state.minute + direction * minuteStep;
        final wrapped = ((total % (24 * 60)) + 24 * 60) % (24 * 60);
        state.hour = wrapped ~/ 60;
        state.minute = wrapped % 60;
      case TimeField.second:
        final total = (state.hour * 3600 + state.minute * 60 + state.second) +
            direction * secondStep;
        final wrapped = ((total % (24 * 3600)) + 24 * 3600) % (24 * 3600);
        state.hour = wrapped ~/ 3600;
        state.minute = (wrapped % 3600) ~/ 60;
        state.second = wrapped % 60;
      case TimeField.ampm:
        state.hour = (state.hour + 12) % 24;
    }
    onChanged?.call(state.hour, state.minute, state.second);
  }

  List<TimeField> _fieldOrder() {
    final fields = [TimeField.hour, TimeField.minute];
    if (showSeconds) fields.add(TimeField.second);
    if (!use24Hour) fields.add(TimeField.ampm);
    return fields;
  }

  void _cycle(int direction) {
    final order = _fieldOrder();
    final idx = order.indexOf(state.active);
    final next = (idx + direction + order.length) % order.length;
    state.active = order[next];
  }

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    switch (event.key) {
      case NamedKey.arrowUp:
        _adjust(1);
        return true;
      case NamedKey.arrowDown:
        _adjust(-1);
        return true;
      case NamedKey.arrowLeft:
        _cycle(-1);
        return true;
      case NamedKey.arrowRight:
        _cycle(1);
        return true;
      case NamedKey.tab:
        _cycle(1);
        return true;
      case NamedKey.enter:
        state.submitted = true;
        onSubmit?.call(state.hour, state.minute, state.second);
        return true;
      default:
        final c = event.char;
        if (c != null && c.length == 1) {
          final cp = c.codeUnitAt(0);
          if (cp >= 0x30 && cp <= 0x39) {
            final digit = cp - 0x30;
            switch (state.active) {
              case TimeField.hour:
                final v = (state.hour % 10) * 10 + digit;
                state.hour = v >= 24 ? digit : v;
              case TimeField.minute:
                final v = (state.minute % 10) * 10 + digit;
                state.minute = v >= 60 ? digit : v;
              case TimeField.second:
                final v = (state.second % 10) * 10 + digit;
                state.second = v >= 60 ? digit : v;
              case TimeField.ampm:
                return false;
            }
            onChanged?.call(state.hour, state.minute, state.second);
            return true;
          }
          if ((c == 'a' || c == 'A') && !use24Hour) {
            if (state.hour >= 12) state.hour -= 12;
            onChanged?.call(state.hour, state.minute, state.second);
            return true;
          }
          if ((c == 'p' || c == 'P') && !use24Hour) {
            if (state.hour < 12) state.hour += 12;
            onChanged?.call(state.hour, state.minute, state.second);
            return true;
          }
        }
        return false;
    }
  }

  String _pad(int v) => v.toString().padLeft(2, '0');

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    final focused = ctx.isFocused(id);

    final base = fieldStyle ?? ctx.theme.text.body;
    final active = activeFieldStyle ??
        Style(
          fg: ctx.theme.colors.background,
          bg: focused ? ctx.theme.colors.primary : ctx.theme.colors.foreground,
          bold: true,
        );
    final sep = separatorStyle ?? Style(fg: ctx.theme.colors.muted);

    String hourText;
    if (use24Hour) {
      hourText = _pad(state.hour);
    } else {
      final h12 = state.hour % 12 == 0 ? 12 : state.hour % 12;
      hourText = _pad(h12);
    }

    var x = area.x;
    void write(String s, Style style) {
      if (x + s.length > area.right) return;
      buffer.writeText(x, area.y, s, style: style, maxWidth: area.right - x);
      x += s.length;
    }

    write(hourText, state.active == TimeField.hour && focused ? active : base);
    write(':', sep);
    write(_pad(state.minute),
        state.active == TimeField.minute && focused ? active : base);
    if (showSeconds) {
      write(':', sep);
      write(_pad(state.second),
          state.active == TimeField.second && focused ? active : base);
    }
    if (!use24Hour) {
      write(' ', sep);
      write(state.hour < 12 ? 'AM' : 'PM',
          state.active == TimeField.ampm && focused ? active : base);
    }
  }
}
