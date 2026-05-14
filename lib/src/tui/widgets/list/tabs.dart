import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

class Tabs implements FocusableWidget {
  @override
  final Key id;
  final List<String> tabs;
  final int selected;
  final void Function(int index)? onTabSelected;
  final Style? activeStyle;
  final Style? inactiveStyle;

  const Tabs({
    required this.id,
    required this.tabs,
    required this.selected,
    this.onTabSelected,
    this.activeStyle,
    this.inactiveStyle,
  });

  @override
  bool get isSkipped => false;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) {
    sink.add(area, id);
    var x = area.x;
    for (var i = 0; i < tabs.length; i++) {
      final w = tabs[i].length + 4;
      sink.add(
        Rect(x, area.y, w, area.height),
        Key.composite([id, 'tab', i]),
      );
      x += w;
    }
  }

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    if (tabs.isEmpty) return false;
    switch (event.key) {
      case 'ArrowLeft':
      case 'h':
        final next = (selected - 1).clamp(0, tabs.length - 1);
        if (next != selected) onTabSelected?.call(next);
        return true;
      case 'ArrowRight':
      case 'l':
        final next = (selected + 1).clamp(0, tabs.length - 1);
        if (next != selected) onTabSelected?.call(next);
        return true;
    }
    return false;
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    final active = activeStyle ??
        Style(fg: ctx.theme.colors.primary, bold: true, underline: true);
    final inactive = inactiveStyle ?? ctx.theme.text.caption;
    var x = area.x;
    for (var i = 0; i < tabs.length && x < area.right; i++) {
      final label = ' ${tabs[i]} ';
      final s = i == selected ? active : inactive;
      buffer.writeText(x, area.y, label, style: s, maxWidth: area.right - x);
      x += label.length + 1;
    }
  }
}
