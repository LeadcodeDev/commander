abstract class Result<T> {
  const Result();

  R when<R>({required R Function(T value) ok, required String Function(Object error) err});
  T unwrap();
}

class Ok<T> extends Result<T> with ResultWhen {
  final T value;

  const Ok(this.value);
}

class Err<T> extends Result<T> with ResultWhen {
  final Object error;

  const Err(this.error);
}

mixin ResultWhen<T> on Result<T> {
  @override
  R when<R>({required R Function(T value) ok, required String Function(Object error) err}) {
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
