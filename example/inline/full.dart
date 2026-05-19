import 'package:commander_ui/prompt.dart';

Future<void> main() async {
  final commander = InlineCommander();

  final name = await commander.ask(
    'Your name?',
    validate: (v) => v.trim().isEmpty ? 'Name is required' : null,
  );

  commander.info('Hi $name, a few questions…');

  final age = await commander.number(
    'Your age?',
    min: 0,
    max: 150,
    defaultValue: 30,
  );

  final language = await commander.select<String>(
    'Pick a language',
    options: ['Dart', 'Rust', 'TypeScript', 'Go'],
    defaultValue: 'Dart',
  );

  final tools = await commander.multiSelect<String>(
    'Pick the tools you use',
    options: ['Git', 'Docker', 'Make', 'Bazel', 'Just'],
    defaults: ['Git'],
    minSelections: 1,
  );

  final newsletter = await commander.confirm(
    'Subscribe to the newsletter?',
    defaultValue: true,
  );

  await commander.task('Saving profile', () async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
  });

  commander.success(
    'Profile saved — $name, $age years, $language, ${tools.join("/")}, '
    'newsletter: ${newsletter ? "yes" : "no"}',
  );

  await commander.dispose();
}
