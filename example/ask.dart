import 'package:commander_ui/src/commander.dart';
import 'package:commander_ui/src/level.dart';

enum Shape { square, circle, triangle }

Future<void> main() async {
  final commander = Commander(level: Level.verbose);
  print('Hello World !');

  final value = await commander.ask('What is your name ?',
      // defaultValue: 'John Doe',
      validate: (value) {
    return switch (value) {
      String(:final isEmpty) when isEmpty => 'Name cannot be empty',
      _ => null,
    };
  });

  print(value);
}
