import 'package:commander_ui/src/commander.dart';
import 'package:commander_ui/src/level.dart';

Future<void> main() async {
  final commander = Commander(level: Level.verbose);

  final value = await commander.checkbox(
    'What is your name ?',
    defaultValue: 'Charlie',
    options: ['Alice', 'Bob', 'Charlie', 'David', 'Eve', 'Frank', 'John'],
  );

  print(value);
}
