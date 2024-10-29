import 'package:commander_ui/src/commander.dart';
import 'package:commander_ui/src/level.dart';

Future<void> main() async {
  final commander = Commander(level: Level.verbose);

  final value = await commander.swap('Do you love cats ?', defaultValue: true);
  print(value);
}
