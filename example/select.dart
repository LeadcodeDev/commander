import 'package:commander_ui/commander_ui.dart';

final class Item {
  final String name;
  final int value;

  Item(this.name, this.value);
}

Future<void> main() async {
  StdinBuffer.initialize();

  final select = Select(
      answer: "Please select your best hello",
      options: List.generate(20, (index) => Item('${index + 1}. Hello World', index + 1)),
      placeholder: 'Type to filter',
      selectedLineStyle: (line) => '${AsciiColors.green('❯')} ${AsciiColors.lightCyan(line)}',
      unselectedLineStyle: (line) => '  $line',
      onDisplay: (item) => item.name
  );

  final selected = switch(await select.handle()) {
    Ok(:final value) => 'My value is ${value.value}',
    Err(:final error) => Exception('Error: $error'),
    _ => 'Unknown',
  };

  print(selected);
}
