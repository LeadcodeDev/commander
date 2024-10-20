import 'package:collection/collection.dart';

enum KeyDown {
  a('a', '\x61'),
  b('b', '\x62'),
  c('c', '\x63'),
  d('d', '\x64'),
  e('e', '\x65'),
  f('f', '\x66'),
  g('g', '\x67'),
  h('h', '\x68'),
  i('i', '\x69'),
  j('j', '\x6A'),
  k('k', '\x6B'),
  l('l', '\x6C'),
  m('m', '\x6D'),
  n('n', '\x6E'),
  o('o', '\x6F'),
  p('p', '\x70'),
  q('q', '\x71'),
  r('r', '\x72'),
  s('s', '\x73'),
  t('t', '\x74'),
  u('u', '\x75'),
  v('v', '\x76'),
  w('w', '\x77'),
  x('x', '\x78'),
  y('y', '\x79'),
  z('z', '\x7A'),

  A('A', '\x41'),
  B('B', '\x42'),
  C('C', '\x43'),
  D('D', '\x44'),
  E('E', '\x45'),
  G('G', '\x47'),
  H('H', '\x48'),
  I('I', '\x49'),
  J('J', '\x4A'),
  K('K', '\x4B'),
  L('L', '\x4C'),
  M('M', '\x4D'),
  N('N', '\x4E'),
  O('O', '\x4F'),
  P('P', '\x50'),
  Q('Q', '\x51'),
  R('R', '\x52'),
  S('S', '\x53'),
  T('T', '\x54'),
  U('U', '\x55'),
  V('V', '\x56'),
  W('W', '\x57'),
  X('X', '\x58'),
  Y('Y', '\x59'),
  Z('Z', '\x5A'),

  ctrlA('Ctrl+A', '\x01'),
  ctrlB('Ctrl+B', '\x02'),
  ctrlC('Ctrl+C', '\x03'),
  ctrlD('Ctrl+D', '\x04'),
  ctrlE('Ctrl+E', '\x05'),
  ctrlF('Ctrl+F', '\x06'),
  ctrlG('Ctrl+G', '\x07'),
  ctrlH('Ctrl+H', '\x08'),
  ctrlI('Ctrl+I', '\x09'),
  ctrlJ('Ctrl+J', '\x0A'),
  ctrlK('Ctrl+K', '\x0B'),
  ctrlL('Ctrl+L', '\x0C'),
  ctrlM('Ctrl+M', '\x0D'),
  ctrlN('Ctrl+N', '\x0E'),
  ctrlO('Ctrl+O', '\x0F'),
  ctrlP('Ctrl+P', '\x10'),
  ctrlQ('Ctrl+Q', '\x11'),
  ctrlR('Ctrl+R', '\x12'),
  ctrlS('Ctrl+S', '\x13'),
  ctrlT('Ctrl+T', '\x14'),
  ctrlU('Ctrl+U', '\x15'),
  ctrlV('Ctrl+V', '\x16'),
  ctrlW('Ctrl+W', '\x17'),
  ctrlX('Ctrl+X', '\x18'),
  ctrlY('Ctrl+Y', '\x19'),
  ctrlZ('Ctrl+Z', '\x1A'),

  upArrow('↑', '\x1B[A'),
  downArrow('↓', '\x1B[B'),
  rightArrow('→', '\x1B[C'),
  leftArrow('←', '\x1B[D'),
  escape('Esc', '\x1B'),
  backspace('Backspace', '\x7F'),
  wordBackspace('Ctrl+Backspace', '\x1B[2~'),
  space(' ', '\x20'),
  delete('Delete', '\x1B[3~'),
  unknown('Unknown', '');


  final String char;
  final String value;

  const KeyDown(this.char, this.value);

  static KeyDown fromInput(List<int> input) {
    for (var key in KeyDown.values) {
      // Convertir la valeur de la touche en liste d'entiers
      List<int> keyBytes = key.value.codeUnits;
      if (keyBytes.length == input.length &&
          ListEquality().equals(keyBytes, input)) {
        return key;
      }
    }
    return KeyDown.unknown;
  }

  static KeyDown match(String value) => KeyDown.values.firstWhere((key) => key.value == value, orElse: () => KeyDown.unknown);
  static KeyDown? matchOrNull(String value) => KeyDown.values.firstWhereOrNull((key) => key.value == value);
}
