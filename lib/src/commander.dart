import 'dart:async';
import 'dart:io' as io;

import 'package:commander_ui/src/application/components/ask.dart';
import 'package:commander_ui/src/application/components/checkbox.dart';
import 'package:commander_ui/src/application/components/select.dart';
import 'package:commander_ui/src/application/terminals/terminal.dart';
import 'package:commander_ui/src/application/utils/terminal_tools.dart';
import 'package:commander_ui/src/level.dart';

/// Type definition for a function which accepts a log message
/// and returns a styled version of that message.
///
/// Generally, [AnsiCode] values are used to generate a [LogStyle].
///
/// ```dart
/// final alertStyle = (m) => backgroundRed.wrap(styleBold.wrap(white.wrap(m)));
/// ```
typedef LogStyle = String? Function(String? message);

/// A basic Logger which wraps `stdio` and applies various styles.
class Commander with TerminalTools {
  Commander({
    this.level = Level.info,
  });

  /// The current log level for this logger.
  Level level;

  final _queue = <String?>[];

  Never _exit(int code) => io.exit(code);
  final _terminal = Terminal();

  /// Write message via `stdout.write`.
  void write(String? message) => io.stdout.write(message);

  /// Writes delayed message to stdout.
  void delayed(String? message) => _queue.add(message);

  Future<String?> ask(String message,
          {String? defaultValue, bool hidden = false, String? Function(String)? validate}) =>
      Ask(_terminal,
              message: message, defaultValue: defaultValue, hidden: hidden, validate: validate)
          .handle();

  Future<T> select<T>(String message,
          {T? defaultValue,
          required List<T> options,
          String placeholder = '',
          String Function(T)? onDisplay}) =>
      Select<T>(_terminal,
              message: message,
              defaultValue: defaultValue,
              options: options,
              placeholder: placeholder,
              onDisplay: onDisplay)
          .handle();

  Future<List<T>> checkbox<T>(String message,
          {T? defaultValue,
          required List<T> options,
          String placeholder = '',
          bool multiple = false,
          String Function(T)? onDisplay}) =>
      Checkbox<T>(_terminal,
              message: message,
              defaultValue: defaultValue,
              options: options,
              placeholder: placeholder,
              multiple: multiple,
              onDisplay: onDisplay)
          .handle();
}
