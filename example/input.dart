import 'package:commander_ui/commander_ui.dart';

Future<void> main() async {
  final input = Input(
    answer: 'What is your name?',
    placeholder: 'Name',
    defaultValue: 'John Doe',
    validate: (value) {
      if (value.isEmpty) {
        return Err('Name cannot be empty');
      }

      return Ok(value);
    },
  );

  final value = await input.handle();
  print(value);
}
