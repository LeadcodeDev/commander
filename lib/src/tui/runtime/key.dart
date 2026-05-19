sealed class Key {
  const Key._();

  factory Key.of(Object value) = ValueKey;
  factory Key.symbol(Symbol s) = SymbolKey;
  factory Key.composite(List<Object> parts) = CompositeKey;

  factory Key(Object value) {
    if (value is Symbol) return SymbolKey(value);
    if (value is List<Object>) return CompositeKey(value);
    return ValueKey(value);
  }
}

final class ValueKey extends Key {
  final Object value;
  const ValueKey(this.value) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ValueKey && other.value == value);

  @override
  int get hashCode => Object.hash(ValueKey, value);

  @override
  String toString() => 'Key.of($value)';
}

final class SymbolKey extends Key {
  final Symbol symbol;
  const SymbolKey(this.symbol) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SymbolKey && other.symbol == symbol);

  @override
  int get hashCode => Object.hash(SymbolKey, symbol);

  @override
  String toString() => 'Key.symbol($symbol)';
}

/// Composite key built from a list of primitive parts.
///
/// `parts` must contain only primitive values (`num`, `String`, `Symbol`,
/// `bool`). Non-primitive parts (e.g. `List`, `Map`, custom objects without a
/// content-based `hashCode`) would break the `==`/`hashCode` contract: equal
/// keys could end up with different hashes, corrupting `Set<Key>` and
/// `Map<Key, _>` lookups used by focus and async tracking.
final class CompositeKey extends Key {
  final List<Object> parts;
  CompositeKey(this.parts)
      : assert(
          parts.every((p) => p is num || p is String || p is Symbol || p is bool),
          'CompositeKey parts must be primitives (num/String/Symbol/bool)',
        ),
        super._();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CompositeKey) return false;
    if (other.parts.length != parts.length) return false;
    for (var i = 0; i < parts.length; i++) {
      if (other.parts[i] != parts[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([CompositeKey, ...parts]);

  @override
  String toString() => 'Key.composite($parts)';
}
