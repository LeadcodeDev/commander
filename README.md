# Commander

Commander is a Dart library for creating user interfaces within the terminal.

It provides interactive components such as option selection and text input with advanced management of
user input.

## Installation

To use Commander in your Dart project, add this to your `pubspec.yaml` file :
```yaml
dependencies:
  commander: ^1.0.0
```

Then run `pub get` to install the dependencies.

## Utilisation

A simple example of using Commander to create an option selection component :

```dart
- [x] Placeholder
- [x] Searchable values
- [x] Selected line custom style
- [x] Unselected line custom style
- [x] Display transformer
- [ ] Count limitation (actually defined as 5)

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
```

A simple example of using Commander to create an input component :

- [x] Placeholder
- [x] Validator with error message as callback
- [ ] Default value

```dart
final input = Input(
  answer: 'Please give us your name',
  placeholder: 'firstname lastname',
  validate: (value) => switch(value) {
    String value when value.trim().isNotEmpty => Ok(null),
    _ => Err('Please provide a valid name')
  }
);
```
