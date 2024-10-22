import 'package:commander_ui/src/commander.dart';
import 'package:commander_ui/src/level.dart';

enum Person {
  alice('Alice'),
  bob('Bob'),
  charlie('Charlie'),
  david('David'),
  eve('Eve'),
  frank('Frank'),
  john('John');

  final String value;
  const Person(this.value);
}

Future<void> main() async {
  final commander = Commander(level: Level.verbose);
  print('Hello World !');

  final value = await commander.select<Person>('What is your name ?',
      defaultValue: Person.bob,
      onDisplay: (person) => person.value,
      options: Person.values);

  print(value);
}
