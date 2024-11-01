import 'package:commander_ui/src/commander.dart';
import 'package:commander_ui/src/level.dart';

Future<void> sleep() => Future.delayed(Duration(seconds: 1));

Future<String> sleepWithValue() => Future.delayed(Duration(seconds: 1), () => 'Hello World !');

Future<void> main() async {
  final commander = Commander(level: Level.verbose);

  final successTask = await commander.task();
  await successTask.step('Success step 1', callback: sleepWithValue);
  await successTask.step('Success step 2', callback: sleep);
  successTask.success('Success task data are available !');

  final warnTask = await commander.task();
  await warnTask.step('Warn step 1', callback: sleepWithValue);
  await warnTask.step('Warn step 2', callback: sleep);
  await warnTask.step('Warn step 3', callback: sleep);
  warnTask.warn('Warn task !');

  final errorTask = await commander.task();
  await errorTask.step('Error step 1', callback: sleepWithValue);
  await errorTask.step('Error step 2', callback: sleep);
  await errorTask.step('Error step 3', callback: sleep);
  errorTask.error('Error task !');
}
