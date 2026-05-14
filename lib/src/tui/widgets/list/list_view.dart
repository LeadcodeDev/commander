import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

class ListState {
  int selected;
  int scrollOffset;
  ListState({this.selected = 0, this.scrollOffset = 0});
}

class ListView<T> implements FocusableWidget {
  @override
  final Key id;
  final List<T> items;
  final Widget Function(T item, bool selected) itemBuilder;
  final ListState state;
  final int itemHeight;
  final void Function(T item, int index)? onActivate;
  final Style? selectedStyle;

  const ListView({
    required this.id,
    required this.items,
    required this.itemBuilder,
    required this.state,
    this.itemHeight = 1,
    this.onActivate,
    this.selectedStyle,
  });

  @override
  bool get isSkipped => false;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) {
    sink.add(area, id);
  }

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    if (items.isEmpty) return false;
    if (event.key == NamedKey.arrowDown || event.char == 'j') {
      state.selected = (state.selected + 1).clamp(0, items.length - 1);
      return true;
    }
    if (event.key == NamedKey.arrowUp || event.char == 'k') {
      state.selected = (state.selected - 1).clamp(0, items.length - 1);
      return true;
    }
    if (event.key == NamedKey.pageDown) {
      state.selected = (state.selected + 10).clamp(0, items.length - 1);
      return true;
    }
    if (event.key == NamedKey.pageUp) {
      state.selected = (state.selected - 10).clamp(0, items.length - 1);
      return true;
    }
    if (event.key == NamedKey.home) {
      state.selected = 0;
      return true;
    }
    if (event.key == NamedKey.end) {
      state.selected = items.length - 1;
      return true;
    }
    if (event.key == NamedKey.enter) {
      if (state.selected >= 0 && state.selected < items.length) {
        onActivate?.call(items[state.selected], state.selected);
      }
      return true;
    }
    return false;
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty || items.isEmpty) return;
    final visible = area.height ~/ itemHeight;
    if (visible <= 0) return;
    if (state.selected < state.scrollOffset) {
      state.scrollOffset = state.selected;
    } else if (state.selected >= state.scrollOffset + visible) {
      state.scrollOffset = state.selected - visible + 1;
    }
    state.scrollOffset = state.scrollOffset.clamp(0, (items.length - visible).clamp(0, items.length));

    for (var i = 0; i < visible && i + state.scrollOffset < items.length; i++) {
      final idx = i + state.scrollOffset;
      final isSel = idx == state.selected;
      final rect = Rect(area.x, area.y + i * itemHeight, area.width, itemHeight);
      itemBuilder(items[idx], isSel).render(rect, buffer, ctx);
      if (isSel) {
        final sel = selectedStyle ??
            Style(bg: ctx.theme.colors.primary, fg: ctx.theme.colors.background);
        buffer.fillStyle(rect, sel);
      }
    }
  }
}
