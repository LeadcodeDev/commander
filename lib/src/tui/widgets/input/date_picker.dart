import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

class DatePickerState {
  DateTime cursor;
  DateTime? selected;
  bool submitted;
  DatePickerState({DateTime? cursor, this.selected})
      : cursor = cursor ?? selected ?? DateTime.now(),
        submitted = false;
}

class DatePicker implements FocusableWidget, SizedWidget {
  final Key? _id;
  @override
  Key get id => _id ?? ValueKey(state);

  final DatePickerState state;
  final DateTime? min;
  final DateTime? max;
  final void Function(DateTime value)? onSubmit;
  final void Function(DateTime value)? onChanged;

  final List<String> monthNames;
  final List<String> weekdayNames;
  final int firstDayOfWeek;

  final Style? headerStyle;
  final Style? weekdayStyle;
  final Style? dayStyle;
  final Style? selectedStyle;
  final Style? cursorStyle;
  final Style? outsideStyle;
  final Style? disabledStyle;

  const DatePicker({
    Key? id,
    required this.state,
    this.min,
    this.max,
    this.onSubmit,
    this.onChanged,
    this.monthNames = const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ],
    this.weekdayNames = const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'],
    this.firstDayOfWeek = 1,
    this.headerStyle,
    this.weekdayStyle,
    this.dayStyle,
    this.selectedStyle,
    this.cursorStyle,
    this.outsideStyle,
    this.disabledStyle,
  })  : _id = id,
        assert(firstDayOfWeek >= 1 && firstDayOfWeek <= 7);

  @override
  int get height => 8;

  @override
  bool get isSkipped => false;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) => sink.add(area, id);

  bool _isDisabled(DateTime d) {
    if (min != null && d.isBefore(_dateOnly(min!))) return true;
    if (max != null && d.isAfter(_dateOnly(max!))) return true;
    return false;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _moveCursor(DateTime next) {
    if (_isDisabled(next)) return;
    state.cursor = next;
    onChanged?.call(next);
  }

  void _shiftDays(int days) {
    _moveCursor(state.cursor.add(Duration(days: days)));
  }

  void _shiftMonths(int months) {
    final c = state.cursor;
    final targetMonth = c.month + months;
    final newYear = c.year + ((targetMonth - 1) ~/ 12);
    final newMonth = ((targetMonth - 1) % 12 + 12) % 12 + 1;
    final lastDay = DateTime(newYear, newMonth + 1, 0).day;
    final day = c.day > lastDay ? lastDay : c.day;
    _moveCursor(DateTime(newYear, newMonth, day));
  }

  void _shiftYears(int years) {
    final c = state.cursor;
    final lastDay = DateTime(c.year + years, c.month + 1, 0).day;
    final day = c.day > lastDay ? lastDay : c.day;
    _moveCursor(DateTime(c.year + years, c.month, day));
  }

  void _select() {
    final picked = _dateOnly(state.cursor);
    if (_isDisabled(picked)) return;
    state.selected = picked;
    state.submitted = true;
    onSubmit?.call(picked);
  }

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    switch (event.key) {
      case NamedKey.arrowLeft:
        _shiftDays(-1);
        return true;
      case NamedKey.arrowRight:
        _shiftDays(1);
        return true;
      case NamedKey.arrowUp:
        _shiftDays(-7);
        return true;
      case NamedKey.arrowDown:
        _shiftDays(7);
        return true;
      case NamedKey.pageUp:
        _shiftMonths(-1);
        return true;
      case NamedKey.pageDown:
        _shiftMonths(1);
        return true;
      case NamedKey.home:
        _moveCursor(DateTime(state.cursor.year, state.cursor.month, 1));
        return true;
      case NamedKey.end:
        final lastDay =
            DateTime(state.cursor.year, state.cursor.month + 1, 0).day;
        _moveCursor(DateTime(state.cursor.year, state.cursor.month, lastDay));
        return true;
      case NamedKey.enter:
        _select();
        return true;
      default:
        if (event.char == '[') {
          _shiftYears(-1);
          return true;
        }
        if (event.char == ']') {
          _shiftYears(1);
          return true;
        }
        return false;
    }
  }

  int _firstColumnOffset(int weekday) {
    // Dart weekday: Mon=1..Sun=7. firstDayOfWeek same convention.
    final offset = (weekday - firstDayOfWeek + 7) % 7;
    return offset;
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty || area.height < 1) return;
    final focused = ctx.isFocused(id);

    final c = state.cursor;
    final monthName = monthNames[c.month - 1];
    final header = '$monthName ${c.year}';

    final hStyle = headerStyle ??
        Style(
          fg: focused ? ctx.theme.colors.primary : ctx.theme.colors.foreground,
          bold: true,
        );
    buffer.writeText(area.x, area.y, header,
        style: hStyle, maxWidth: area.width);

    if (area.height < 2) return;

    final wkStyle = weekdayStyle ?? Style(fg: ctx.theme.colors.muted);
    final orderedWeekdays = [
      for (var i = 0; i < 7; i++) weekdayNames[(firstDayOfWeek - 1 + i) % 7]
    ];
    for (var i = 0; i < 7; i++) {
      final wx = area.x + i * 3;
      if (wx + 2 > area.x + area.width) break;
      buffer.writeText(wx, area.y + 1, orderedWeekdays[i],
          style: wkStyle, maxWidth: 2);
    }

    final firstOfMonth = DateTime(c.year, c.month, 1);
    final colOffset = _firstColumnOffset(firstOfMonth.weekday);
    final daysInMonth = DateTime(c.year, c.month + 1, 0).day;
    final selected = state.selected != null ? _dateOnly(state.selected!) : null;
    final cursorDate = _dateOnly(c);

    final defaultDay = dayStyle ?? ctx.theme.text.body;
    final defaultSelected =
        selectedStyle ?? Style(fg: ctx.theme.colors.success, bold: true);
    final defaultCursor = cursorStyle ??
        Style(
          fg: ctx.theme.colors.background,
          bg: focused ? ctx.theme.colors.primary : ctx.theme.colors.foreground,
          bold: true,
        );
    final defaultDisabled =
        disabledStyle ?? Style(fg: ctx.theme.colors.muted, dim: true);

    for (var day = 1; day <= daysInMonth; day++) {
      final cellIndex = colOffset + day - 1;
      final row = cellIndex ~/ 7;
      final col = cellIndex % 7;
      final yPos = area.y + 2 + row;
      if (yPos >= area.y + area.height) break;
      final xPos = area.x + col * 3;
      if (xPos + 2 > area.x + area.width) continue;

      final date = DateTime(c.year, c.month, day);
      final disabled = _isDisabled(date);
      final isCursor = date == cursorDate;
      final isSelected = selected != null && date == selected;

      Style s;
      if (disabled) {
        s = defaultDisabled;
      } else if (isCursor) {
        s = defaultCursor;
      } else if (isSelected) {
        s = defaultSelected;
      } else {
        s = defaultDay;
      }

      final label = day.toString().padLeft(2);
      buffer.writeText(xPos, yPos, label, style: s, maxWidth: 2);
    }
  }
}
