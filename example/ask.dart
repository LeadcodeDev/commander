import 'package:commander_ui/commander_ui.dart';
import 'package:commander_ui/src/application/themes/default_ask_theme.dart';

Future<void> main() async {
  final theme = DefaultAskTheme.copyWith(askPrefix: '🤖');

  final commander = Commander(level: Level.verbose);

  final value = await commander.ask('What is your name ?',
      // defaultValue: 'John Doe',
      validate: (value) {
    return switch (value) {
      String(:final isEmpty) when isEmpty => 'Name cannot be empty',
      _ => null,
    };
  });

  print(value);
}
