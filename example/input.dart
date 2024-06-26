import 'package:commander_ui/commander_ui.dart';

Future<void> main() async {
  final input = Input(
    answer: 'What is your name?',
  );

  final value = await input.handle();
  print(value);
}
