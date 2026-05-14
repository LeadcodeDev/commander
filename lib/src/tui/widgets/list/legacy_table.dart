import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

class LegacyTableState {
  int selectedRow;
  int scrollOffset;
  LegacyTableState({this.selectedRow = 0, this.scrollOffset = 0});
}

class LegacyTable implements FocusableWidget {
  @override
  final Key id;
  final List<String> columns;
  final List<List<String>> rows;
  final LegacyTableState state;
  final List<int>? widths;

  const LegacyTable({
    required this.id,
    required this.columns,
    required this.rows,
    required this.state,
    this.widths,
  });

  @override
  bool get isSkipped => false;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) => sink.add(area, id);

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    if (rows.isEmpty) return false;
    switch (event.key) {
      case 'ArrowDown':
      case 'j':
        state.selectedRow = (state.selectedRow + 1).clamp(0, rows.length - 1);
        return true;
      case 'ArrowUp':
      case 'k':
        state.selectedRow = (state.selectedRow - 1).clamp(0, rows.length - 1);
        return true;
      case 'Home':
        state.selectedRow = 0;
        return true;
      case 'End':
        state.selectedRow = rows.length - 1;
        return true;
    }
    return false;
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    final colWidths = _computeWidths(area.width);

    final headerStyle = ctx.theme.text.title;
    var x = area.x;
    for (var i = 0; i < columns.length && i < colWidths.length; i++) {
      buffer.writeText(x, area.y, columns[i], style: headerStyle, maxWidth: colWidths[i]);
      x += colWidths[i] + 1;
    }

    final dataArea = Rect(area.x, area.y + 1, area.width, area.height - 1);
    final visible = dataArea.height;
    if (visible <= 0) return;
    if (state.selectedRow < state.scrollOffset) {
      state.scrollOffset = state.selectedRow;
    } else if (state.selectedRow >= state.scrollOffset + visible) {
      state.scrollOffset = state.selectedRow - visible + 1;
    }
    state.scrollOffset = state.scrollOffset.clamp(0, (rows.length - visible).clamp(0, rows.length));

    for (var i = 0; i < visible && i + state.scrollOffset < rows.length; i++) {
      final idx = i + state.scrollOffset;
      final row = rows[idx];
      final isSel = idx == state.selectedRow;
      final rowRect = Rect(dataArea.x, dataArea.y + i, dataArea.width, 1);
      final rowStyle = isSel
          ? Style(bg: ctx.theme.colors.primary, fg: ctx.theme.colors.background)
          : ctx.theme.text.body;
      if (isSel) buffer.fillStyle(rowRect, rowStyle);
      x = rowRect.x;
      for (var c = 0; c < colWidths.length && c < row.length; c++) {
        buffer.writeText(x, rowRect.y, row[c], style: rowStyle, maxWidth: colWidths[c]);
        x += colWidths[c] + 1;
      }
    }
  }

  List<int> _computeWidths(int total) {
    if (widths != null) return widths!;
    if (columns.isEmpty) return const [];
    final per = ((total - (columns.length - 1)) / columns.length).floor();
    return List.filled(columns.length, per.clamp(1, total));
  }
}
