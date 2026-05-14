import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

class TextAreaState {
  List<String> lines;
  int cursorLine;
  int cursorCol;
  int scrollOffset;
  bool submitted;

  TextAreaState({String? initialValue})
      : lines = (initialValue ?? '').split('\n'),
        cursorLine = (initialValue ?? '').split('\n').length - 1,
        cursorCol = (initialValue ?? '').split('\n').last.length,
        scrollOffset = 0,
        submitted = false;

  String get text => lines.join('\n');

  set text(String value) {
    lines = value.split('\n');
    cursorLine = lines.length - 1;
    cursorCol = lines.last.length;
  }
}

class TextArea implements FocusableWidget {
  final Key? _id;
  @override
  Key get id => _id ?? ValueKey(state);

  final TextAreaState state;
  final String? placeholder;
  final int? maxLines;
  final int? maxLength;
  final bool submitOnCtrlEnter;
  final void Function(String value)? onChanged;
  final void Function(String value)? onSubmit;

  final Style? textStyle;
  final Style? placeholderStyle;
  final Style? cursorStyle;

  const TextArea({
    Key? id,
    required this.state,
    this.placeholder,
    this.maxLines,
    this.maxLength,
    this.submitOnCtrlEnter = true,
    this.onChanged,
    this.onSubmit,
    this.textStyle,
    this.placeholderStyle,
    this.cursorStyle,
  }) : _id = id;

  @override
  bool get isSkipped => false;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) => sink.add(area, id);

  void _clampCursor() {
    if (state.cursorLine < 0) state.cursorLine = 0;
    if (state.cursorLine >= state.lines.length) {
      state.cursorLine = state.lines.length - 1;
    }
    final line = state.lines[state.cursorLine];
    if (state.cursorCol < 0) state.cursorCol = 0;
    if (state.cursorCol > line.length) state.cursorCol = line.length;
  }

  void _notifyChanged() {
    onChanged?.call(state.text);
    state.submitted = false;
  }

  void _insertChar(String c) {
    if (maxLength != null && state.text.length >= maxLength!) return;
    final line = state.lines[state.cursorLine];
    state.lines[state.cursorLine] =
        line.substring(0, state.cursorCol) + c + line.substring(state.cursorCol);
    state.cursorCol += c.length;
    _notifyChanged();
  }

  void _insertNewline() {
    if (maxLines != null && state.lines.length >= maxLines!) return;
    final line = state.lines[state.cursorLine];
    final before = line.substring(0, state.cursorCol);
    final after = line.substring(state.cursorCol);
    state.lines[state.cursorLine] = before;
    state.lines.insert(state.cursorLine + 1, after);
    state.cursorLine += 1;
    state.cursorCol = 0;
    _notifyChanged();
  }

  void _backspace() {
    if (state.cursorCol > 0) {
      final line = state.lines[state.cursorLine];
      state.lines[state.cursorLine] =
          line.substring(0, state.cursorCol - 1) + line.substring(state.cursorCol);
      state.cursorCol -= 1;
      _notifyChanged();
    } else if (state.cursorLine > 0) {
      final prev = state.lines[state.cursorLine - 1];
      final cur = state.lines[state.cursorLine];
      state.cursorCol = prev.length;
      state.lines[state.cursorLine - 1] = prev + cur;
      state.lines.removeAt(state.cursorLine);
      state.cursorLine -= 1;
      _notifyChanged();
    }
  }

  void _delete() {
    final line = state.lines[state.cursorLine];
    if (state.cursorCol < line.length) {
      state.lines[state.cursorLine] =
          line.substring(0, state.cursorCol) + line.substring(state.cursorCol + 1);
      _notifyChanged();
    } else if (state.cursorLine < state.lines.length - 1) {
      final next = state.lines[state.cursorLine + 1];
      state.lines[state.cursorLine] = line + next;
      state.lines.removeAt(state.cursorLine + 1);
      _notifyChanged();
    }
  }

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    _clampCursor();
    switch (event.key) {
      case NamedKey.enter:
        if (submitOnCtrlEnter && event.ctrl) {
          state.submitted = true;
          onSubmit?.call(state.text);
          return true;
        }
        _insertNewline();
        return true;
      case NamedKey.backspace:
        _backspace();
        return true;
      case NamedKey.delete:
        _delete();
        return true;
      case NamedKey.arrowLeft:
        if (state.cursorCol > 0) {
          state.cursorCol -= 1;
        } else if (state.cursorLine > 0) {
          state.cursorLine -= 1;
          state.cursorCol = state.lines[state.cursorLine].length;
        }
        return true;
      case NamedKey.arrowRight:
        final line = state.lines[state.cursorLine];
        if (state.cursorCol < line.length) {
          state.cursorCol += 1;
        } else if (state.cursorLine < state.lines.length - 1) {
          state.cursorLine += 1;
          state.cursorCol = 0;
        }
        return true;
      case NamedKey.arrowUp:
        if (state.cursorLine > 0) {
          state.cursorLine -= 1;
          state.cursorCol =
              state.cursorCol.clamp(0, state.lines[state.cursorLine].length);
        }
        return true;
      case NamedKey.arrowDown:
        if (state.cursorLine < state.lines.length - 1) {
          state.cursorLine += 1;
          state.cursorCol =
              state.cursorCol.clamp(0, state.lines[state.cursorLine].length);
        }
        return true;
      case NamedKey.home:
        state.cursorCol = 0;
        return true;
      case NamedKey.end:
        state.cursorCol = state.lines[state.cursorLine].length;
        return true;
      case NamedKey.pageUp:
        state.cursorLine = (state.cursorLine - 5).clamp(0, state.lines.length - 1);
        state.cursorCol =
            state.cursorCol.clamp(0, state.lines[state.cursorLine].length);
        return true;
      case NamedKey.pageDown:
        state.cursorLine = (state.cursorLine + 5).clamp(0, state.lines.length - 1);
        state.cursorCol =
            state.cursorCol.clamp(0, state.lines[state.cursorLine].length);
        return true;
      default:
        if (event.ctrl || event.alt) return false;
        final c = event.char;
        if (c != null &&
            c.runes.length == 1 &&
            c.runes.first >= 0x20 &&
            c.runes.first != 0x7F) {
          _insertChar(c);
          return true;
        }
        return false;
    }
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    _clampCursor();
    final focused = ctx.isFocused(id);

    // Keep cursor in viewport.
    if (state.cursorLine < state.scrollOffset) {
      state.scrollOffset = state.cursorLine;
    } else if (state.cursorLine >= state.scrollOffset + area.height) {
      state.scrollOffset = state.cursorLine - area.height + 1;
    }
    state.scrollOffset = state.scrollOffset.clamp(0, state.lines.length);

    final showPlaceholder = state.lines.length == 1 &&
        state.lines.first.isEmpty &&
        placeholder != null &&
        !focused;

    final txtStyle = textStyle ?? ctx.theme.text.body;
    final phStyle = placeholderStyle ??
        Style(fg: ctx.theme.colors.muted, italic: true);
    final curStyle = cursorStyle ??
        Style(
          fg: ctx.theme.colors.background,
          bg: focused ? ctx.theme.colors.primary : ctx.theme.colors.foreground,
        );

    if (showPlaceholder) {
      buffer.writeText(area.x, area.y, placeholder!,
          style: phStyle, maxWidth: area.width);
      return;
    }

    for (var i = 0; i < area.height; i++) {
      final lineIdx = state.scrollOffset + i;
      if (lineIdx >= state.lines.length) break;
      final line = state.lines[lineIdx];
      final visible = line.length > area.width ? line.substring(0, area.width) : line;
      buffer.writeText(area.x, area.y + i, visible,
          style: txtStyle, maxWidth: area.width);

      // Draw the cursor on the line containing it.
      if (focused && lineIdx == state.cursorLine) {
        final cx = area.x + state.cursorCol;
        if (cx < area.right) {
          final ch = state.cursorCol < line.length ? line[state.cursorCol] : ' ';
          buffer.setChar(cx, area.y + i, ch, style: curStyle);
        }
      }
    }
  }
}
