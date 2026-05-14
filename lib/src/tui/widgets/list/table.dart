import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';
import '../display/text.dart' show TextAlign;

sealed class TableConstraint {
  const TableConstraint();
  const factory TableConstraint.length(int value) = _Length;
  const factory TableConstraint.percentage(int value) = _Percentage;
  const factory TableConstraint.fill(int weight) = _Fill;
}

final class _Length extends TableConstraint {
  final int value;
  const _Length(this.value);
}

final class _Percentage extends TableConstraint {
  final int value;
  const _Percentage(this.value);
}

final class _Fill extends TableConstraint {
  final int weight;
  const _Fill(this.weight);
}

class TableCellState {
  final bool isActive;
  final bool isRowActive;
  final bool isColumnActive;
  final bool isCellSelected;
  final bool isRowSelected;
  final bool isColumnSelected;
  final bool isFocused;
  final int rowIndex;
  final int columnIndex;

  const TableCellState({
    required this.isActive,
    required this.isRowActive,
    required this.isColumnActive,
    required this.isCellSelected,
    required this.isRowSelected,
    required this.isColumnSelected,
    required this.isFocused,
    required this.rowIndex,
    required this.columnIndex,
  });
}

typedef TableCellBuilder<T> = Widget Function(T item, TableCellState state);

class TableColumn<T> {
  final String title;
  final TableConstraint width;
  final TableCellBuilder<T> cellBuilder;
  final Style? headerStyle;
  final TextAlign headerAlign;

  const TableColumn({
    required this.title,
    required this.cellBuilder,
    this.width = const TableConstraint.fill(1),
    this.headerStyle,
    this.headerAlign = TextAlign.left,
  });
}

typedef CellCoord = ({int row, int col});

class TableState<T> {
  int activeRow = 0;
  int activeColumn = 0;
  int verticalScroll = 0;
  int horizontalScroll = 0;
  final Set<CellCoord> selectedCells = {};
  final Set<int> selectedRows = {};
  final Set<int> selectedColumns = {};
}

class Table<T> implements FocusableWidget {
  @override
  final Key id;
  final List<T> items;
  final List<TableColumn<T>> columns;
  final TableState<T> state;

  final bool showHeader;
  final Style? headerStyle;
  final Style? headerSeparatorStyle;
  final String headerSeparator;

  final bool selectCells;
  final bool selectRows;
  final bool selectColumns;

  final String? columnSeparator;
  final Style? columnSeparatorStyle;

  final int Function(T a, T b)? sortBy;
  final bool Function(T item)? filter;

  final String placeholder;
  final bool showScrollIndicators;

  final void Function(int rowIndex, T item)? onRowActivated;
  final void Function(Set<int> rows)? onRowsSelectionChanged;
  final void Function(Set<int> columns)? onColumnsSelectionChanged;
  final void Function(Set<CellCoord> cells)? onCellsSelectionChanged;

  const Table({
    required this.id,
    required this.items,
    required this.columns,
    required this.state,
    this.showHeader = true,
    this.headerStyle,
    this.headerSeparatorStyle,
    this.headerSeparator = '─',
    this.selectCells = false,
    this.selectRows = false,
    this.selectColumns = false,
    this.columnSeparator,
    this.columnSeparatorStyle,
    this.sortBy,
    this.filter,
    this.placeholder = 'No items',
    this.showScrollIndicators = true,
    this.onRowActivated,
    this.onRowsSelectionChanged,
    this.onColumnsSelectionChanged,
    this.onCellsSelectionChanged,
  }) : assert(columns.length > 0);

  @override
  bool get isSkipped => false;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) => sink.add(area, id);

  List<T> _derived() {
    Iterable<T> work = items;
    if (filter != null) work = work.where(filter!);
    final list = work.toList(growable: false);
    if (sortBy != null) {
      final mutable = list.toList();
      mutable.sort(sortBy!);
      return mutable;
    }
    return list;
  }

  List<int> _computeWidths(int totalWidth) {
    final n = columns.length;
    final sepWidth = columnSeparator != null ? columnSeparator!.length : 1;
    final widths = List<int>.filled(n, 0);
    var remaining = (totalWidth - sepWidth * (n - 1)).clamp(0, totalWidth);
    final initial = remaining;

    for (var i = 0; i < n; i++) {
      final c = columns[i].width;
      if (c is _Length) {
        widths[i] = c.value.clamp(0, remaining);
        remaining -= widths[i];
      }
    }
    for (var i = 0; i < n; i++) {
      final c = columns[i].width;
      if (c is _Percentage) {
        final w = (initial * c.value / 100).round().clamp(0, remaining);
        widths[i] = w;
        remaining -= w;
      }
    }
    var totalWeight = 0;
    final fillIndices = <int>[];
    for (var i = 0; i < n; i++) {
      final c = columns[i].width;
      if (c is _Fill) {
        totalWeight += c.weight;
        fillIndices.add(i);
      }
    }
    if (fillIndices.isNotEmpty && remaining > 0) {
      var allocated = 0;
      for (var k = 0; k < fillIndices.length; k++) {
        final i = fillIndices[k];
        final c = columns[i].width as _Fill;
        final w = k == fillIndices.length - 1
            ? remaining - allocated
            : (remaining * c.weight / totalWeight).round();
        widths[i] = w;
        allocated += w;
      }
    }
    return widths;
  }

  int _headerLines() => showHeader ? 2 : 0;

  ({int firstVisible, int lastVisible}) _visibleColumns(
      List<int> widths, int availableWidth) {
    final sepWidth = columnSeparator != null ? columnSeparator!.length : 1;
    var x = 0;
    final start = state.horizontalScroll.clamp(0, columns.length - 1);
    var end = start;
    for (var i = start; i < columns.length; i++) {
      final w = widths[i] + (i == start ? 0 : sepWidth);
      if (x + w > availableWidth && i != start) break;
      x += w;
      end = i;
    }
    return (firstVisible: start, lastVisible: end);
  }

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    final filtered = _derived();
    if (filtered.isEmpty) return false;

    state.activeRow = state.activeRow.clamp(0, filtered.length - 1);
    state.activeColumn = state.activeColumn.clamp(0, columns.length - 1);

    switch (event.key) {
      case 'ArrowDown':
      case 'j':
        state.activeRow = (state.activeRow + 1).clamp(0, filtered.length - 1);
        return true;
      case 'ArrowUp':
      case 'k':
        state.activeRow = (state.activeRow - 1).clamp(0, filtered.length - 1);
        return true;
      case 'ArrowRight':
      case 'l':
        state.activeColumn =
            (state.activeColumn + 1).clamp(0, columns.length - 1);
        return true;
      case 'ArrowLeft':
      case 'h':
        state.activeColumn =
            (state.activeColumn - 1).clamp(0, columns.length - 1);
        return true;
      case 'Home':
        if (event.ctrl) {
          state.activeColumn = 0;
        } else {
          state.activeRow = 0;
        }
        return true;
      case 'End':
        if (event.ctrl) {
          state.activeColumn = columns.length - 1;
        } else {
          state.activeRow = filtered.length - 1;
        }
        return true;
      case 'PageDown':
        state.activeRow = (state.activeRow + 10).clamp(0, filtered.length - 1);
        return true;
      case 'PageUp':
        state.activeRow = (state.activeRow - 10).clamp(0, filtered.length - 1);
        return true;
      case 'Enter':
        onRowActivated?.call(state.activeRow, filtered[state.activeRow]);
        return true;
      case ' ':
        return _handleSpace(event);
    }
    return false;
  }

  bool _handleSpace(KeyEvent event) {
    final shift = event.shift;
    final alt = event.alt;
    if (shift && selectRows) {
      _toggleRow(state.activeRow);
      return true;
    }
    if (alt && selectColumns) {
      _toggleColumn(state.activeColumn);
      return true;
    }
    if (selectCells) {
      _toggleCell(state.activeRow, state.activeColumn);
      return true;
    }
    if (selectRows) {
      _toggleRow(state.activeRow);
      return true;
    }
    if (selectColumns) {
      _toggleColumn(state.activeColumn);
      return true;
    }
    return false;
  }

  void _toggleCell(int row, int col) {
    final key = (row: row, col: col);
    if (state.selectedCells.contains(key)) {
      state.selectedCells.remove(key);
    } else {
      state.selectedCells.add(key);
    }
    onCellsSelectionChanged?.call(state.selectedCells);
  }

  void _toggleRow(int row) {
    if (state.selectedRows.contains(row)) {
      state.selectedRows.remove(row);
    } else {
      state.selectedRows.add(row);
    }
    onRowsSelectionChanged?.call(state.selectedRows);
  }

  void _toggleColumn(int col) {
    if (state.selectedColumns.contains(col)) {
      state.selectedColumns.remove(col);
    } else {
      state.selectedColumns.add(col);
    }
    onColumnsSelectionChanged?.call(state.selectedColumns);
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    final isFocused = ctx.isFocused(id);
    final filtered = _derived();

    final headerLines = _headerLines();
    final dataArea = headerLines == 0
        ? area
        : Rect(area.x, area.y + headerLines, area.width, area.height - headerLines);

    if (filtered.isEmpty) {
      if (showHeader && area.height >= 2) {
        final widths = _computeWidths(area.width);
        final vis = _visibleColumns(widths, area.width);
        _renderHeader(area, buffer, ctx, widths, vis);
      }
      final emptyArea = headerLines > 0 && area.height > headerLines
          ? Rect(area.x, area.y + headerLines, area.width, area.height - headerLines)
          : area;
      _renderEmpty(emptyArea, buffer, ctx);
      return;
    }

    state.activeRow = state.activeRow.clamp(0, filtered.length - 1);
    state.activeColumn = state.activeColumn.clamp(0, columns.length - 1);

    final widths = _computeWidths(area.width);
    final vis = _visibleColumns(widths, area.width);

    if (state.activeColumn < vis.firstVisible) {
      state.horizontalScroll = state.activeColumn;
    } else if (state.activeColumn > vis.lastVisible) {
      state.horizontalScroll = state.activeColumn;
      while (state.horizontalScroll > 0) {
        final candidate = state.horizontalScroll;
        state.horizontalScroll = candidate - 1;
        final visAttempt = _visibleColumns(widths, area.width);
        if (visAttempt.lastVisible < state.activeColumn) {
          state.horizontalScroll = candidate;
          break;
        }
      }
    }

    final visibleCols = _visibleColumns(widths, area.width);
    final visibleRows = dataArea.height;
    if (visibleRows <= 0) return;

    if (state.activeRow < state.verticalScroll) {
      state.verticalScroll = state.activeRow;
    } else if (state.activeRow >= state.verticalScroll + visibleRows) {
      state.verticalScroll = state.activeRow - visibleRows + 1;
    }
    final maxRowOffset =
        (filtered.length - visibleRows).clamp(0, filtered.length);
    state.verticalScroll = state.verticalScroll.clamp(0, maxRowOffset);

    if (showHeader) {
      _renderHeader(area, buffer, ctx, widths, visibleCols);
    }

    _renderRows(
      dataArea,
      buffer,
      ctx,
      filtered,
      widths,
      visibleCols,
      visibleRows,
      isFocused,
    );

    if (showScrollIndicators) {
      _renderScrollIndicators(area, buffer, ctx, visibleCols);
    }
  }

  void _renderEmpty(Rect area, Buffer buffer, RenderContext ctx) {
    final msg = filter != null && items.isNotEmpty ? 'No match' : placeholder;
    final y = area.y + area.height ~/ 2;
    final tx = area.x + (area.width - msg.length) ~/ 2;
    buffer.writeText(tx.clamp(area.x, area.right), y, msg,
        style: ctx.theme.text.caption, maxWidth: area.width);
  }

  void _renderHeader(
    Rect area,
    Buffer buffer,
    RenderContext ctx,
    List<int> widths,
    ({int firstVisible, int lastVisible}) vis,
  ) {
    final sep = columnSeparator;
    final sepStyle = columnSeparatorStyle ?? ctx.theme.borders.strokeStyle;
    final defaultHeaderStyle = headerStyle ?? ctx.theme.text.title;
    var x = area.x;
    for (var i = vis.firstVisible; i <= vis.lastVisible; i++) {
      if (i != vis.firstVisible && sep != null) {
        buffer.writeText(x, area.y, sep, style: sepStyle, maxWidth: area.right - x);
        x += sep.length;
      } else if (i != vis.firstVisible) {
        x += 1; // implicit space separator
      }
      final colStyle = columns[i].headerStyle ?? defaultHeaderStyle;
      final align = columns[i].headerAlign;
      final title = columns[i].title;
      final w = widths[i];
      final tx = switch (align) {
        TextAlign.center => x + (w - title.length) ~/ 2,
        TextAlign.right => x + w - title.length,
        TextAlign.left => x,
      };
      buffer.writeText(
        tx.clamp(x, x + w),
        area.y,
        title,
        style: colStyle,
        maxWidth: w,
      );
      x += w;
    }

    if (area.height >= 2) {
      final sepLineStyle = headerSeparatorStyle ?? ctx.theme.borders.strokeStyle;
      for (var k = 0; k < area.width; k++) {
        buffer.setChar(area.x + k, area.y + 1, headerSeparator, style: sepLineStyle);
      }
    }
  }

  void _renderRows(
    Rect area,
    Buffer buffer,
    RenderContext ctx,
    List<T> filtered,
    List<int> widths,
    ({int firstVisible, int lastVisible}) vis,
    int visibleRows,
    bool isFocused,
  ) {
    final sep = columnSeparator;
    final sepStyle = columnSeparatorStyle ?? ctx.theme.borders.strokeStyle;
    final activeOverlay =
        Style(bg: ctx.theme.colors.primary, fg: ctx.theme.colors.background);

    for (var i = 0; i < visibleRows && i + state.verticalScroll < filtered.length; i++) {
      final rowIdx = i + state.verticalScroll;
      final item = filtered[rowIdx];
      final rowRect = Rect(area.x, area.y + i, area.width, 1);
      final isRowSelected = state.selectedRows.contains(rowIdx);

      var x = area.x;
      for (var c = vis.firstVisible; c <= vis.lastVisible; c++) {
        if (c != vis.firstVisible && sep != null) {
          buffer.writeText(x, rowRect.y, sep, style: sepStyle, maxWidth: area.right - x);
          x += sep.length;
        } else if (c != vis.firstVisible) {
          x += 1;
        }
        final w = widths[c];
        if (w <= 0) {
          continue;
        }
        final cellRect = Rect(x, rowRect.y, w, 1);
        final isColSelected = state.selectedColumns.contains(c);
        final isCellSelected =
            state.selectedCells.contains((row: rowIdx, col: c));
        final isCellActive =
            isFocused && rowIdx == state.activeRow && c == state.activeColumn;
        final cellState = TableCellState(
          isActive: isCellActive,
          isRowActive: isFocused && rowIdx == state.activeRow,
          isColumnActive: isFocused && c == state.activeColumn,
          isCellSelected: isCellSelected,
          isRowSelected: isRowSelected,
          isColumnSelected: isColSelected,
          isFocused: isFocused,
          rowIndex: rowIdx,
          columnIndex: c,
        );
        columns[c].cellBuilder(item, cellState).render(cellRect, buffer, ctx);
        if (isCellActive) {
          buffer.fillStyle(cellRect, activeOverlay);
        }
        x += w;
      }
    }
  }

  void _renderScrollIndicators(
    Rect area,
    Buffer buffer,
    RenderContext ctx,
    ({int firstVisible, int lastVisible}) vis,
  ) {
    final canScrollLeft = vis.firstVisible > 0;
    final canScrollRight = vis.lastVisible < columns.length - 1;
    final style = Style(fg: ctx.theme.colors.muted);
    if (showHeader && area.width >= 2) {
      if (canScrollLeft) {
        buffer.setChar(area.x, area.y, '◀', style: style);
      }
      if (canScrollRight) {
        buffer.setChar(area.right - 1, area.y, '▶', style: style);
      }
    }
  }
}
