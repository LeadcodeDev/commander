import 'package:commander_ui/commander_ui.dart';

Future<void> main() async {
  final commander = Commander(level: Level.verbose);

  final value = await commander.ask('What is your name ?',
      validate: (validator) =>
          validator..notEmpty(message: 'Name cannot be empty :)'));

  print(value);
}
