import 'package:commander_ui/src/components/checkbox.dart';

Future<void> main() async {
  final checkbox = Checkbox(
    answer: 'What is your favorite pet ?',
    options: ['cat', 'dog', 'bird'],
    // max: 1
  );

  final value = await checkbox.handle();
  print(value);
}
