import 'dart:async';

import 'package:mansion/mansion.dart';

final class BoardHeaderItem {
  final String label;
  String? text;
  final FutureOr? Function(BoardHeaderItem)? updater;
  FutureOr Function()? dispose;

  final List<Sequence> Function(String)? labelFormatter;
  final List<Sequence> Function(String)? textFormatter;

  int get length => label.length + (text?.length ?? 0);

  BoardHeaderItem({required this.label, this.text, this.updater, this.labelFormatter, this.textFormatter});
}
