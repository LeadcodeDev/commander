# Commander

Commander is a Dart library for creating user interfaces within the terminal.

It provides interactive components such as option selection and text input with advanced management of
user input.

## Installation

To use Commander in your Dart project, add this to your `pubspec.yaml` file :
```yaml
dependencies:
  commander_ui: ^1.3.0
```

Then run `pub get` to install the dependencies.

## Usage

### Input component

A simple example of using Commander to create an input component :

- ✅ Placeholder
- ✅ Validator with error message as callback 
- ❌ Default value

```dart
Future<void> main() async {
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
  
  print(await input.handle());
}
```

### Select component
A simple example of using Commander to create an option selection component :

- ✅ Placeholder
- ✅ Searchable values
- ✅ Selected line custom style
- ✅ Unselected line custom style
- ✅ Display transformer
- ✅ Max display count (default as 5)

```dart
Future<void> main() async {
  final select = Select(
      answer: "Please select your best hello",
      options: List.generate(20, (index) => Item('${index + 1}. Hello World', index + 1)),
      placeholder: 'Type to filter',
      selectedLineStyle: (line) => '${AsciiColors.green('❯')} ${AsciiColors.lightCyan(line)}',
      unselectedLineStyle: (line) => '  $line',
      onDisplay: (item) => item.name,
      displayCount: 4
  );

  final selected = switch(await select.handle()) {
    Ok(:final value) => 'My value is ${value.value}',
    Err(:final error) => Exception('Error: $error'),
    _ => 'Unknown',
  };

  print(selected);
}
```

### Switching component
A simple example of using Commander to create a switch component :

```dart
Future<void> main() async {
  final component = Switch(
    answer: 'Do you love cat ?',
    defaultValue: false,
  );
  
  final value = await component.handle();
  
  final result = switch(value) {
    Ok(:final value) => value.value 
      ? 'I love cat 😍' 
      : 'I hate cat 😕',
    Err(:final error) => Exception('Error: $error'),
    _ => 'Unknown',
  };
}
```
### Delayed component
A simple example of using Commander to create a delayed component :

```dart
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
```

### Progress component
A simple example of using Commander to create a progress component :

```dart
void main() async {
  final progress = ProgressBar(max: 50);

  for (int i = 0; i < 50; i++) {
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
```
