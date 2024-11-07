import 'package:commander_ui/commander_ui.dart';

Future<void> main() async {
  final commander = Commander(level: Level.verbose);

  final value = await commander.number('What is your age ?',
      interval: 1,
      onDisplay: (value) => value?.toStringAsFixed(2),
      validate: (validator) => validator
        ..lowerThan(18, message: 'You must be at least 18 years old')
        ..greaterThan(99, message: 'You must be at most 99 years old'));

  print(value);
}
