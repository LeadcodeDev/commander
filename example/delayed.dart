import 'dart:math';

import 'package:commander_ui/commander_ui.dart';

Future<void> main() async {
  final delayed = Delayed();

  delayed.step('Fetching data from remote api...');

  await wait();

  delayed.step('Find remote location...');

  await wait();

  delayed.step('Extract data...');

  await wait();

  delayed.success('Data are available !');
}

Future<void> wait() =>
    Future.delayed(Duration(seconds: Random().nextInt(3) + 1));
