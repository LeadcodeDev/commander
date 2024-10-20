import 'dart:convert';
import 'dart:io';

import 'package:commander_ui/old_src/infrastructure/models/key_down.dart';

void main() {
  // Désactiver l'affichage et le mode ligne pour lire les entrées directement
  stdin.echoMode = false;
  stdin.lineMode = false;

  print('Press any key. Press ESC to exit.');

  stdin.transform(utf8.decoder).listen((data) {
    print([data, KeyDown.match(data)]);
    // final key = KeyDown.fromInput(data);
    //
    // // Affichage des résultats
    // print('Key: $key, Char: ${key.char}, Data: ${data}');
    //
    // // Si ESC est pressé, quitter le programme
    // if (key == KeyDown.escape) {
    //   exit(0);
    // }
  });
}
