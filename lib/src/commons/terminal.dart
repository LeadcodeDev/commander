import 'package:commander_ui/src/domain/models/terminal.dart';

mixin TerminalTools {
  Stream<List<int>> get stdinStream => _switch((terminal) => terminal.stream);

  void enableRawMode() => _switch((terminal) => terminal.enableRawMode());

  void disableRawMode() => _switch((terminal) => terminal.disableRawMode);

  T _switch<T>(T Function(Terminal) payload) => switch (Terminal.terminal) {
        Terminal terminal => payload(terminal),
        _ => throw Exception('Terminal not initialized'),
      };
}
