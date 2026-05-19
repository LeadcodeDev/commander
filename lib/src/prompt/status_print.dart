import 'dart:io';

import 'package:mansion/mansion.dart';

enum _Kind { success, info, warn, error }

void _write(_Kind kind, String message, IOSink? sink) {
  final out = sink ?? stdout;
  final (icon, color) = switch (kind) {
    _Kind.success => ('✓', Color4.brightGreen),
    _Kind.info => ('ℹ', Color4.brightBlue),
    _Kind.warn => ('!', Color4.yellow),
    _Kind.error => ('✗', Color4.red),
  };
  out.writeAnsiAll([
    SetStyles(Style.foreground(color), Style.bold),
    Print(icon),
    SetStyles.reset,
    Print(' '),
    Print(message),
    AsciiControl.lineFeed,
  ]);
}

void writeSuccess(String message, {IOSink? sink}) =>
    _write(_Kind.success, message, sink);

void writeInfo(String message, {IOSink? sink}) =>
    _write(_Kind.info, message, sink);

void writeWarn(String message, {IOSink? sink}) =>
    _write(_Kind.warn, message, sink);

void writeError(String message, {IOSink? sink}) =>
    _write(_Kind.error, message, sink);
