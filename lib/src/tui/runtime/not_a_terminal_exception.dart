class NotATerminalException implements Exception {
  final String message;
  final bool stdinIsTty;
  final bool stdoutIsTty;

  const NotATerminalException({
    required this.message,
    required this.stdinIsTty,
    required this.stdoutIsTty,
  });

  @override
  String toString() => 'NotATerminalException: $message';
}
