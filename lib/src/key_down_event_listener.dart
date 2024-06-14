import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:commander_ui/src/application/stdin_buffer.dart';
import 'package:commander_ui/src/commons/ansi_character.dart';

class KeyDownEventListener {
  StreamSubscription? sigintSubscription;
  late StreamSubscription<String>? subscription;
  final List<KeyDownListener> listeners = [];
  FutureOr<void> Function(String, void Function())? fallback;

  KeyDownEventListener() {
    subscription = StdinBuffer.stream.transform(utf8.decoder).listen((data) {
      final listener =
          listeners.firstWhereOrNull((listener) => listener.key.value == data);
      if (listener case KeyDownListener listener) {
        listener.callback(data, dispose);
        return;
      }

      if (fallback != null) {
        fallback!(data, dispose);
      }
    });
  }

  void match(AnsiCharacter key,
      void Function(String, void Function() dispose) callback) {
    listeners.add(KeyDownListener(key, callback));
  }

  void catchAll(
      FutureOr<void> Function(String, void Function() dispose) callback) {
    fallback = callback;
  }

  onExit(Function(void Function() dispose) callback) {
    sigintSubscription = ProcessSignal.sigint.watch().listen((event) {
      callback(dispose);
    });
  }

  void dispose() {
    subscription?.cancel();
    subscription = null;

    sigintSubscription?.cancel();
    sigintSubscription = null;
  }
}

final class KeyDownListener {
  final AnsiCharacter key;
  final void Function(String, void Function()) callback;

  KeyDownListener(this.key, this.callback);
}
