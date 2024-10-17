import 'dart:math';

import 'package:commander_ui/commander_ui.dart';

Future<void> main() async {
  final screen = AlternateScreen(title: 'Hello World !');
  screen.start();

  print('Hello World !');

  await wait();

  final screen2 = AlternateScreen(title: 'Hello World !');
  screen2.start();

  print('Hello World ! 2');

  await wait();
}

Future<void> wait() =>
    Future.delayed(Duration(seconds: Random().nextInt(3) + 1));
