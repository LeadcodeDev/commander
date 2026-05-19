import 'dart:io';

abstract interface class CommanderLogger {
  void debug(String message, {Object? data});
  void info(String message, {Object? data});
  void warning(String message, {Object? data});
  void error(String message, {Object? error, StackTrace? stack});
}

class SilentLogger implements CommanderLogger {
  const SilentLogger();
  @override
  void debug(String message, {Object? data}) {}
  @override
  void info(String message, {Object? data}) {}
  @override
  void warning(String message, {Object? data}) {}
  @override
  void error(String message, {Object? error, StackTrace? stack}) {}
}

class StderrLogger implements CommanderLogger {
  const StderrLogger();
  @override
  void debug(String message, {Object? data}) =>
      stderr.writeln('[DEBUG] $message${data != null ? ' $data' : ''}');
  @override
  void info(String message, {Object? data}) =>
      stderr.writeln('[INFO ] $message${data != null ? ' $data' : ''}');
  @override
  void warning(String message, {Object? data}) =>
      stderr.writeln('[WARN ] $message${data != null ? ' $data' : ''}');
  @override
  void error(String message, {Object? error, StackTrace? stack}) {
    stderr.writeln('[ERROR] $message');
    if (error != null) stderr.writeln('  $error');
    if (stack != null) stderr.writeln(stack);
  }
}

class FileLogger implements CommanderLogger {
  final IOSink _sink;
  FileLogger(String path) : _sink = File(path).openWrite(mode: FileMode.append);

  @override
  void debug(String message, {Object? data}) =>
      _write('DEBUG', message, data: data);
  @override
  void info(String message, {Object? data}) =>
      _write('INFO ', message, data: data);
  @override
  void warning(String message, {Object? data}) =>
      _write('WARN ', message, data: data);
  @override
  void error(String message, {Object? error, StackTrace? stack}) {
    _write('ERROR', message, data: error);
    if (stack != null) _sink.writeln(stack);
  }

  void _write(String level, String message, {Object? data}) {
    final time = DateTime.now().toIso8601String();
    _sink.writeln('$time [$level] $message${data != null ? ' :: $data' : ''}');
  }

  Future<void> close() async {
    await _sink.flush();
    await _sink.close();
  }
}
