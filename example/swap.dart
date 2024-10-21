import 'package:commander_ui/src/commander.dart';
import 'package:commander_ui/src/level.dart';

enum Shape { square, circle, triangle }

Future<void> main() async {
  final commander = Commander(level: Level.verbose);
  print('Hello World !');

  final value = await commander.swap(
    'What is your name ?',
    defaultValue: true,placeholder: 'ff'
  );

  print(value);
}
