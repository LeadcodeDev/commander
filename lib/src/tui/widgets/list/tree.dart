import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

class TreeNode<T> {
  final T value;
  final String label;
  final List<TreeNode<T>> children;

  const TreeNode({
    required this.value,
    required this.label,
    this.children = const [],
  });

  bool get isLeaf => children.isEmpty;
}

class TreeState<T> {
  int activeIndex;
  int scrollOffset;
  final Set<Object> expanded;

  TreeState({
    this.activeIndex = 0,
    this.scrollOffset = 0,
    Set<Object>? expandedKeys,
  }) : expanded = expandedKeys ?? <Object>{};
}

class _Visible<T> {
  final TreeNode<T> node;
  final int depth;
  final Object key;
  _Visible(this.node, this.depth, this.key);
}

class Tree<T> implements FocusableWidget {
  final Key? _id;
  @override
  Key get id => _id ?? ValueKey(state);

  final List<TreeNode<T>> roots;
  final TreeState<T> state;
  final Object Function(TreeNode<T> node, List<int> path) keyOf;
  final void Function(TreeNode<T> node)? onActivate;
  final void Function(TreeNode<T> node, bool expanded)? onExpansionChanged;

  final String expandedIcon;
  final String collapsedIcon;
  final String leafIcon;
  final int indent;

  final Style? itemStyle;
  final Style? activeStyle;
  final Style? iconStyle;

  const Tree({
    Key? id,
    required this.roots,
    required this.state,
    required this.keyOf,
    this.onActivate,
    this.onExpansionChanged,
    this.expandedIcon = '▼',
    this.collapsedIcon = '▶',
    this.leafIcon = '·',
    this.indent = 2,
    this.itemStyle,
    this.activeStyle,
    this.iconStyle,
  }) : _id = id;

  @override
  bool get isSkipped => false;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) => sink.add(area, id);

  List<_Visible<T>> _flatten() {
    final out = <_Visible<T>>[];
    void visit(TreeNode<T> n, int depth, List<int> path) {
      final k = keyOf(n, path);
      out.add(_Visible(n, depth, k));
      if (!n.isLeaf && state.expanded.contains(k)) {
        for (var i = 0; i < n.children.length; i++) {
          visit(n.children[i], depth + 1, [...path, i]);
        }
      }
    }
    for (var i = 0; i < roots.length; i++) {
      visit(roots[i], 0, [i]);
    }
    return out;
  }

  void _toggle(_Visible<T> v) {
    if (v.node.isLeaf) return;
    if (state.expanded.contains(v.key)) {
      state.expanded.remove(v.key);
      onExpansionChanged?.call(v.node, false);
    } else {
      state.expanded.add(v.key);
      onExpansionChanged?.call(v.node, true);
    }
  }

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    final visible = _flatten();
    if (visible.isEmpty) return false;
    state.activeIndex = state.activeIndex.clamp(0, visible.length - 1);
    final active = visible[state.activeIndex];

    switch (event.key) {
      case NamedKey.arrowUp:
        if (state.activeIndex > 0) state.activeIndex -= 1;
        return true;
      case NamedKey.arrowDown:
        if (state.activeIndex < visible.length - 1) state.activeIndex += 1;
        return true;
      case NamedKey.arrowLeft:
        if (!active.node.isLeaf && state.expanded.contains(active.key)) {
          state.expanded.remove(active.key);
          onExpansionChanged?.call(active.node, false);
          return true;
        }
        // Otherwise jump to parent: find previous item with depth - 1.
        for (var i = state.activeIndex - 1; i >= 0; i--) {
          if (visible[i].depth < active.depth) {
            state.activeIndex = i;
            break;
          }
        }
        return true;
      case NamedKey.arrowRight:
        if (active.node.isLeaf) return true;
        if (!state.expanded.contains(active.key)) {
          state.expanded.add(active.key);
          onExpansionChanged?.call(active.node, true);
        } else if (state.activeIndex < visible.length - 1) {
          state.activeIndex += 1;
        }
        return true;
      case NamedKey.home:
        state.activeIndex = 0;
        return true;
      case NamedKey.end:
        state.activeIndex = visible.length - 1;
        return true;
      case NamedKey.enter:
        if (active.node.isLeaf) {
          onActivate?.call(active.node);
        } else {
          _toggle(active);
        }
        return true;
      default:
        if (event.char == ' ') {
          _toggle(active);
          return true;
        }
        return false;
    }
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    final focused = ctx.isFocused(id);
    final visible = _flatten();
    if (visible.isEmpty) return;
    state.activeIndex = state.activeIndex.clamp(0, visible.length - 1);

    // Keep active in viewport.
    if (state.activeIndex < state.scrollOffset) {
      state.scrollOffset = state.activeIndex;
    } else if (state.activeIndex >= state.scrollOffset + area.height) {
      state.scrollOffset = state.activeIndex - area.height + 1;
    }
    state.scrollOffset = state.scrollOffset.clamp(0, visible.length);

    final base = itemStyle ?? ctx.theme.text.body;
    final activeS = activeStyle ??
        Style(
          fg: ctx.theme.colors.background,
          bg: focused
              ? ctx.theme.colors.primary
              : ctx.theme.colors.foreground,
          bold: true,
        );
    final icon = iconStyle ?? Style(fg: ctx.theme.colors.muted);

    for (var row = 0; row < area.height; row++) {
      final idx = state.scrollOffset + row;
      if (idx >= visible.length) break;
      final v = visible[idx];
      final y = area.y + row;
      final isActive = idx == state.activeIndex;

      final iconChar = v.node.isLeaf
          ? leafIcon
          : (state.expanded.contains(v.key) ? expandedIcon : collapsedIcon);

      final prefix = ' ' * (v.depth * indent);
      final line = '$prefix$iconChar ${v.node.label}';

      // Background fill for active row.
      if (isActive) {
        for (var i = 0; i < area.width; i++) {
          buffer.setChar(area.x + i, y, ' ', style: activeS);
        }
      }

      // Icon
      final iconX = area.x + prefix.length;
      if (iconX < area.right) {
        buffer.writeText(iconX, y, iconChar,
            style: isActive ? activeS : icon, maxWidth: area.right - iconX);
      }
      // Label
      final lblX = iconX + iconChar.length + 1;
      if (lblX < area.right) {
        buffer.writeText(lblX, y, v.node.label,
            style: isActive ? activeS : base, maxWidth: area.right - lblX);
      }
      // Suppress unused
      if (line.isEmpty) {}
    }
  }
}
