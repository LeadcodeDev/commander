/// A [StateError] thrown when input is requested in
/// an environment where no terminal is attached.
final class NoTerminalAttachedError extends StateError {
  NoTerminalAttachedError() : super('''
No terminal attached to stdout.
Ensure a terminal is attached via "stdout.hasTerminal" before requesting input.
''');
}
