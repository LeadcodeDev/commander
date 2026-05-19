import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../widget/widget.dart';

class RadioOption<T> {
  final T value;
  final String label;
  const RadioOption({required this.value, required this.label});
}

class RadioGroup<T> implements FocusableWidget {
  @override
  final Key id;
  final List<RadioOption<T>> options;
  final T? selected;
  final void Function(T)? onChanged;

  const RadioGroup({
    required this.id,
    required this.options,
    this.selected,
    this.onChanged,
  });

  @override
  bool get isSkipped => false;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) {
    sink.add(area, id);
    for (var i = 0; i < options.length && i < area.height; i++) {
      sink.add(
        Rect(area.x, area.y + i, area.width, 1),
        Key.composite([id, 'opt', i]),
      );
    }
  }

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    final idx = options.indexWhere((o) => o.value == selected);
    if (event.key == NamedKey.arrowUp) {
      final next = (idx <= 0 ? options.length - 1 : idx - 1);
      if (next >= 0) onChanged?.call(options[next].value);
      return true;
    }
    if (event.key == NamedKey.arrowDown) {
      final next = (idx + 1) % options.length;
      if (next >= 0) onChanged?.call(options[next].value);
      return true;
    }
    if (event.char == ' ' || event.key == NamedKey.enter) {
      return true;
    }
    return false;
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    final isFocused = ctx.isFocused(id);
    for (var i = 0; i < options.length && i < area.height; i++) {
      final opt = options[i];
      final isSel = opt.value == selected;
      final mark = isSel ? '(•)' : '( )';
      final style = isFocused && isSel
          ? ctx.theme.text.body
              .copyWith(fg: ctx.theme.colors.primary, bold: true)
          : ctx.theme.text.body;
      buffer.writeText(area.x, area.y + i, '$mark ${opt.label}',
          style: style, maxWidth: area.width);
    }
  }
}
