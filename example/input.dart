import 'package:commander_ui/commander_ui.dart';
import 'package:commander_ui/src/domain/models/terminal.dart';

Future<void> main() async {
  Terminal.init();

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
