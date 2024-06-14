# Commander

Commander is a Dart library for creating user interfaces within the terminal.

It provides interactive components such as option selection and text input with advanced management of
user input.

## Installation

To use Commander in your Dart project, add this to your `pubspec.yaml` file :
```yaml
dependencies:
  commander_ui: ^1.1.0
```

Then run `pub get` to install the dependencies.

## Usage

### Input component

A simple example of using Commander to create an input component :

- ✅ Placeholder
- ✅ Validator with error message as callback 
- ❌ Default value

```dart
StdinBuffer.initialize();

final input = Input(
  answer: 'Please give us your name',
  placeholder: 'firstname lastname',
  validate: (value) => switch(value) {
    String value when value.trim().isNotEmpty => Ok(null),
    _ => Err('Please provide a valid name')
  }
);
```

### Select component
A simple example of using Commander to create an option selection component :

- ✅ Placeholder
- ✅ Searchable values
- ✅ Selected line custom style
- ✅ Unselected line custom style
- ✅ Display transformer
- ❌ Count limitation (actually defined as 5)

```dart
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
```
