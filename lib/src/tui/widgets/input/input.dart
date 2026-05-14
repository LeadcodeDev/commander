import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

class InputState {
  String value;
  int cursor;
  String? error;
  bool submitted;

  InputState({String? initialValue})
      : value = initialValue ?? '',
        cursor = (initialValue ?? '').length,
        error = null,
        submitted = false;
}

class Input implements FocusableWidget {
  @override
  final Key id;
  final String message;
  final String? defaultValue;
  final String? placeholder;
  final bool obscure;
  final String? Function(String value)? validate;
  final void Function(String value)? onSubmit;
  final void Function(String value)? onChanged;
  final InputState state;

  final bool lockOnSubmit;

  final String askPrefix;
  final String errorPrefix;
  final String successPrefix;

  final Style? messageStyle;
  final Style? inputStyle;
  final Style? defaultValueStyle;
  final Style? errorStyle;
  final Style? askPrefixStyle;
  final Style? errorPrefixStyle;
  final Style? successPrefixStyle;

  const Input({
    required this.id,
    required this.message,
    required this.state,
    this.defaultValue,
    this.placeholder,
    this.obscure = false,
    this.validate,
    this.onSubmit,
    this.onChanged,
    this.lockOnSubmit = true,
    this.askPrefix = '?',
    this.errorPrefix = '✗',
    this.successPrefix = '✓',
    this.messageStyle,
    this.inputStyle,
    this.defaultValueStyle,
    this.errorStyle,
    this.askPrefixStyle,
    this.errorPrefixStyle,
    this.successPrefixStyle,
  });

  @override
  bool get isSkipped => state.submitted && lockOnSubmit;

  /// Number of rows the input needs in its current state.
  /// - 1 row in normal/submitted state.
  /// - 2 rows when displaying an unrecovered validation error.
  int get height => (!state.submitted && state.error != null) ? 2 : 1;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) => sink.add(area, id);

  bool get _hasDefault => defaultValue != null && defaultValue!.isNotEmpty;

  String _effectiveSubmitValue() {
    final v = state.value;
    if (v.isEmpty && _hasDefault) return defaultValue!;
    return v;
  }

  void _submit() {
    final value = _effectiveSubmitValue();
    final err = validate?.call(value);
    if (err != null) {
      state.error = err;
      return;
    }
    state.error = null;
    state.submitted = true;
    if (state.value.isEmpty && _hasDefault) {
      state.value = defaultValue!;
      state.cursor = state.value.length;
    }
    onSubmit?.call(value);
  }

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    if (state.submitted && lockOnSubmit) return false;

    var cur = state.cursor.clamp(0, state.value.length);
    var v = state.value;
    String? next;

    if (event.key != null) {
      switch (event.key!) {
        case NamedKey.tab:
          if (state.value.isEmpty &&
              placeholder != null &&
              placeholder!.isNotEmpty) {
            state.value = placeholder!;
            state.cursor = state.value.length;
            state.error = null;
            onChanged?.call(state.value);
          }
          return false;
        case NamedKey.enter:
          _submit();
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
          if (v.isEmpty &&
              placeholder != null &&
              placeholder!.isNotEmpty) {
            state.value = placeholder!;
            state.cursor = state.value.length;
            state.error = null;
            onChanged?.call(state.value);
            return true;
          }
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
      if (c != null &&
          c.runes.length == 1 &&
          c.runes.first >= 0x20 &&
          c.runes.first != 0x7F) {
        next = v.substring(0, cur) + c + v.substring(cur);
        cur += c.length;
      }
    }

    if (next != null) {
      state.value = next;
      state.cursor = cur;
      state.error = null;
      state.submitted = false;
      onChanged?.call(next);
      return true;
    }
    return false;
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    final isFocused = ctx.isFocused(id);
    final theme = ctx.theme;

    if (state.submitted && lockOnSubmit) {
      _renderSubmitted(area, buffer, ctx);
      return;
    }

    final hasError = state.error != null;
    final prefix = state.submitted
        ? successPrefix
        : (hasError ? errorPrefix : askPrefix);
    final prefixStyle = state.submitted
        ? (successPrefixStyle ?? Style(fg: theme.colors.success, bold: true))
        : (hasError
            ? (errorPrefixStyle ?? Style(fg: theme.colors.error, bold: true))
            : (askPrefixStyle ?? Style(fg: theme.colors.primary, bold: true)));

    final mStyle = messageStyle ?? theme.text.body;
    final iStyle = inputStyle ??
        (isFocused
            ? theme.text.body.copyWith(fg: theme.colors.primary)
            : theme.text.body);
    final dStyle = defaultValueStyle ?? theme.text.caption;

    var x = area.x;
    buffer.writeText(x, area.y, prefix, style: prefixStyle, maxWidth: area.right - x);
    x += prefix.length + 1;
    buffer.writeText(x, area.y, message, style: mStyle, maxWidth: area.right - x);
    x += message.length;

    if (_hasDefault && state.value.isEmpty) {
      final hint = ' (${defaultValue!})';
      buffer.writeText(x, area.y, hint, style: dStyle, maxWidth: area.right - x);
      x += hint.length;
    }
    buffer.writeText(x, area.y, ' ', style: iStyle, maxWidth: 1);
    x += 1;

    final inputStart = x;
    final inputWidth = area.right - inputStart;
    if (inputWidth > 0) {
      final showPlaceholder = state.value.isEmpty && (placeholder?.isNotEmpty ?? false);
      final display = showPlaceholder
          ? placeholder!
          : (obscure ? '*' * state.value.length : state.value);
      final displayStyle = showPlaceholder ? theme.text.caption : iStyle;
      buffer.writeText(inputStart, area.y, display,
          style: displayStyle, maxWidth: inputWidth);

      if (isFocused) {
        final cur = state.cursor.clamp(0, state.value.length);
        final cx = inputStart + cur;
        if (cx >= inputStart && cx < area.right) {
          final c = cur < state.value.length ? state.value[cur] : ' ';
          final ch = obscure && cur < state.value.length ? '*' : c;
          buffer.setChar(cx, area.y, ch, style: const Style(reverse: true));
        }
      }
    }

    if (hasError && area.height >= 2) {
      final eStyle = errorStyle ?? Style(fg: theme.colors.error);
      final indent = prefix.length + 1;
      buffer.writeText(area.x + indent, area.y + 1, state.error!,
          style: eStyle, maxWidth: area.width - indent);
    }
  }

  void _renderSubmitted(Rect area, Buffer buffer, RenderContext ctx) {
    final theme = ctx.theme;
    final prefixStyle = successPrefixStyle ??
        Style(fg: theme.colors.success, bold: true);
    final mStyle = messageStyle ?? theme.text.body;
    final iStyle = inputStyle ?? theme.text.body.copyWith(bold: true);

    var x = area.x;
    buffer.writeText(x, area.y, successPrefix,
        style: prefixStyle, maxWidth: area.right - x);
    x += successPrefix.length + 1;
    buffer.writeText(x, area.y, message, style: mStyle, maxWidth: area.right - x);
    x += message.length;
    buffer.writeText(x, area.y, ' ', style: iStyle, maxWidth: 1);
    x += 1;
    final value = obscure ? '*' * state.value.length : state.value;
    buffer.writeText(x, area.y, value, style: iStyle, maxWidth: area.right - x);
  }
}
