import 'dart:async';
import 'dart:io';

import '../geometry/size.dart';
import '../runtime/event.dart';
import 'unix_terminal.dart';
import 'windows_terminal.dart';

abstract interface class Terminal {
  Size get size;
  Stream<Event> get events;

  void enterRawMode();
  void leaveRawMode();
  void enterAlternateScreen();
  void leaveAlternateScreen();
  void hideCursor();
  void showCursor();
  void enableMouse();
  void disableMouse();
  void write(String data);
  Future<void> flush();
  void moveTo(int x, int y);
  void setTitle(String title);
  Future<(int, int)> queryCursorPosition({
    Duration timeout = const Duration(milliseconds: 500),
  });

  /// Lightweight cleanup: restore terminal modes (raw off, cursor on,
  /// mouse off, alternate screen off) without tearing down stdin
  /// subscriptions or event streams. Safe to call between successive
  /// `runTerminal` invocations that share this terminal.
  Future<void> restore();

  /// Full teardown: releases stdin subscriptions, closes event streams,
  /// frees native resources. After this, the terminal is unusable —
  /// process exit will collect anything left behind.
  Future<void> shutdown();

  factory Terminal() =>
      Platform.isWindows ? WindowsTerminal() : UnixTerminal();
}
