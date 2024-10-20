import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:commander_ui/old_src/commons/terminal.dart';
import 'package:commander_ui/old_src/infrastructure/key_down_listener.dart';
import 'package:commander_ui/old_src/infrastructure/models/key_down.dart';

/// Listens to key down events and executes the corresponding callbacks.
class KeyDownEventListener with TerminalTools {
  StreamSubscription? sigintSubscription;
  late StreamSubscription<String>? subscription;
  final List<KeyDownListener> listeners = [];
  FutureOr<void> Function(KeyDown key, void Function())? fallback;
  Function(void Function() dispose)? exitHandler;

  /// Creates a new instance of [KeyDownEventListener] and starts listening to key down events.
  KeyDownEventListener() {
    subscription = terminal.stream.transform(utf8.decoder).listen((data) {
      final key = KeyDown.match(data);
      if (key case KeyDown.unknown) {
        return;
      }

      if (key == KeyDown.ctrlC) {
        exitHandler?.call(dispose);
        return;
      }

      final listener = listeners.firstWhereOrNull((listener) => listener.key == key);

      if (listener case KeyDownListener listener) {
        listener.callback(key, dispose);
        return;
      }

      if (fallback != null) {
        fallback!(key, dispose);
      }
    });
  }

  /// Adds a new listener for the specified [key].
  /// When the [key] is pressed, the [callback] is executed.
  void match(List<KeyDown> keys, void Function(KeyDown key, void Function() dispose) callback) {
    for (var key in keys) {
      listeners.add(KeyDownListener(key, callback));
    }
  }

  /// Sets a fallback listener that is called when a key is pressed that does not have a specific listener.
  void catchAll(FutureOr<void> Function(KeyDown key, void Function() dispose) callback) {
    fallback = callback;
  }

  /// Sets a listener that is called when the application is about to exit.
  onExit(Function(void Function() dispose) callback) {
    exitHandler = callback;
  }

  /// Disposes the listener, stopping it from listening to key down events.
  void dispose() {
    subscription?.cancel();
    subscription = null;

    sigintSubscription?.cancel();
    sigintSubscription = null;

    terminal.disableRawMode();
  }
}
