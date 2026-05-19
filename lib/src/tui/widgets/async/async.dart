import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/async_registry.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../utils/result.dart';
import '../../widget/widget.dart';

class Async<T> implements Widget {
  final Key key;
  final Future<T> Function() future;
  final Widget Function() onLoading;
  final Widget Function(T value) onSuccess;
  final Widget Function(Object error, StackTrace? stack) onError;

  const Async({
    required this.key,
    required this.future,
    required this.onLoading,
    required this.onSuccess,
    required this.onError,
  });

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    final entry = ctx.async_.useFuture<T>(key, future);
    final widget = switch (entry.status) {
      AsyncStatus.success => onSuccess(entry.value as T),
      AsyncStatus.error => onError(entry.error ?? 'unknown', entry.stack),
      AsyncStatus.loading ||
      AsyncStatus.unknown ||
      AsyncStatus.failure =>
        onLoading(),
    };
    ctx.draw(widget, area);
  }
}

class AsyncResult<T, E> implements Widget {
  final Key key;
  final Future<Result<T, E>> Function() future;
  final Widget Function() onLoading;
  final Widget Function(T value) onSuccess;
  final Widget Function(E failure) onFailure;
  final Widget Function(Object error, StackTrace? stack) onError;

  const AsyncResult({
    required this.key,
    required this.future,
    required this.onLoading,
    required this.onSuccess,
    required this.onFailure,
    required this.onError,
  });

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    final entry = ctx.async_.useFuture<Result<T, E>>(key, future);
    Widget widget;
    switch (entry.status) {
      case AsyncStatus.success:
        final r = entry.value as Result<T, E>;
        widget = switch (r) {
          Ok(:final value) => onSuccess(value),
          Err(:final error) => onFailure(error),
        };
      case AsyncStatus.error:
        widget = onError(entry.error ?? 'unknown', entry.stack);
      case AsyncStatus.loading:
      case AsyncStatus.unknown:
      case AsyncStatus.failure:
        widget = onLoading();
    }
    ctx.draw(widget, area);
  }
}

class AsyncStream<T> implements Widget {
  final Key key;
  final Stream<T> Function() stream;
  final Widget Function() onLoading;
  final Widget Function(T value) onData;
  final Widget Function()? onDone;
  final Widget Function(Object error, StackTrace? stack) onError;

  const AsyncStream({
    required this.key,
    required this.stream,
    required this.onLoading,
    required this.onData,
    required this.onError,
    this.onDone,
  });

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    final entry = ctx.async_.useStream<T>(key, stream);
    Widget widget;
    if (entry.status == AsyncStatus.error) {
      widget = onError(entry.error ?? 'unknown', entry.stack);
    } else if (entry.value != null) {
      widget = onData(entry.value as T);
    } else {
      widget = onLoading();
    }
    ctx.draw(widget, area);
  }
}
