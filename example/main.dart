import 'dart:io';

import 'package:mansion/mansion.dart';

void main() async {
  stdout.writeAnsi(Clear.all);
  stdout.writeAnsi(CursorPosition.reset);
  await wait();

  // Move to (10, 10).
  stdout.writeln('Moving to (2, 10).');
  stdout.writeAnsi(const CursorPosition.moveTo(2, 10));
  stdout.writeln('Hello, World!');
  await wait();

  // Move to column 5.
  stdout.writeln('Moving to column 5.');
  stdout.writeAnsi(const CursorPosition.moveToColumn(5));
  await wait();

  // Move to the left.
  stdout.writeln('Moving to the right by 10.');
  stdout.writeAnsi(const CursorPosition.moveRight(10));
  stdout.writeln('Hello, World!');
  await wait();
}

Future<void> wait() => Future.delayed(const Duration(milliseconds: 300));
