import 'dart:async';
import 'dart:io';

import 'package:commander_ui/src/application/components/ask.dart';
import 'package:commander_ui/src/application/components/checkbox.dart';
import 'package:commander_ui/src/application/components/screen.dart';
import 'package:commander_ui/src/application/components/select.dart';
import 'package:commander_ui/src/application/components/table.dart';
import 'package:commander_ui/src/application/components/task.dart';
import 'package:commander_ui/src/application/components/swap.dart';
import 'package:commander_ui/src/application/terminals/terminal.dart';
import 'package:commander_ui/src/application/utils/terminal_tools.dart';
import 'package:commander_ui/src/domains/models/commander_theme.dart';
import 'package:commander_ui/src/domains/models/component_theme.dart';
import 'package:commander_ui/src/domains/themes/ask_theme.dart';
import 'package:commander_ui/src/domains/themes/checkbox_theme.dart';
import 'package:commander_ui/src/domains/themes/select_theme.dart';
import 'package:commander_ui/src/domains/themes/swap_theme.dart';
import 'package:commander_ui/src/level.dart';

/// Type definition for a function which accepts a log message
/// and returns a styled version of that message.
///
/// A basic Logger which wraps `stdio` and applies various styles.
class Commander with TerminalTools {
  late final CommanderTheme _theme;
  late final ComponentTheme _componentTheme;
  final _terminal = Terminal();

  Level level;

  Commander({
    this.level = Level.info,
    CommanderTheme? theme,
    ComponentTheme? componentTheme,
  })  : _theme = theme ?? CommanderTheme.initial(),
        _componentTheme = componentTheme ?? ComponentTheme();

  /// Write message via `stdout.write`.
  void write(String? message) => stdout.write(message);

  /// Write message via `stdout.write`.
  void writeln(String? message) => stdout.writeln(message);

  /// Write info message to stdout.
  void info(String? message, {StdoutStyle? style}) => writeln((style ?? _theme.info)(message));

  /// Write success message to stdout.
  void success(String? message, {StdoutStyle? style}) =>
      writeln((style ?? _theme.success)(message));

  /// Write warning message to stdout.
  void warn(String? message, {StdoutStyle? style}) => writeln((style ?? _theme.warn)(message));

  /// Write error message to stdout.
  void error(String? message, {StdoutStyle? style}) => writeln((style ?? _theme.error)(message));

  /// Write alert message to stdout.
  void alert(String? message, {StdoutStyle? style}) => writeln((style ?? _theme.alert)(message));

  /// Write debug message to stdout.
  void debug(String? message, {StdoutStyle? style}) => writeln((style ?? _theme.debug)(message));

  Future<T> ask<T>(String message,
          {String? defaultValue,
          bool hidden = false,
          String? Function(String)? validate,
          AskTheme? theme}) =>
      Ask<T>(_terminal,
              message: message,
              defaultValue: defaultValue,
              hidden: hidden,
              validate: validate,
              theme: theme ?? _componentTheme.askTheme)
          .handle();

  Future<T> select<T>(String message,
          {T? defaultValue,
          required List<T> options,
          String placeholder = '',
          int displayCount = 5,
          String Function(T)? onDisplay,
          SelectTheme? theme}) =>
      Select<T>(_terminal,
              message: message,
              defaultValue: defaultValue,
              displayCount: displayCount,
              options: options,
              placeholder: placeholder,
              onDisplay: onDisplay,
              theme: theme ?? _componentTheme.selectTheme)
          .handle();

  Future<List<T>> checkbox<T>(String message,
          {T? defaultValue,
          required List<T> options,
          String placeholder = '',
          bool multiple = false,
          String Function(T)? onDisplay,
          CheckboxTheme? theme}) =>
      Checkbox<T>(_terminal,
              message: message,
              defaultValue: defaultValue,
              options: options,
              placeholder: placeholder,
              multiple: multiple,
              onDisplay: onDisplay,
              theme: theme ?? _componentTheme.checkboxTheme)
          .handle();

  Future<bool> swap<T>(String message,
          {bool defaultValue = false, String? placeholder, SwapTheme? theme}) =>
      Swap<T>(_terminal,
              message: message,
              defaultValue: defaultValue,
              placeholder: placeholder,
              theme: theme ?? _componentTheme.switchTheme)
          .handle();

  Future<StepManager> task<T>({bool colored = false}) => Task(_terminal, colored: colored).handle();

  void table(
          {required List<List<String>> data,
          required List<String> columns,
          bool lineSeparator = false,
          bool columnSeparator = false}) =>
      Table(
              data: data,
              columns: columns,
              lineSeparator: lineSeparator,
              columnSeparator: columnSeparator)
          .handle();

  ScreenManager screen({String? title}) => Screen(title: title).handle();
}
