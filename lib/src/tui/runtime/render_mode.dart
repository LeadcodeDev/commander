sealed class RenderMode {
  const RenderMode();
  const factory RenderMode.alternateScreen() = AlternateScreenMode;
  const factory RenderMode.inline({required int height}) = InlineMode;
}

final class AlternateScreenMode extends RenderMode {
  const AlternateScreenMode();
}

final class InlineMode extends RenderMode {
  final int height;
  const InlineMode({required this.height});
}
