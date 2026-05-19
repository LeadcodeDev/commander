import '../../geometry/rect.dart';
import '../../geometry/size.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

class ScrollViewState {
  int offsetY;
  int offsetX;
  int contentHeight;
  int contentWidth;

  ScrollViewState({
    this.offsetY = 0,
    this.offsetX = 0,
    this.contentHeight = 0,
    this.contentWidth = 0,
  });
}

/// Scrollable container.
///
/// Renders [child] into a virtual buffer of size [contentWidth] x [contentHeight]
/// then copies the visible window to the target area, honoring the scroll
/// offsets in [state]. Receives arrow / PageUp/Down / Home/End keys to scroll.
class ScrollView implements FocusableWidget {
  final Key? _id;
  @override
  Key get id => _id ?? ValueKey(state);

  final ScrollViewState state;
  final Widget child;
  final int contentWidth;
  final int contentHeight;
  final bool horizontal;
  final bool showScrollbar;
  final Style? scrollbarStyle;
  final Style? scrollbarThumbStyle;

  const ScrollView({
    Key? id,
    required this.state,
    required this.child,
    required this.contentHeight,
    int? contentWidth,
    this.horizontal = false,
    this.showScrollbar = true,
    this.scrollbarStyle,
    this.scrollbarThumbStyle,
  })  : _id = id,
        contentWidth = contentWidth ?? 0;

  @override
  bool get isSkipped => false;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) => sink.add(area, id);

  int _maxOffsetY(int viewportHeight) =>
      (contentHeight - viewportHeight).clamp(0, contentHeight);
  int _maxOffsetX(int viewportWidth) {
    final w = contentWidth == 0 ? viewportWidth : contentWidth;
    return (w - viewportWidth).clamp(0, w);
  }

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    // We don't know viewport size here; use a generous default that gets
    // clamped on render. Storage is intentionally a count, not pixel.
    const page = 10;
    switch (event.key) {
      case NamedKey.arrowDown:
        state.offsetY += 1;
        return true;
      case NamedKey.arrowUp:
        if (state.offsetY > 0) state.offsetY -= 1;
        return true;
      case NamedKey.pageDown:
        state.offsetY += page;
        return true;
      case NamedKey.pageUp:
        state.offsetY = (state.offsetY - page).clamp(0, contentHeight);
        return true;
      case NamedKey.home:
        state.offsetY = 0;
        if (horizontal) state.offsetX = 0;
        return true;
      case NamedKey.end:
        state.offsetY = contentHeight;
        return true;
      case NamedKey.arrowLeft:
        if (horizontal && state.offsetX > 0) state.offsetX -= 1;
        return horizontal;
      case NamedKey.arrowRight:
        if (horizontal) state.offsetX += 1;
        return horizontal;
      default:
        return false;
    }
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    state.contentHeight = contentHeight;
    if (contentWidth > 0) state.contentWidth = contentWidth;

    final hasVScroll = showScrollbar && contentHeight > area.height;
    final viewportWidth =
        (area.width - (hasVScroll ? 1 : 0)).clamp(0, area.width);
    final viewportHeight = area.height;
    if (viewportWidth <= 0 || viewportHeight <= 0) return;

    final maxY = _maxOffsetY(viewportHeight);
    state.offsetY = state.offsetY.clamp(0, maxY);
    if (horizontal) {
      final maxX = _maxOffsetX(viewportWidth);
      state.offsetX = state.offsetX.clamp(0, maxX);
    } else {
      state.offsetX = 0;
    }

    final renderWidth = contentWidth > 0 ? contentWidth : viewportWidth;
    final renderHeight = contentHeight > 0 ? contentHeight : viewportHeight;

    // Render into a virtual buffer at origin (0,0), then blit window.
    final inner = Buffer(
        Size(renderWidth.clamp(1, 1 << 16), renderHeight.clamp(1, 1 << 16)));
    child.render(Rect(0, 0, inner.width, inner.height), inner, ctx);

    final srcX = state.offsetX;
    final srcY = state.offsetY;
    for (var dy = 0; dy < viewportHeight; dy++) {
      for (var dx = 0; dx < viewportWidth; dx++) {
        final cell = inner.get(srcX + dx, srcY + dy);
        buffer.set(area.x + dx, area.y + dy, cell);
      }
    }

    if (hasVScroll) {
      final track = scrollbarStyle ?? Style(fg: ctx.theme.colors.muted);
      final thumb = scrollbarThumbStyle ??
          Style(fg: ctx.theme.colors.primary, bold: true);
      final trackX = area.x + area.width - 1;
      final ratio = contentHeight == 0
          ? 0.0
          : (viewportHeight / contentHeight).clamp(0.0, 1.0);
      final thumbLen =
          (ratio * viewportHeight).round().clamp(1, viewportHeight);
      final posRatio = maxY == 0 ? 0.0 : state.offsetY / maxY;
      final thumbStart = (posRatio * (viewportHeight - thumbLen))
          .round()
          .clamp(0, viewportHeight - thumbLen);
      for (var y = 0; y < viewportHeight; y++) {
        final isThumb = y >= thumbStart && y < thumbStart + thumbLen;
        buffer.setChar(trackX, area.y + y, isThumb ? '█' : '│',
            style: isThumb ? thumb : track);
      }
    }
  }
}
