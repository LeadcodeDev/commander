import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../rendering/cell.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/border.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

class SelectState {
  bool open;
  int highlightedIndex;
  SelectState({this.open = false, this.highlightedIndex = 0});
}

class Select<T> implements FocusableWidget {
  @override
  final Key id;
  final List<T> options;
  final T? selected;
  final String Function(T)? display;
  final void Function(T value)? onChanged;
  final SelectState state;
  final String placeholder;
  final int maxDropdownHeight;

  const Select({
    required this.id,
    required this.options,
    required this.state,
    this.selected,
    this.display,
    this.onChanged,
    this.placeholder = 'Select...',
    this.maxDropdownHeight = 5,
  });

  String _label(T v) => display != null ? display!(v) : v.toString();

  @override
  bool get isSkipped => false;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) {
    sink.add(area, id);
  }

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    if (!state.open) {
      if (event.key == 'Enter' || event.key == ' ') {
        state.open = true;
        state.highlightedIndex = selected == null
            ? 0
            : options.indexWhere((o) => o == selected).clamp(0, options.length - 1);
        return true;
      }
      return false;
    }
    switch (event.key) {
      case 'Escape':
        state.open = false;
        return true;
      case 'ArrowDown':
      case 'j':
        state.highlightedIndex =
            (state.highlightedIndex + 1).clamp(0, options.length - 1);
        return true;
      case 'ArrowUp':
      case 'k':
        state.highlightedIndex =
            (state.highlightedIndex - 1).clamp(0, options.length - 1);
        return true;
      case 'Enter':
        if (options.isNotEmpty) {
          onChanged?.call(options[state.highlightedIndex]);
        }
        state.open = false;
        return true;
    }
    return false;
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    final isFocused = ctx.isFocused(id);
    final base = ctx.theme.text.body;
    final style = isFocused
        ? base.copyWith(fg: ctx.theme.colors.primary, bold: true)
        : base;
    final label = selected == null ? placeholder : _label(selected as T);
    final arrow = state.open ? '▲' : '▼';
    buffer.writeText(area.x, area.y, '$label $arrow', style: style, maxWidth: area.width);

    if (state.open) {
      final h = (options.length + 2).clamp(3, maxDropdownHeight + 2);
      final dropArea = Rect(area.x, area.y + 1, area.width, h);
      ctx.drawOverlay(
        _SelectDropdown<T>(
          options: options,
          highlightedIndex: state.highlightedIndex,
          display: _label,
        ),
        dropArea,
      );
    }
  }
}

class _SelectDropdown<T> implements Widget {
  final List<T> options;
  final int highlightedIndex;
  final String Function(T) display;

  const _SelectDropdown({
    required this.options,
    required this.highlightedIndex,
    required this.display,
  });

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.width < 2 || area.height < 2) return;
    buffer.fillRect(area, const Cell(char: ' '));
    final chars = BorderStyle.single.chars;
    final stroke = ctx.theme.borders.strokeStyle;
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

    final visibleRows = area.height - 2;
    final base = ctx.theme.text.body;
    final hl =
        Style(bg: ctx.theme.colors.primary, fg: ctx.theme.colors.background);
    for (var i = 0; i < visibleRows && i < options.length; i++) {
      final isHi = i == highlightedIndex;
      final lineRect = Rect(area.x + 1, area.y + 1 + i, area.width - 2, 1);
      if (lineRect.isEmpty) continue;
      buffer.writeText(lineRect.x, lineRect.y, display(options[i]),
          style: isHi ? hl : base, maxWidth: lineRect.width);
      if (isHi) buffer.fillStyle(lineRect, hl);
    }
  }
}
