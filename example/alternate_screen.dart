import 'dart:math';

import 'package:commander_ui/src/components/alternate_screen.dart';

Future<void> main() async {
  final screen = AlternateScreen(title: 'Hello World !');
  screen.start();

  print('Hello World !');

  await wait();
  screen.stop();
}

Future<void> wait() =>
    Future.delayed(Duration(seconds: Random().nextInt(3) + 1));
