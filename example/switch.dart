import 'package:commander_ui/src/components/switch.dart';

Future<void> main() async {
  final component = Switch(
    answer: 'What is your name?',
    defaultValue: true,
  );

  final value = await component.handle();
  print(value);
}
