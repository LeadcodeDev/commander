import 'package:commander_ui/src/infrastructure/models/key_down.dart';

/// Represents a listener for a specific key.
final class KeyDownListener {
  /// The key that this listener is listening to.
  final KeyDown key;

  /// The callback that is executed when the key is pressed.
  final void Function(KeyDown, void Function()) callback;

  /// Creates a new instance of [KeyDownListener] for the specified [key] and [callback].
  KeyDownListener(this.key, this.callback);
}
