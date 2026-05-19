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
  const FlowMode({this.height, this.minHeight, this.autoGrow = false})
      : assert(height == null || height > 0, 'FlowMode.height must be > 0'),
        assert(minHeight == null || minHeight > 0,
            'FlowMode.minHeight must be > 0');
}

final class InlineMode extends RenderMode {
  final int height;
  const InlineMode({required this.height})
      : assert(height > 0, 'InlineMode.height must be > 0');
}
