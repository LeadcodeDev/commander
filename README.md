# Commander

Commander is a Dart library for creating user interfaces within the terminal.

It provides interactive components such as option selection and text input with advanced management of
user input.

## Installation

To use Commander in your Dart project, add this to your `pubspec.yaml` file :
```yaml
dependencies:
  commander_ui: ^2.0.0
```

Then run `pub get` to install the dependencies.

## Usage

### Ask component

A simple example of using Commander to create an ask component :

- ✅ Secure
- ✅ Validator with error message as callback 
- ✅ Default value

```dart
Future<void> main() async {
  final commander = Commander(level: Level.verbose);

  final value = await commander.ask('What is your name ?',
      defaultValue: 'John Doe',
      validate: (value) {
        return switch (value) {
          String(:final isEmpty) when isEmpty => 'Name cannot be empty',
          _ => null,
        };
      });

  print(value);
}
```

### Select component
A simple example of using Commander to create an option selection component :

- ✅ Placeholder
- ✅ Default selected
- ✅ Searchable values
- ✅ Display transformer
- ✅ Max display count (default as 5)

```dart
Future<void> main() async {
  final commander = Commander(level: Level.verbose);

  final value = await commander.select('What is your name ?',
      onDisplay: (value) => value,
      placeholder: 'Type to search',
      defaultValue: 'Charlie',
      options: ['Alice', 'Bob', 'Charlie', 'David', 'Eve', 'Frank', 'John']);

  print(value);
}
```

### Swap component
A simple example of using Commander to create a swap component :

- ✅ Select value with directional arrows

```dart
Future<void> main() async {
  final commander = Commander(level: Level.verbose);

  final value = await commander.swap('Do you love cats', 
    defaultValue: true, 
    placeholder: '🐈'
  );
  
  final str = switch (value) {
    true => 'I love cats 😍',
    false => 'I prefer dogs 😕',
  };

  print(str);
}
```

### Task component
A simple example of using Commander to create a task component :

- ✅ Multiple steps per task
- ✅ Success, warn and error results
- ✅ Sync and async action supports

```dart
Future<void> sleep() => Future.delayed(Duration(seconds: 1));

Future<String> sleepWithValue() =>
    Future.delayed(Duration(seconds: 1), () => 'Hello World !');

Future<void> main() async {
  final commander = Commander(level: Level.verbose);
  print('Hello World !');

  final successTask =
  await commander.task('I am an success task', colored: true);
  await successTask.step('Success step 1', callback: sleepWithValue);
  await successTask.step('Success step 2', callback: sleep);
  successTask.success('Success task data are available !');

  final warnTask = await commander.task('I am an warn task');
  await warnTask.step('Warn step 1', callback: sleepWithValue);
  await warnTask.step('Warn step 2', callback: sleep);
  await warnTask.step('Warn step 3', callback: sleep);
  warnTask.warn('Warn task !');

  final errorTask = await commander.task('I am an error task');
  await errorTask.step('Error step 1', callback: sleepWithValue);
  await errorTask.step('Error step 2', callback: sleep);
  await errorTask.step('Error step 3', callback: sleep);
  errorTask.error('Error task !');
}
```

### Checkbox component
A simple example of using Commander to create a checkbox component :

- ✅ Placeholder
- ✅ Default checked
- ✅ Single or multiple selection
- ✅ Display transforme

```dart
Future<void> main() async {
  final commander = Commander(level: Level.verbose);

  final value = await commander.checkbox(
    'What is your favorite pet ?',
    defaultValue: 'Charlie',
    options: ['cat', 'dog', 'bird'],
  );

  print(value);
}
```

### Table component
A simple example of using Commander to create a table component :

- ✅ Without column and line borders
- ✅ With column and line borders
- ✅ With column borders and without line borders
- ✅ With line borders and without column borders

```dart
Future<void> main() async {
  final commander = Commander(level: Level.verbose);
  commander.table(
    columns: ['Name', 'Age', 'Country', 'City'],
    lineSeparator: false,
    columnSeparator: false,
    data: [
      ['Alice', '20', 'USA', 'New York'],
      ['Bob', '25', 'Canada', 'Toronto'],
      ['Charlie', '30', 'France', 'Paris'],
      ['David', '35', 'Germany', 'Berlin'],
      ['Eve', '40', 'Italy', 'Rome'],
      ['Frank', '45', 'Japan', 'Tokyo'],
      ['John', '50', 'China', 'Beijing'],
    ],
  );
}
```

### Alternative screen component
A simple example of using Commander to create an alternative screen component :

- ✅ Set title
- ✅ Clear screen on start
- ✅ Restore screen on stop

```dart
Future<void> main() async {
  final commander = Commander(level: Level.verbose);

  final screen = commander.screen(title: 'First screen');
  screen.enter();

  await sleep();
  print('Hello screen !');
  await sleep();

  screen.leave();

  print('Goodbye screen !');
}


Future<void> wait() =>
    Future.delayed(Duration(seconds: Random().nextInt(3) + 1));
```
