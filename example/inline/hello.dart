import 'package:commander_ui/prompt.dart';

Future<void> main() async {
  final commander = InlineCommander();

  final name = await commander.ask('Your name?');
  commander.success('Hello $name');

  await commander.dispose();
}
