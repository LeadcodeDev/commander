import 'package:commander_ui/src/commander.dart';
import 'package:commander_ui/src/level.dart';

Future<void> sleep(int value) => Future.delayed(Duration(seconds: value));

Future<void> main() async {
  final commander = Commander(level: Level.verbose);
  print('Hello World !');

  final screen = commander.screen(title: 'First screen');

  screen.enter();

  await sleep(1);
  print('Hello screen !');
  await sleep(2);

  screen.leave();

  print('Goodbye screen !');
}
