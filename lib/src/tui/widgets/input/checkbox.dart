import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

class Checkbox implements FocusableWidget {
  @override
  final Key id;
  final bool value;
  final String label;
  final void Function(bool)? onChanged;
  final Style? style;

  const Checkbox({
    required this.id,
    required this.value,
    this.label = '',
    this.onChanged,
    this.style,
  });

  @override
  bool get isSkipped => false;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) {
    sink.add(area, id);
  }

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    if (event.key == NamedKey.enter || event.char == ' ') {
      onChanged?.call(!value);
      return true;
    }
    return false;
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    final isFocused = ctx.isFocused(id);
    final mark = value ? '[x]' : '[ ]';
    final base = style ?? ctx.theme.text.body;
    final s = isFocused
        ? base.copyWith(fg: ctx.theme.colors.primary, bold: true)
        : base;
    final text = label.isEmpty ? mark : '$mark $label';
    buffer.writeText(area.x, area.y, text, style: s, maxWidth: area.width);
  }
}
