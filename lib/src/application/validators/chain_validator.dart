import 'package:commander_ui/src/domains/models/chain_validator.dart';

final class ValidatorChain
    implements ChainValidatorExecutor, ChainValidatorContract {
  final List<String? Function(String?)> _validators = [];

  String? value;

  @override
  void validate(String? Function(String? value) validator) {
    _validators.add(validator);
  }

  @override
  void notEmpty({String? message = 'This field is required'}) {
    _validators.add((value) {
      return switch (value) {
        String(:final isEmpty) when isEmpty => message,
        _ => null,
      };
    });
  }

  @override
  void empty({String? message = 'This field should be empty'}) {
    _validators.add((value) {
      return switch (value) {
        null => null,
        _ => message,
      };
    });
  }

  @override
  void email({String? message = 'This field should be a valid email'}) {
    _validators.add((value) {
      final emailRegExp = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');

      if (value == null) {
        return message;
      }

      return switch (emailRegExp.hasMatch(value)) {
        false => message,
        _ => null,
      };
    });
  }

  @override
  void minLength(int count, {String? message}) {
    _validators.add((value) {
      if (value case String value when value.length < count) {
        return message ?? 'This field should have at least $count characters';
      }

      return null;
    });
  }

  @override
  void maxLength(int count, {String? message}) {
    _validators.add((value) {
      if (value case String value when value.length > count) {
        return message ?? 'This field should have at most $count characters';
      }

      return null;
    });
  }

  @override
  void equals(String str, {String? message}) {
    _validators.add((value) {
      if (value case String value when value != str) {
        return message ?? 'This field should be equal to $str';
      }

      return null;
    });
  }

  @override
  void between(int min, int max, {String? message}) {
    final errorMessage =
        message ?? 'This field should be between $min and $max characters';
    _validators.add((value) {
      if (value == null) {
        return errorMessage;
      }

      final length = value.length;

      if (length < min || length > max) {
        return errorMessage;
      }

      return null;
    });
  }

  @override
  void lowerThan(int value, {String? message}) {
    final errorMessage = message ?? 'This field should be lower than $value';
    _validators.add((response) {
      if (response == null) {
        return errorMessage;
      }

      final intValue = int.tryParse(response);

      if (intValue == null || intValue >= value) {
        return errorMessage;
      }

      return null;
    });
  }

  @override
  void greaterThan(int value, {String? message}) {
    final errorMessage = message ?? 'This field should be greater than $value';
    _validators.add((response) {
      if (response == null) {
        return errorMessage;
      }

      final intValue = int.tryParse(response);

      if (intValue == null || intValue <= value) {
        return errorMessage;
      }

      return null;
    });
  }

  @override
  String? execute(String? value) {
    print('Executing validators');
    for (final validator in _validators) {
      final result = validator(value);
      if (result != null) {
        return result;
      }
    }

    return null;
  }
}
