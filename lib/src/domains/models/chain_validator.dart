abstract interface class ChainValidatorExecutor {
  String? execute(String? value);
}

abstract interface class BaseChainValidator {
  void validate(String? Function(String? value) validator);
}

abstract interface class TextualChainValidator implements BaseChainValidator {
  void notEmpty({String? message});

  void empty({String? message});

  void email({String? message});

  void minLength(int count, {String? message});

  void maxLength(int count, {String? message});

  void equals(String value, {String? message});
}

abstract interface class NumberChainValidator implements BaseChainValidator {
  void between(int min, int max, {String? message});

  void lowerThan(int value, {String? message});

  void greaterThan(int value, {String? message});
}

abstract interface class ChainValidatorContract
    implements
        BaseChainValidator,
        TextualChainValidator,
        NumberChainValidator {}
