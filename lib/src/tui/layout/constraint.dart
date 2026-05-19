sealed class Constraint {
  const Constraint();

  const factory Constraint.length(int value) = LengthConstraint;
  const factory Constraint.percentage(int value) = PercentageConstraint;
  const factory Constraint.ratio(int num, int den) = RatioConstraint;
  const factory Constraint.fill(int weight) = FillConstraint;
  const factory Constraint.min(int value) = MinConstraint;
  const factory Constraint.max(int value) = MaxConstraint;
}

final class LengthConstraint extends Constraint {
  final int value;
  const LengthConstraint(this.value);
}

final class PercentageConstraint extends Constraint {
  final int value;
  const PercentageConstraint(this.value);
}

final class RatioConstraint extends Constraint {
  final int numerator;
  final int denominator;
  const RatioConstraint(this.numerator, this.denominator);
}

final class FillConstraint extends Constraint {
  final int weight;
  const FillConstraint(this.weight);
}

final class MinConstraint extends Constraint {
  final int value;
  const MinConstraint(this.value);
}

final class MaxConstraint extends Constraint {
  final int value;
  const MaxConstraint(this.value);
}
