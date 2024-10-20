/// Represents a result of an operation that could either be successful (`Ok`) or fail (`Err`).
abstract class Result<T> {
  const Result();

  /// Executes one of the provided functions based on whether this instance is `Ok` or `Err`.
  /// If this instance is [Ok], the `ok` function is called with the value.
  /// If this instance is [Err], the `err` function is called with the error.
  R when<R>(
      {required R Function(T value) ok,
      required String Function(Object error) err});

  /// Returns the value if this instance is `Ok`.
  /// Throws an exception if this instance is `Err`.
  T unwrap();
}

/// Represents a successful result of an operation.
class Ok<T> extends Result<T> with ResultWhen {
  /// The value of the successful operation.
  final T value;

  const Ok(this.value);
}

/// Represents a failed result of an operation.
class Err<T> extends Result<T> with ResultWhen {
  /// The error of the failed operation.
  final Object error;

  const Err(this.error);
}

/// Provides default implementations for the `when` and `unwrap` methods of `Result`.
mixin ResultWhen<T> on Result<T> {
  @override
  R when<R>(
      {required R Function(T value) ok,
      required String Function(Object error) err}) {
    if (this is Ok<T>) {
      return ok((this as Ok<T>).value);
    } else {
      throw Exception(err((this as Err).error));
    }
  }

  @override
  T unwrap() {
    if (this is Ok<T>) {
      return (this as Ok<T>).value;
    } else {
      throw (this as Err).error;
    }
  }
}
