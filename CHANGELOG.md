# 2.3.0
- Implement theming components
  - Add `AskTheme` property in `ask` component
  - Add `SelectTheme` property in `select` component
  - Add `CheckboxTheme` property in `checkbox` component
  - Add `TaskTheme` property in `task` component
  - Add `SwapTheme` property in `swap` component
- Remove useless `message` property in task component

# 2.2.4
- Make `task` component as windows compatible
- Change default placeholder for `swap` component in example
- Remove "Tape to search" in `checkbox` component
- Reset cursor position in enter `screen` component

# 2.2.3
- Add missing properties `select` in select commander entry
- Fix multiple behaviour instead of single behaviour in `checkbox` component
- Enhance `info` logger method

# 2.2.2
- Remove `createSpace` method in `ask` component

# 2.2.1
- The ask component disappeared after the validation stage
- Calling `createSpace` method in all rendering cases for `ask` component
- Remove missing `print` statement in `readKey` function

# 2.2.0
- Add `select` display handler
- Fix bad FutureOr execution

## 2.1.0
- Add missing exports
- Change `ask` return type for an generic to allow nullable value 

## 2.0.0
- Rework the whole library
- Change `input` to `ask` component
- Change `delayed` to `task` component
- Implement `swap` component
- Implement logger methods

## 1.8.0

- Hide internal component methods
- Implement `onExit` property on components

## 1.7.0[CHANGELOG.md](CHANGELOG.md)

- Implement `alternative screen` component
- Add `Table` component in public export

## 1.6.0

- Add `Table` component

## 1.5.1

- Fix bad selected value when searching in `select` component
- Fix hidden cursor on exit in `input` component

## 1.5.0

- Add `defaultValue` property on `input` component

## 1.4.1

- Add `max` property on `checkbox` component
- Fix displayed value on `checkbox` when user submit component 

## 1.4.0

- Add `hidden` property on `input` component
- Implement `checkbox` component

## 1.3.0

- Add select max result into configurable option
- Add delayed component into readme
- Add progress component into readme

## 1.2.0

- Implement switch component
- Enhance methods documentation

## 1.1.0

- Implement password secure
- Restore cursor after component result

## 1.0.0

- Initial version.
