import 'package:commander_ui/commander_ui.dart';

/// Represents a listener for a specific key.
final class KeyDownListener {
  /// The key that this listener is listening to.
  final AnsiCharacter key;

  /// The callback that is executed when the key is pressed.
  final void Function(String, void Function()) callback;

  /// Creates a new instance of [KeyDownListener] for the specified [key] and [callback].
  KeyDownListener(this.key, this.callback);
}
