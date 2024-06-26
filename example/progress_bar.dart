import 'dart:async';

import 'package:commander_ui/src/components/progress_bar.dart';
import 'package:mansion/mansion.dart';

void main() async {
  final progress = ProgressBar(max: 50);

  for(int i = 0; i < 50; i++) {
    progress.next(message: [Print('Downloading file ${i + 1}/50...')]);
    await Future.delayed(Duration(milliseconds: 50));
  }

  progress.done(message: [
    SetStyles(Style.foreground(Color.green)),
    Print('✔'),
    SetStyles.reset,
    Print(' Download complete!')
  ]);
}
