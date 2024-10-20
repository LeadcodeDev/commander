import 'dart:async';
import 'dart:io';

import 'package:commander_ui/old_src/domain/models/terminal.dart';

class UnixTerminal implements Terminal {
  final _streamController = StreamController<List<int>>.broadcast();

  @override
  Stream<List<int>> get stream => _streamController.stream;


  UnixTerminal() {
    stdin.listen(_streamController.add);
  }

  @override
  void enableRawMode() {}

  @override
  void disableRawMode() {}
}
