import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/border.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

class TextFieldState {
  String value;
  int cursor;
  TextFieldState({this.value = '', int? cursor}) : cursor = cursor ?? value.length;
}

class TextField implements FocusableWidget {
  @override
  final Key id;
  final String value;
  final String placeholder;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmit;
  final bool obscure;
  final bool Function(String)? validate;
  final Style? focusedStyle;
  final Style? unfocusedStyle;
  final BorderStyle? border;
  final TextFieldState? state;

  const TextField({
    required this.id,
    required this.value,
    this.placeholder = '',
    this.onChanged,
    this.onSubmit,
    this.obscure = false,
    this.validate,
    this.focusedStyle,
    this.unfocusedStyle,
    this.border,
    this.state,
  });

  @override
  bool get isSkipped => false;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) {
    sink.add(area, id);
  }

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    var cur = state?.cursor ?? value.length;
    var v = state?.value ?? value;
    if (cur > v.length) cur = v.length;

    String? next;
    switch (event.key) {
      case 'Enter':
        onSubmit?.call();
        return true;
      case 'Backspace':
        if (cur > 0) {
          next = v.substring(0, cur - 1) + v.substring(cur);
          cur -= 1;
        }
        break;
      case 'Delete':
        if (cur < v.length) {
          next = v.substring(0, cur) + v.substring(cur + 1);
        }
        break;
      case 'ArrowLeft':
        if (cur > 0) cur -= 1;
        if (state != null) state!.cursor = cur;
        return true;
      case 'ArrowRight':
        if (cur < v.length) cur += 1;
        if (state != null) state!.cursor = cur;
        return true;
      case 'Home':
        cur = 0;
        if (state != null) state!.cursor = cur;
        return true;
      case 'End':
        cur = v.length;
        if (state != null) state!.cursor = cur;
        return true;
      default:
        if (event.ctrl || event.alt) return false;
        if (event.key.length == 1 && event.key.codeUnitAt(0) >= 0x20) {
          next = v.substring(0, cur) + event.key + v.substring(cur);
          cur += event.key.length;
        } else if (event.key.runes.length == 1 && event.key.runes.first >= 0x20) {
          next = v.substring(0, cur) + event.key + v.substring(cur);
          cur += event.key.length;
        }
    }

    if (next != null) {
      if (state != null) {
        state!.value = next;
        state!.cursor = cur;
      }
      onChanged?.call(next);
      return true;
    }
    return false;
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    final isFocused = ctx.isFocused(id);
    final borderStyle = border ??
        (isFocused
            ? ctx.theme.borders.focusedStyle
            : ctx.theme.borders.style);
    final stroke = isFocused
        ? ctx.theme.borders.focusedStrokeStyle.withFg(ctx.theme.colors.primary)
        : ctx.theme.borders.strokeStyle;

    final hasBorder = borderStyle != BorderStyle.none && area.height >= 3;
    final inner = hasBorder ? area.insetAll(1) : area;

    if (hasBorder) {
      _drawBorder(area, buffer, borderStyle, stroke);
    }

    final v = state?.value ?? value;
    final cur = state?.cursor ?? value.length;
    final isValid = validate?.call(v) ?? true;
    final textStyle = isFocused
        ? (focusedStyle ?? Style.none)
        : (unfocusedStyle ?? ctx.theme.text.body);
    final display = v.isEmpty
        ? placeholder
        : (obscure ? '*' * v.length : v);
    final displayStyle = v.isEmpty
        ? ctx.theme.text.caption
        : (isValid
            ? textStyle
            : textStyle.copyWith(fg: ctx.theme.colors.error));

    if (!inner.isEmpty) {
      buffer.writeText(inner.x, inner.y, display, style: displayStyle, maxWidth: inner.width);
      if (isFocused && cur <= v.length) {
        final cx = inner.x + cur;
        if (cx < inner.right) {
          final c = cur < v.length ? v[cur] : ' ';
          final ch = obscure && cur < v.length ? '*' : c;
          buffer.setChar(cx, inner.y, ch, style: const Style(reverse: true));
        }
      }
    }
  }

  void _drawBorder(Rect area, Buffer buffer, BorderStyle bs, Style stroke) {
    final chars = bs.chars;
    for (var x = 0; x < area.width; x++) {
      buffer.setChar(area.x + x, area.y, chars.top, style: stroke);
      buffer.setChar(area.x + x, area.bottom - 1, chars.bottom, style: stroke);
    }
    for (var y = 0; y < area.height; y++) {
      buffer.setChar(area.x, area.y + y, chars.left, style: stroke);
      buffer.setChar(area.right - 1, area.y + y, chars.right, style: stroke);
    }
    buffer.setChar(area.x, area.y, chars.topLeft, style: stroke);
    buffer.setChar(area.right - 1, area.y, chars.topRight, style: stroke);
    buffer.setChar(area.x, area.bottom - 1, chars.bottomLeft, style: stroke);
    buffer.setChar(area.right - 1, area.bottom - 1, chars.bottomRight, style: stroke);
  }
}

typedef ValueChanged<T> = void Function(T value);
typedef VoidCallback = void Function();
