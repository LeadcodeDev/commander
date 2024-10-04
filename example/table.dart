import 'package:commander_ui/src/components/table.dart';

Future<void> main() async {
  Table(
    columns: ['Name', 'Age', 'Country', 'City'],
    lineSeparator: false,
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
