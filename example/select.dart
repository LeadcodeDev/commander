import 'package:commander_ui/src/commander.dart';
import 'package:commander_ui/src/level.dart';

enum Shape { square, circle, triangle }

Future<void> main() async {
  final commander = Commander(level: Level.verbose);
  print('Hello World !');

  final value = await commander.select('What is your name ?',
      defaultValue: 'Charlie',
      options: ['Alice', 'Bob', 'Charlie', 'David', 'Eve', 'Frank', 'John']
  );

  print(value);
}
