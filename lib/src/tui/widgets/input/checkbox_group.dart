import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

class CheckboxItemState {
  final bool isChecked;
  final bool isActive;
  final bool isFocused;
  final int index;

  const CheckboxItemState({
    required this.isChecked,
    required this.isActive,
    required this.isFocused,
    required this.index,
  });
}

typedef CheckboxItemBuilder<T> = Widget Function(T item, CheckboxItemState state);

class CheckboxGroupState<T> {
  int activeIndex = 0;
  int scrollOffset = 0;
  final Set<T> checked = {};
  bool initialized = false;
}

class CheckboxGroup<T> implements FocusableWidget {
  @override
  final Key id;
  final List<T> items;
  final CheckboxGroupState<T> state;
  final List<T> defaultChecked;
  final CheckboxItemBuilder<T> builder;
  final void Function(List<T> checked)? onChanged;

  const CheckboxGroup({
    required this.id,
    required this.items,
    required this.state,
    required this.builder,
    this.defaultChecked = const [],
    this.onChanged,
  });

  @override
  bool get isSkipped => false;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) => sink.add(area, id);

  void _ensureDefaults() {
    if (state.initialized) return;
    state.initialized = true;
    for (final v in defaultChecked) {
      if (items.contains(v)) state.checked.add(v);
    }
  }

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    if (items.isEmpty) return false;
    state.activeIndex = state.activeIndex.clamp(0, items.length - 1);

    switch (event.key) {
      case 'ArrowUp':
      case 'k':
        state.activeIndex = (state.activeIndex - 1).clamp(0, items.length - 1);
        return true;
      case 'ArrowDown':
      case 'j':
        state.activeIndex = (state.activeIndex + 1).clamp(0, items.length - 1);
        return true;
      case 'Home':
        state.activeIndex = 0;
        return true;
      case 'End':
        state.activeIndex = items.length - 1;
        return true;
      case 'PageUp':
      case 'PageDown':
        return false;
      case ' ':
        final item = items[state.activeIndex];
        if (state.checked.contains(item)) {
          state.checked.remove(item);
        } else {
          state.checked.add(item);
        }
        onChanged?.call(state.checked.toList(growable: false));
        return true;
    }
    return false;
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    _ensureDefaults();
    if (items.isEmpty) return;

    final isFocused = ctx.isFocused(id);
    final maxVisible = area.height.clamp(1, items.length);

    state.activeIndex = state.activeIndex.clamp(0, items.length - 1);
    if (state.activeIndex < state.scrollOffset) {
      state.scrollOffset = state.activeIndex;
    } else if (state.activeIndex >= state.scrollOffset + maxVisible) {
      state.scrollOffset = state.activeIndex - maxVisible + 1;
    }
    final maxOffset = (items.length - maxVisible).clamp(0, items.length);
    state.scrollOffset = state.scrollOffset.clamp(0, maxOffset);

    for (var i = 0; i < maxVisible && i + state.scrollOffset < items.length; i++) {
      final idx = i + state.scrollOffset;
      final item = items[idx];
      final lineRect = Rect(area.x, area.y + i, area.width, 1);
      if (lineRect.isEmpty) continue;

      final itemState = CheckboxItemState(
        isChecked: state.checked.contains(item),
        isActive: isFocused && idx == state.activeIndex,
        isFocused: isFocused,
        index: idx,
      );
      builder(item, itemState).render(lineRect, buffer, ctx);
      if (itemState.isActive) {
        buffer.fillStyle(
          lineRect,
          Style(bg: ctx.theme.colors.primary, fg: ctx.theme.colors.background),
        );
      }
    }
  }
}
