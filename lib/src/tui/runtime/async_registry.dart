import 'dart:async';

import 'key.dart';

enum AsyncStatus { unknown, loading, success, error, failure }

class AsyncEntry<T> {
  AsyncStatus status = AsyncStatus.loading;
  T? value;
  Object? error;
  StackTrace? stack;
  Object? failure;
  bool active = false;
  StreamSubscription? subscription;
  Future? future;
  Object? gen;

  void cancel() {
    active = false;
    subscription?.cancel();
    subscription = null;
  }
}

class AsyncRegistry {
  final Map<Key, AsyncEntry> _entries = {};
  final Set<Key> _seenThisFrame = {};
  void Function(Key)? onResolved;

  void beginFrame() {
    _seenThisFrame.clear();
  }

  void endFrame() {
    final toRemove = <Key>[];
    for (final k in _entries.keys) {
      if (!_seenThisFrame.contains(k)) toRemove.add(k);
    }
    for (final k in toRemove) {
      _entries.remove(k)?.cancel();
    }
  }

  AsyncEntry<T> useFuture<T>(Key key, Future<T> Function() factory) {
    _seenThisFrame.add(key);
    final existing = _entries[key];
    if (existing != null) return existing as AsyncEntry<T>;
    final entry = AsyncEntry<T>();
    entry.active = true;
    _entries[key] = entry;
    final gen = Object();
    entry.gen = gen;
    final fut = factory();
    entry.future = fut;
    fut.then((value) {
      if (entry.gen != gen || !entry.active) return;
      entry.status = AsyncStatus.success;
      entry.value = value;
      onResolved?.call(key);
    }, onError: (e, st) {
      if (entry.gen != gen || !entry.active) return;
      entry.status = AsyncStatus.error;
      entry.error = e;
      entry.stack = st;
      onResolved?.call(key);
    });
    return entry;
  }

  AsyncEntry<T> useStream<T>(Key key, Stream<T> Function() factory) {
    _seenThisFrame.add(key);
    final existing = _entries[key];
    if (existing != null) return existing as AsyncEntry<T>;
    final entry = AsyncEntry<T>();
    entry.active = true;
    _entries[key] = entry;
    final gen = Object();
    entry.gen = gen;
    entry.subscription = factory().listen((value) {
      if (entry.gen != gen || !entry.active) return;
      entry.status = AsyncStatus.success;
      entry.value = value;
      onResolved?.call(key);
    }, onError: (e, st) {
      if (entry.gen != gen || !entry.active) return;
      entry.status = AsyncStatus.error;
      entry.error = e;
      entry.stack = st;
      onResolved?.call(key);
    }, onDone: () {
      if (entry.gen != gen || !entry.active) return;
      entry.status = AsyncStatus.success;
      onResolved?.call(key);
    });
    return entry;
  }

  void invalidate(Key key) {
    final entry = _entries.remove(key);
    entry?.cancel();
  }

  void retry(Key key) {
    final entry = _entries[key];
    if (entry == null) return;
    if (entry.status == AsyncStatus.error ||
        entry.status == AsyncStatus.failure) {
      _entries.remove(key);
      entry.cancel();
    }
  }

  AsyncStatus statusOf(Key key) =>
      _entries[key]?.status ?? AsyncStatus.unknown;

  void disposeAll() {
    for (final e in _entries.values) {
      e.cancel();
    }
    _entries.clear();
  }
}
