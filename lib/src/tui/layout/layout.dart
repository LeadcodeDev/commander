import '../geometry/rect.dart';
import 'constraint.dart';

enum Direction { vertical, horizontal }

class Layout {
  final Direction direction;
  final List<Constraint> constraints;
  final int spacing;

  const Layout({
    required this.direction,
    required this.constraints,
    this.spacing = 0,
  });

  factory Layout.vertical(List<Constraint> constraints, {int spacing = 0}) =>
      Layout(
          direction: Direction.vertical,
          constraints: constraints,
          spacing: spacing);

  factory Layout.horizontal(List<Constraint> constraints, {int spacing = 0}) =>
      Layout(
          direction: Direction.horizontal,
          constraints: constraints,
          spacing: spacing);

  List<Rect> split(Rect area) {
    final isVertical = direction == Direction.vertical;
    final total = isVertical ? area.height : area.width;

    if (total <= 0 || constraints.isEmpty) {
      return List.filled(constraints.length, const Rect.zero());
    }

    final n = constraints.length;
    final spacingTotal = spacing * (n - 1).clamp(0, n);
    final available = (total - spacingTotal).clamp(0, total);

    final sizes = List<int>.filled(n, 0);
    final mins = List<int>.filled(n, 0);
    final maxs = List<int>.filled(n, available);
    int remaining = available;

    for (int i = 0; i < n; i++) {
      switch (constraints[i]) {
        case LengthConstraint(:final value):
          sizes[i] = value.clamp(0, remaining);
          remaining -= sizes[i];
        case PercentageConstraint(:final value):
          sizes[i] = (available * value / 100).round().clamp(0, remaining);
          remaining -= sizes[i];
        case RatioConstraint(:final numerator, :final denominator):
          if (denominator == 0) {
            sizes[i] = 0;
          } else {
            sizes[i] = (available * numerator / denominator)
                .round()
                .clamp(0, remaining);
          }
          remaining -= sizes[i];
        case MinConstraint(:final value):
          mins[i] = value;
        case MaxConstraint(:final value):
          maxs[i] = value;
        case FillConstraint():
          break;
      }
    }

    final fillIndices = <int>[];
    int fillWeightTotal = 0;

    for (int i = 0; i < n; i++) {
      final c = constraints[i];
      if (c is FillConstraint) {
        fillIndices.add(i);
        fillWeightTotal += c.weight;
      } else if (c is MinConstraint || c is MaxConstraint) {
        fillIndices.add(i);
        fillWeightTotal += 1;
      }
    }

    if (fillIndices.isNotEmpty && remaining > 0) {
      if (fillWeightTotal == 0) {
        fillWeightTotal = fillIndices.length;
      }

      int fillTotal = remaining;
      for (int k = 0; k < fillIndices.length; k++) {
        final i = fillIndices[k];
        final c = constraints[i];
        final weight = c is FillConstraint ? c.weight : 1;

        int allocated;
        if (k == fillIndices.length - 1) {
          allocated = remaining;
        } else {
          allocated = (fillTotal * weight / fillWeightTotal).round();
        }

        allocated =
            allocated.clamp(mins[i], maxs[i] == 0 ? allocated : maxs[i]);
        sizes[i] = allocated;
        remaining -= allocated;
      }
    } else {
      for (var i = 0; i < n; i++) {
        if (constraints[i] is MinConstraint) {
          sizes[i] = mins[i].clamp(0, remaining + sizes[i]);
        }
      }
    }

    final rects = <Rect>[];
    int offset = isVertical ? area.y : area.x;

    for (int i = 0; i < n; i++) {
      if (isVertical) {
        rects.add(Rect(area.x, offset, area.width, sizes[i]));
      } else {
        rects.add(Rect(offset, area.y, sizes[i], area.height));
      }

      offset += sizes[i];
      if (i < n - 1) {
        offset += spacing;
      }
    }

    return rects;
  }
}
