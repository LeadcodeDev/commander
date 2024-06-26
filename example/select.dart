import 'package:commander_ui/commander_ui.dart';

Future<void> main() async {
  final select = Select(
    answer: 'What is your name?',
    options: ['Alice', 'Bob', 'Charlie', 'David', 'Eve'],
  );

  final value = await select.handle();
  print(value.unwrap());
}
