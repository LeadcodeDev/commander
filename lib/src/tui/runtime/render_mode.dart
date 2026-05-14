sealed class RenderMode {
  const RenderMode();
  const factory RenderMode.alternateScreen() = AlternateScreenMode;
  const factory RenderMode.fullScreen() = FullScreenMode;
  const factory RenderMode.flow({
    int? height,
    int? minHeight,
    bool autoGrow,
  }) = FlowMode;
  const factory RenderMode.inline({required int height}) = InlineMode;
}

final class AlternateScreenMode extends RenderMode {
  const AlternateScreenMode();
}

final class FullScreenMode extends RenderMode {
  const FullScreenMode();
}

final class FlowMode extends RenderMode {
  final int? height;
  final int? minHeight;
  final bool autoGrow;
  const FlowMode({this.height, this.minHeight, this.autoGrow = false});
}

final class InlineMode extends RenderMode {
  final int height;
  const InlineMode({required this.height});
}
