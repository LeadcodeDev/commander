import 'dart:async';

import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/render_context.dart';
import '../../widget/widget.dart';

class ChainCancelled implements Exception {
  const ChainCancelled();
}

class _HistoryEntry {
  final Widget widget;
  final Object? value;
  _HistoryEntry(this.widget, this.value);
}

class ChainFlowState {
  bool started = false;
  bool completed = false;
  bool cancelled = false;
  Widget? currentWidget;
  Completer<dynamic>? currentCompleter;
  final List<_HistoryEntry> _history = [];

  /// Number of completed steps so far.
  int get length => _history.length;

  /// Collected values from completed steps.
  List<Object?> get values =>
      _history.map((e) => e.value).toList(growable: false);
}

class ChainFlowContext {
  final ChainFlowState _state;
  final void Function() _onRequestRedraw;

  ChainFlowContext._(this._state, this._onRequestRedraw);

  Future<T> draw<T>(Widget widget) {
    if (_state.cancelled) {
      return Future.error(const ChainCancelled());
    }
    _state.currentWidget = widget;
    final c = Completer<T>();
    _state.currentCompleter = c;
    _onRequestRedraw();
    return c.future;
  }

  void complete<T>(T value) {
    final completer = _state.currentCompleter;
    if (completer == null || completer.isCompleted) return;
    final widget = _state.currentWidget;
    if (widget != null) {
      _state._history.add(_HistoryEntry(widget, value));
    }
    _state.currentWidget = null;
    _state.currentCompleter = null;
    completer.complete(value);
    _onRequestRedraw();
  }

  void cancel() {
    if (_state.cancelled) return;
    _state.cancelled = true;
    final completer = _state.currentCompleter;
    _state.currentCompleter = null;
    _state.currentWidget = null;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(const ChainCancelled());
    }
    _onRequestRedraw();
  }

  List<Object?> get history =>
      _state._history.map((e) => e.value).toList(growable: false);

  int get index => _state._history.length;
}

typedef ChainFlowFn = Future<void> Function(ChainFlowContext ctx);

class Chain implements Widget {
  final ChainFlowState state;
  final ChainFlowFn flow;
  final void Function(List<Object?> values)? onComplete;
  final void Function(Object error, StackTrace stack)? onError;
  final int Function(Widget widget)? heightOf;
  final int spacing;

  const Chain.flow({
    required this.state,
    required this.flow,
    this.onComplete,
    this.onError,
    this.heightOf,
    this.spacing = 0,
  });

  int _measure(Widget w) {
    if (heightOf != null) return heightOf!(w);
    if (w is SizedWidget) return w.height;
    return 1;
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (!state.started) {
      state.started = true;
      final chainCtx = ChainFlowContext._(state, ctx.requestRedraw);
      flow(chainCtx).then((_) {
        if (state.cancelled) return;
        state.completed = true;
        state.currentWidget = null;
        state.currentCompleter = null;
        final values =
            state._history.map((e) => e.value).toList(growable: false);
        onComplete?.call(values);
        ctx.requestRedraw();
      }).catchError((Object e, StackTrace st) {
        if (e is ChainCancelled) return;
        onError?.call(e, st);
      });
    }

    if (state.cancelled) return;

    var y = area.y;
    for (final entry in state._history) {
      final h = _measure(entry.widget);
      final rect = Rect(area.x, y, area.width, h);
      ctx.draw(entry.widget, rect);
      y += h + spacing;
    }

    final current = state.currentWidget;
    if (current != null) {
      final h = _measure(current);
      final rect = Rect(area.x, y, area.width, h);
      ctx.draw(current, rect);
    }
  }
}
