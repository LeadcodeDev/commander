abstract interface class ChainValidatorExecutor<T> {
  String? execute(T? value);
}

abstract interface class BaseChainValidator<T> {
  void validate(String? Function(T? value) validator);
}

abstract interface class TextualChainValidator<T>
    implements BaseChainValidator<T> {
  void notEmpty({String? message});

  void empty({String? message});

  void email({String? message});

  void minLength(T count, {String? message});

  void maxLength(T count, {String? message});

  void equals(T value, {String? message});
}

abstract interface class NumberChainValidator<T>
    implements BaseChainValidator<T> {
  void between(T min, T max, {String? message});

  void lowerThan(T value, {String? message});

  void greaterThan(T value, {String? message});
}

abstract interface class ChainValidatorContract<T>
    implements
        BaseChainValidator<T>,
        TextualChainValidator<T>,
        NumberChainValidator<T> {}
