import 'package:mansion/mansion.dart';

typedef StdoutStyle = String? Function(String? message);

final class CommanderTheme {
  late final StdoutStyle info;
  late final StdoutStyle warn;
  late final StdoutStyle error;
  late final StdoutStyle success;
  late final StdoutStyle alert;
  late final StdoutStyle debug;

  CommanderTheme({
    StdoutStyle? info,
    StdoutStyle? warn,
    StdoutStyle? error,
    StdoutStyle? success,
    StdoutStyle? alert,
    StdoutStyle? debug,
  }) {
    this.info = info ?? (message) => message;
    this.warn = warn ?? (message) => message;
    this.error = error ?? (message) => message;
    this.success = success ?? (message) => message;
    this.alert = alert ?? (message) => message;
    this.debug = debug ?? (message) => message;
  }

  factory CommanderTheme.initial() => CommanderTheme(
      info: infoFormatter,
      success: successFormatter,
      warn: warnFormatter,
      error: errorFormatter,
      alert: alertFormatter,
      debug: debugFormatter);
}

String infoFormatter(String? message) {
  final buffer = StringBuffer()
    ..writeAnsiAll([
      SetStyles(Style.foreground(Color.green)),
      Print('ℹ'),
      SetStyles.reset,
      Print(' $message'),
      SetStyles.reset,
    ]);

  return buffer.toString();
}

String successFormatter(String? message) {
  final buffer = StringBuffer()
    ..writeAnsiAll([
      SetStyles(Style.foreground(Color.green)),
      Print('✔'),
      SetStyles.reset,
      Print(' $message'),
      SetStyles.reset,
    ]);

  return buffer.toString();
}

String warnFormatter(String? message) {
  final buffer = StringBuffer()
    ..writeAnsiAll([
      SetStyles(Style.foreground(Color.yellow), Style.bold),
      Print('⚠'),
      SetStyles.reset,
      Print(' $message'),
      SetStyles.reset,
    ]);

  return buffer.toString();
}

String errorFormatter(String? message) {
  final buffer = StringBuffer()
    ..writeAnsiAll([
      SetStyles(Style.foreground(Color.brightRed), Style.bold),
      Print('✘'),
      SetStyles.reset,
      Print(' $message'),
      SetStyles.reset,
    ]);

  return buffer.toString();
}

String alertFormatter(String? message) {
  final buffer = StringBuffer()
    ..writeAnsiAll([
      SetStyles(Style.background(Color.red), Style.foreground(Color.white)),
      Print(' $message'),
      SetStyles.reset,
    ]);

  return buffer.toString();
}

String debugFormatter(String? message) {
  final buffer = StringBuffer()
    ..writeAnsiAll([
      SetStyles(Style.foreground(Color.brightBlack)),
      Print(' $message'),
      SetStyles.reset,
    ]);

  return buffer.toString();
}
