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

  Future<void> shutdown();

  factory Terminal() =>
      Platform.isWindows ? WindowsTerminal() : UnixTerminal();
}
