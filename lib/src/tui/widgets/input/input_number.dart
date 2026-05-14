import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

class InputNumberState {
  String text;
  int cursor;
  String? error;
  bool submitted;

  InputNumberState({num? initialValue})
      : text = initialValue?.toString() ?? '',
        cursor = (initialValue?.toString() ?? '').length,
        error = null,
        submitted = false;

  num? get parsed {
    if (text.isEmpty || text == '-' || text == '.') return null;
    return num.tryParse(text);
  }
}

class InputNumber implements FocusableWidget, SizedWidget {
  final Key? _id;
  @override
  Key get id => _id ?? ValueKey(state);

  final InputNumberState state;
  final String message;
  final String? placeholder;
  final num? min;
  final num? max;
  final num step;
  final bool allowDecimals;
  final bool allowNegative;
  final num? defaultValue;
  final String? Function(num value)? validate;
  final void Function(num value)? onSubmit;
  final void Function(num? value)? onChanged;

  final bool lockOnSubmit;
  final String askPrefix;
  final String errorPrefix;
  final String successPrefix;

  final Style? messageStyle;
  final Style? inputStyle;
  final Style? errorStyle;
  final Style? askPrefixStyle;
  final Style? errorPrefixStyle;
  final Style? successPrefixStyle;

  const InputNumber({
    Key? id,
    required this.state,
    required this.message,
    this.placeholder,
    this.min,
    this.max,
    this.step = 1,
    this.allowDecimals = false,
    this.allowNegative = true,
    this.defaultValue,
    this.validate,
    this.onSubmit,
    this.onChanged,
    this.lockOnSubmit = true,
    this.askPrefix = '?',
    this.errorPrefix = '✗',
    this.successPrefix = '✓',
    this.messageStyle,
    this.inputStyle,
    this.errorStyle,
    this.askPrefixStyle,
    this.errorPrefixStyle,
    this.successPrefixStyle,
  })  : _id = id,
        assert(step > 0, 'step must be > 0'),
        assert(min == null || max == null || min <= max,
            'min must be <= max');

  @override
  bool get isSkipped => state.submitted && lockOnSubmit;

  @override
  int get height => (!state.submitted && state.error != null) ? 2 : 1;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) => sink.add(area, id);

  bool _isValidChar(int codePoint, String current, int cursor) {
    // Digits 0-9.
    if (codePoint >= 0x30 && codePoint <= 0x39) return true;
    // Minus only at position 0 and not already present.
    if (codePoint == 0x2D) {
      return allowNegative && cursor == 0 && !current.startsWith('-');
    }
    // Decimal point.
    if (codePoint == 0x2E) {
      return allowDecimals && !current.contains('.');
    }
    return false;
  }

  num? _coerce(String text) {
    if (text.isEmpty || text == '-' || text == '.') return null;
    if (allowDecimals) return double.tryParse(text);
    return int.tryParse(text);
  }

  num _clamp(num v) {
    if (min != null && v < min!) return min!;
    if (max != null && v > max!) return max!;
    return v;
  }

  void _setFromNumber(num v) {
    final clamped = _clamp(v);
    final asText = allowDecimals
        ? (clamped is int
            ? clamped.toString()
            : (clamped as double).toString())
        : clamped.toInt().toString();
    state.text = asText;
    state.cursor = asText.length;
    state.error = null;
    state.submitted = false;
    onChanged?.call(clamped);
  }

  void _submit() {
    final raw = state.text.isEmpty && defaultValue != null
        ? defaultValue!.toString()
        : state.text;
    final parsed = _coerce(raw);
    if (parsed == null) {
      state.error = 'Must be a number';
      return;
    }
    if (min != null && parsed < min!) {
      state.error = 'Min is $min';
      return;
    }
    if (max != null && parsed > max!) {
      state.error = 'Max is $max';
      return;
    }
    final err = validate?.call(parsed);
    if (err != null) {
      state.error = err;
      return;
    }
    state.error = null;
    state.submitted = true;
    if (state.text.isEmpty && defaultValue != null) {
      state.text = raw;
      state.cursor = state.text.length;
    }
    onSubmit?.call(parsed);
  }

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    if (state.submitted && lockOnSubmit) return false;

    var cur = state.cursor.clamp(0, state.text.length);
    var v = state.text;
    String? next;

    if (event.key != null) {
      switch (event.key!) {
        case NamedKey.enter:
          _submit();
          return true;
        case NamedKey.arrowUp:
          final current = _coerce(v) ?? defaultValue ?? min ?? 0;
          _setFromNumber(current + step);
          return true;
        case NamedKey.arrowDown:
          final current = _coerce(v) ?? defaultValue ?? max ?? 0;
          _setFromNumber(current - step);
          return true;
        case NamedKey.backspace:
          if (cur > 0) {
            next = v.substring(0, cur - 1) + v.substring(cur);
            cur -= 1;
          }
        case NamedKey.delete:
          if (cur < v.length) {
            next = v.substring(0, cur) + v.substring(cur + 1);
          }
        case NamedKey.arrowLeft:
          if (cur > 0) cur -= 1;
          state.cursor = cur;
          return true;
        case NamedKey.arrowRight:
          if (cur < v.length) cur += 1;
          state.cursor = cur;
          return true;
        case NamedKey.home:
          state.cursor = 0;
          return true;
        case NamedKey.end:
          state.cursor = v.length;
          return true;
        default:
          return false;
      }
    } else {
      if (event.ctrl || event.alt) return false;
      final c = event.char;
      if (c != null && c.runes.length == 1) {
        final cp = c.runes.first;
        if (_isValidChar(cp, v, cur)) {
          next = v.substring(0, cur) + c + v.substring(cur);
          cur += c.length;
        }
      }
    }

    if (next != null) {
      state.text = next;
      state.cursor = cur;
      state.error = null;
      state.submitted = false;
      onChanged?.call(_coerce(next));
      return true;
    }
    return false;
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    final focused = ctx.isFocused(id);

    final prefix = state.submitted
        ? successPrefix
        : (state.error != null ? errorPrefix : askPrefix);
    final prefixStyle = state.submitted
        ? (successPrefixStyle ??
            Style(fg: ctx.theme.colors.success, bold: true))
        : (state.error != null
            ? (errorPrefixStyle ??
                Style(fg: ctx.theme.colors.error, bold: true))
            : (askPrefixStyle ??
                Style(fg: ctx.theme.colors.primary, bold: true)));

    final msgStyle = messageStyle ?? ctx.theme.text.body;
    final valStyle = inputStyle ??
        ctx.theme.text.body.copyWith(
          fg: focused ? ctx.theme.colors.primary : null,
        );

    var x = area.x;
    buffer.writeText(x, area.y, prefix,
        style: prefixStyle, maxWidth: area.width);
    x += prefix.length + 1;

    if (x < area.right) {
      buffer.writeText(x, area.y, message,
          style: msgStyle, maxWidth: area.right - x);
      x += message.length + 1;
    }

    if (x < area.right) {
      final shown = state.text.isEmpty && placeholder != null && !focused
          ? placeholder!
          : state.text;
      final shownStyle = state.text.isEmpty && placeholder != null && !focused
          ? Style(fg: ctx.theme.colors.muted, italic: true)
          : valStyle;
      buffer.writeText(x, area.y, shown,
          style: shownStyle, maxWidth: area.right - x);
    }

    if (!state.submitted && state.error != null && area.height >= 2) {
      final errStyle = errorStyle ?? Style(fg: ctx.theme.colors.error);
      buffer.writeText(area.x + prefix.length + 1, area.y + 1, state.error!,
          style: errStyle, maxWidth: area.width - prefix.length - 1);
    }
  }
}
