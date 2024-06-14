import 'package:commander_ui/commander_ui.dart';

final class Item {
  final String name;
  final int value;

  Item(this.name, this.value);
}

Future<void> main() async {
  StdinBuffer.initialize();

  final input = Input(
      answer: 'Please give us your name',
      placeholder: 'firstname lastname',
      validate: (value) =>
      switch(value) {
        String value when value
            .trim()
            .isNotEmpty => Ok(null),
        _ => Err('Please provide a valid name')
      }
  );

  final value = switch(await input.handle()) {
    Ok(:final value) => 'My value is $value',
    Err(:final error) => Exception('Error: $error'),
    _ => 'Unknown',
  };

  print(value);
}
