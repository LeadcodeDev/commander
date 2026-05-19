import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

enum SelectionMode { single, multi }

class SelectItemState {
  final bool isActive;
  final bool isSelected;
  final bool isFocused;
  final int index;
  final bool canSelect;

  const SelectItemState({
    required this.isActive,
    required this.isSelected,
    required this.isFocused,
    required this.index,
    required this.canSelect,
  });
}

typedef SelectItemBuilder<T> = Widget Function(T item, SelectItemState state);
typedef SelectFilter<T> = bool Function(T item, String query);

class SelectState<T> {
  int activeIndex = 0;
  int scrollOffset = 0;
  final Set<T> selected = {};
  String filterQuery = '';
  int filterCursor = 0;
  bool filterFocused = false;
  String? validationError;
  bool initialized = false;
}

class Select<T> implements FocusableWidget {
  final Key? _id;
  @override
  Key get id => _id ?? ValueKey(state);
  final List<T> items;
  final SelectionMode mode;
  final SelectState<T> state;

  final int visibleCount;
  final String placeholder;
  final SelectItemBuilder<T> builder;

  final T? defaultValue;
  final List<T> defaultValues;

  final bool filterable;
  final SelectFilter<T>? filter;
  final String filterPlaceholder;

  final int? minSelections;
  final int? maxSelections;

  final String? Function(List<T> selected)? validate;

  final void Function(T item)? onChanged;
  final void Function(List<T> items)? onSubmit;
  final void Function(T item, bool selected)? onToggle;

  const Select({
    Key? id,
    required this.items,
    required this.state,
    required this.builder,
    this.mode = SelectionMode.single,
    this.visibleCount = 5,
    this.placeholder = 'No items',
    this.defaultValue,
    this.defaultValues = const [],
    this.filterable = false,
    this.filter,
    this.filterPlaceholder = 'Filter...',
    this.minSelections,
    this.maxSelections,
    this.validate,
    this.onChanged,
    this.onSubmit,
    this.onToggle,
  })  : _id = id,
        assert(visibleCount > 0),
        assert(minSelections == null || minSelections >= 0),
        assert(maxSelections == null || maxSelections >= 1),
        assert(minSelections == null ||
            maxSelections == null ||
            minSelections <= maxSelections);

  @override
  bool get isSkipped => false;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) {
    sink.add(area, id);
  }

  void _ensureDefaults() {
    if (state.initialized) return;
    state.initialized = true;
    if (mode == SelectionMode.single) {
      if (defaultValue != null && items.contains(defaultValue)) {
        state.selected
          ..clear()
          ..add(defaultValue as T);
        state.activeIndex = items.indexOf(defaultValue as T);
      }
    } else {
      for (final v in defaultValues) {
        if (items.contains(v)) state.selected.add(v);
      }
    }
  }

  List<T> _filteredItems() {
    if (!filterable || state.filterQuery.isEmpty) return items;
    final q = state.filterQuery;
    final f = filter ??
        (T item, String query) =>
            item.toString().toLowerCase().contains(query.toLowerCase());
    return items.where((i) => f(i, q)).toList(growable: false);
  }

  bool _canSelect(T item) {
    if (mode == SelectionMode.single) return true;
    if (state.selected.contains(item)) return true;
    final max = maxSelections;
    if (max == null) return true;
    return state.selected.length < max;
  }

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    if (state.filterFocused) {
      return _onKeyFilter(event);
    }
    return _onKeyList(event);
  }

  bool _onKeyFilter(KeyEvent event) {
    state.validationError = null;
    if (event.key == NamedKey.arrowDown) {
      state.filterFocused = false;
      state.activeIndex = 0;
      state.scrollOffset = 0;
      return true;
    }
    if (event.key == NamedKey.escape) {
      if (state.filterQuery.isNotEmpty) {
        state.filterQuery = '';
        state.filterCursor = 0;
        return true;
      }
      return false;
    }
    if (event.key == NamedKey.enter) {
      state.filterFocused = false;
      return true;
    }
    if (event.key == NamedKey.backspace) {
      if (state.filterCursor > 0) {
        state.filterQuery =
            state.filterQuery.substring(0, state.filterCursor - 1) +
                state.filterQuery.substring(state.filterCursor);
        state.filterCursor -= 1;
      }
      return true;
    }
    if (event.key == NamedKey.delete) {
      if (state.filterCursor < state.filterQuery.length) {
        state.filterQuery = state.filterQuery.substring(0, state.filterCursor) +
            state.filterQuery.substring(state.filterCursor + 1);
      }
      return true;
    }
    if (event.key == NamedKey.arrowLeft) {
      if (state.filterCursor > 0) state.filterCursor -= 1;
      return true;
    }
    if (event.key == NamedKey.arrowRight) {
      if (state.filterCursor < state.filterQuery.length) {
        state.filterCursor += 1;
      }
      return true;
    }
    if (event.key == NamedKey.home) {
      state.filterCursor = 0;
      return true;
    }
    if (event.key == NamedKey.end) {
      state.filterCursor = state.filterQuery.length;
      return true;
    }
    if (event.char != null) {
      if (event.ctrl || event.alt) return false;
      final c = event.char!;
      if (c.runes.length == 1 && c.runes.first >= 0x20) {
        state.filterQuery = state.filterQuery.substring(0, state.filterCursor) +
            c +
            state.filterQuery.substring(state.filterCursor);
        state.filterCursor += c.length;
        return true;
      }
    }
    return false;
  }

  bool _onKeyList(KeyEvent event) {
    final filtered = _filteredItems();
    if (filtered.isEmpty) {
      if (event.key == NamedKey.escape) {
        if (filterable && state.filterQuery.isNotEmpty) {
          state.filterQuery = '';
          state.filterCursor = 0;
          return true;
        }
        return false;
      }
      if (filterable && _isPrintable(event)) {
        state.filterFocused = true;
        return _onKeyFilter(event);
      }
      return false;
    }
    state.activeIndex = state.activeIndex.clamp(0, filtered.length - 1);

    if (event.key == NamedKey.arrowUp || event.char == 'k') {
      if (filterable && state.activeIndex == 0) {
        state.filterFocused = true;
        state.filterCursor = state.filterQuery.length;
        return true;
      }
      state.activeIndex = (state.activeIndex - 1).clamp(0, filtered.length - 1);
      return true;
    }
    if (event.key == NamedKey.arrowDown || event.char == 'j') {
      state.activeIndex = (state.activeIndex + 1).clamp(0, filtered.length - 1);
      return true;
    }
    if (event.key == NamedKey.pageUp) {
      state.activeIndex =
          (state.activeIndex - visibleCount).clamp(0, filtered.length - 1);
      return true;
    }
    if (event.key == NamedKey.pageDown) {
      state.activeIndex =
          (state.activeIndex + visibleCount).clamp(0, filtered.length - 1);
      return true;
    }
    if (event.key == NamedKey.home) {
      state.activeIndex = 0;
      return true;
    }
    if (event.key == NamedKey.end) {
      state.activeIndex = filtered.length - 1;
      return true;
    }
    if (event.char == ' ') {
      _toggleAtActive(filtered);
      return true;
    }
    if (event.key == NamedKey.enter) {
      _submit();
      return true;
    }
    if (event.key == NamedKey.escape) {
      if (filterable && state.filterQuery.isNotEmpty) {
        state.filterQuery = '';
        state.filterCursor = 0;
        state.activeIndex = state.activeIndex.clamp(0, items.length - 1);
        return true;
      }
      return false;
    }
    if (filterable && _isPrintable(event)) {
      state.filterFocused = true;
      return _onKeyFilter(event);
    }
    return false;
  }

  bool _isPrintable(KeyEvent event) {
    if (event.ctrl || event.alt) return false;
    final c = event.char;
    if (c == null || c.isEmpty) return false;
    return c.runes.length == 1 &&
        c.runes.first >= 0x20 &&
        c.runes.first != 0x7F;
  }

  void _toggleAtActive(List<T> filtered) {
    state.validationError = null;
    final item = filtered[state.activeIndex];
    if (mode == SelectionMode.single) {
      state.selected
        ..clear()
        ..add(item);
      onChanged?.call(item);
      return;
    }
    if (state.selected.contains(item)) {
      state.selected.remove(item);
      onToggle?.call(item, false);
    } else {
      final max = maxSelections;
      if (max != null && state.selected.length >= max) {
        return; // refused
      }
      state.selected.add(item);
      onToggle?.call(item, true);
    }
  }

  void _submit() {
    final selectedList = state.selected.toList(growable: false);
    if (mode == SelectionMode.single && selectedList.isEmpty) {
      final filtered = _filteredItems();
      if (filtered.isNotEmpty) {
        final item = filtered[state.activeIndex];
        state.selected
          ..clear()
          ..add(item);
        onChanged?.call(item);
      }
    }
    final finalList = state.selected.toList(growable: false);
    final min = minSelections;
    if (mode == SelectionMode.multi && min != null && finalList.length < min) {
      state.validationError = 'Select at least $min item${min > 1 ? 's' : ''}.';
      return;
    }
    final validator = validate;
    if (validator != null) {
      final err = validator(finalList);
      if (err != null) {
        state.validationError = err;
        return;
      }
    }
    state.validationError = null;
    onSubmit?.call(finalList);
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    _ensureDefaults();

    final isFocused = ctx.isFocused(id);
    final filtered = _filteredItems();

    var remaining = area;
    if (filterable) {
      final filterRect = Rect(remaining.x, remaining.y, remaining.width, 1);
      _renderFilter(filterRect, buffer, ctx, isFocused);
      remaining = remaining.inset(top: 1);
      if (remaining.isEmpty) return;
    }

    Rect errorRect = const Rect.zero();
    if (state.validationError != null && remaining.height > 1) {
      errorRect = Rect(remaining.x, remaining.bottom - 1, remaining.width, 1);
      remaining = remaining.inset(bottom: 1);
    }

    final maxVisible = visibleCount.clamp(1, remaining.height);
    if (filtered.isEmpty) {
      _renderEmpty(remaining, buffer, ctx);
    } else {
      _renderList(remaining, buffer, ctx, filtered, maxVisible, isFocused);
    }

    if (state.validationError != null && !errorRect.isEmpty) {
      buffer.writeText(
        errorRect.x,
        errorRect.y,
        state.validationError!,
        style: Style(fg: ctx.theme.colors.error),
        maxWidth: errorRect.width,
      );
    }
  }

  void _renderFilter(
      Rect area, Buffer buffer, RenderContext ctx, bool isFocused) {
    final focused = isFocused && state.filterFocused;
    final query = state.filterQuery;
    final display = query.isEmpty ? filterPlaceholder : query;
    final style = query.isEmpty
        ? ctx.theme.text.caption
        : (focused
            ? ctx.theme.text.body.copyWith(fg: ctx.theme.colors.primary)
            : ctx.theme.text.body);
    final prefix = focused ? '/ ' : '  ';
    buffer.writeText(area.x, area.y, prefix,
        style: ctx.theme.text.caption, maxWidth: area.width);
    buffer.writeText(area.x + 2, area.y, display,
        style: style, maxWidth: area.width - 2);
    if (focused) {
      final cx = area.x + 2 + state.filterCursor;
      if (cx < area.right) {
        final c =
            state.filterCursor < query.length ? query[state.filterCursor] : ' ';
        buffer.setChar(cx, area.y, c, style: const Style(reverse: true));
      }
    }
  }

  void _renderEmpty(Rect area, Buffer buffer, RenderContext ctx) {
    final msg = state.filterQuery.isNotEmpty ? 'No match' : placeholder;
    final y = area.y + area.height ~/ 2;
    final tx = area.x + (area.width - msg.length) ~/ 2;
    buffer.writeText(tx.clamp(area.x, area.right), y, msg,
        style: ctx.theme.text.caption, maxWidth: area.width);
  }

  void _renderList(
    Rect area,
    Buffer buffer,
    RenderContext ctx,
    List<T> filtered,
    int maxVisible,
    bool isFocused,
  ) {
    state.activeIndex = state.activeIndex.clamp(0, filtered.length - 1);
    if (state.activeIndex < state.scrollOffset) {
      state.scrollOffset = state.activeIndex;
    } else if (state.activeIndex >= state.scrollOffset + maxVisible) {
      state.scrollOffset = state.activeIndex - maxVisible + 1;
    }
    final maxOffset = (filtered.length - maxVisible).clamp(0, filtered.length);
    state.scrollOffset = state.scrollOffset.clamp(0, maxOffset);

    final listFocused = isFocused && !state.filterFocused;
    for (var i = 0;
        i < maxVisible && i + state.scrollOffset < filtered.length;
        i++) {
      final idx = i + state.scrollOffset;
      final item = filtered[idx];
      final lineRect = Rect(area.x, area.y + i, area.width, 1);
      if (lineRect.isEmpty) continue;
      final sourceIndex = items.indexOf(item);
      final canSel = _canSelect(item);
      final itemState = SelectItemState(
        isActive: listFocused && idx == state.activeIndex,
        isSelected: state.selected.contains(item),
        isFocused: isFocused,
        index: sourceIndex,
        canSelect: canSel,
      );
      builder(item, itemState).render(lineRect, buffer, ctx);
      if (itemState.isActive) {
        buffer.fillStyle(
          lineRect,
          Style(bg: ctx.theme.colors.primary, fg: ctx.theme.colors.background),
        );
      }
      if (!canSel && !itemState.isSelected) {
        buffer.fillStyle(lineRect, const Style(dim: true));
      }
    }
  }
}
