import 'dart:io';

void main() {
  // Active le mode brut pour capturer les caractères directement
  stdin.echoMode = false;
  stdin.lineMode = false;

  print('Appuie sur les touches (incluant les flèches), appuie sur Ctrl+C pour quitter.');

  List<int> buffer = [];

  stdin.listen((List<int> input) {
    for (var byte in input) {
      buffer.add(byte);

      // Affiche la valeur ASCII ou Unicode selon la plage
      if (byte < 128) {
        print('ASCII: \\x${byte.toRadixString(16).padLeft(2, '0')} (Caractère: ${String.fromCharCode(byte)})');
      } else {
        print('Unicode: \\u${byte.toRadixString(16).padLeft(4, '0')} (Caractère: ${String.fromCharCode(byte)})');
      }

      // Vérifie si c'est le début d'une séquence échappée
      if (byte == 27 && buffer.length == 1) {
        // Attend d'autres caractères pour identifier une séquence d'échappement complète
        continue;
      }

      // Si on a détecté une séquence d'échappement (par exemple, une flèche directionnelle)
      if (buffer.length >= 3 && buffer[0] == 27 && buffer[1] == 91) {
        String ansiSequence = '';

        switch (buffer[2]) {
          case 65: // 'A' (Flèche haut)
            ansiSequence = '\\u001b[A';
            break;
          case 66: // 'B' (Flèche bas)
            ansiSequence = '\\u001b[B';
            break;
          case 67: // 'C' (Flèche droite)
            ansiSequence = '\\u001b[C';
            break;
          case 68: // 'D' (Flèche gauche)
            ansiSequence = '\\u001b[D';
            break;
        }

        if (ansiSequence.isNotEmpty) {
          print('Séquence ANSI: ${ansiSequence}');
        }

        // Vide le buffer après avoir traité la séquence
        buffer.clear();
      } else if (buffer.length > 3) {
        // Si la séquence ne correspond pas, on vide le buffer (séquence invalide)
        buffer.clear();
      }
    }
  });
}
