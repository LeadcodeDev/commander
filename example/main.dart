import 'package:commander_ui/commander_ui.dart';
import 'package:commander_ui/src/commander.dart';
import 'package:commander_ui/src/level.dart';

enum Shape { square, circle, triangle }

Future<void> main() async {
  final commander = Commander(level: Level.verbose);
  print('Hello World !');

  final value = await commander.ask('What is your name ?',
      // defaultValue: 'John Doe',
      validate: (value) => switch (value) {
            String(:final isEmpty) when isEmpty => Err('Name cannot be empty'),
            _ => Ok(value),
          });
  // print(value);
}
