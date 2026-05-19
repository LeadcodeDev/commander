import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

class Spinner implements Widget {
  final int frame;
  final List<String> frames;
  final Style? style;
  final String? label;
  final Key? tickerKey;
  final Duration interval;

  const Spinner({
    this.frame = 0,
    this.frames = const ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'],
    this.style,
    this.label,
    this.tickerKey,
    this.interval = const Duration(milliseconds: 80),
  });

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    final s = style ?? Style(fg: ctx.theme.colors.primary);
    final effectiveKey =
        tickerKey ?? Key.composite([#__spinner, area.x, area.y]);
    final entry = ctx.async_.useStream<int>(
      effectiveKey,
      () => _ticker(interval),
    );
    final tick = entry.value ?? frame;
    final ch = frames[tick % frames.length];
    final text = label != null ? '$ch $label' : ch;
    buffer.writeText(area.x, area.y, text, style: s, maxWidth: area.width);
  }
}

Stream<int> _ticker(Duration interval) async* {
  var i = 0;
  yield i;
  while (true) {
    await Future.delayed(interval);
    yield ++i;
  }
}
