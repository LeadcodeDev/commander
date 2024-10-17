import 'package:collection/collection.dart';

enum KeyDown {
  ctrlC([3]),
  ctrlA([1]),
  ctrlD([4]),
  ctrlS([19]),
  ctrlV([22]),
  ctrlW([23]),
  ctrlX([24]),
  ctrlY([25]),
  ctrlZ([26]),

  upArrow([27, 91, 65]),
  downArrow([27, 91, 66]),
  rightArrow([27, 91, 67]),
  leftArrow([27, 91, 68]),
  escape([27]),
  enter([13]),
  backspace([127]),
  space([32]),
  delete([27, 91, 51, 126]),
  tab([9]),
  f1([27, 79, 80]),
  f2([27, 79, 81]),
  f3([27, 79, 82]),
  f4([27, 79, 83]),
  a([97]),
  b([98]),
  c([99]),
  d([100]),
  e([101]),
  f([102]),
  g([103]),
  h([104]),
  i([105]),
  j([106]),
  k([107]),
  l([108]),
  m([109]),
  n([110]),
  o([111]),
  p([112]),
  q([113]),
  r([114]),
  s([115]),
  t([116]),
  u([117]),
  v([118]),
  w([119]),
  x([120]),
  y([121]),
  z([122]),
  A([65]),
  B([66]),
  C([67]),
  D([68]),
  E([69]),
  F([70]),
  G([71]),
  H([72]),
  I([73]),
  J([74]),
  K([75]),
  L([76]),
  M([77]),
  N([78]),
  O([79]),
  P([80]),
  Q([81]),
  R([82]),
  S([83]),
  T([84]),
  U([85]),
  V([86]),
  W([87]),
  X([88]),
  Y([89]),
  Z([90]),
  unknown([]);

  final List<int> value;
  const KeyDown(this.value);

  static KeyDown fromInput(List<int> input) {
    for (var key in KeyDown.values) {
      if (key.value.length == input.length &&
          ListEquality().equals(key.value, input)) {
        return key;
      }
    }
    return KeyDown.unknown;
  }
}