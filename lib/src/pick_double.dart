import 'package:deep_pick/src/pick.dart';

extension DoublePick on RequiredPick {
  double asDouble() {
    if (value is double) {
      return value as double;
    } else if (value is num) {
      return (value as num).toDouble();
    } else if (value is String) {
      final parsed = double.tryParse(value as String);
      if (parsed != null) {
        return parsed;
      }
    }
    throw PickException(
        "value $value of type ${value.runtimeType} at location ${location()} can't be casted to double");
  }
}

extension NullableDoublePick on Pick {
  // This deprecation is used to promote the `.required()` in auto-completion.
  // Therefore it is not intended to be ever removed
  @Deprecated(
      'By default values are optional and can only be converted when a fallback is provided '
      'i.e. .asDoubleOrNull() which falls back to `null`. '
      'Use .required().asDouble() in cases the value is mandatory. '
      "It will crash when the value couldn't be picked.")
  double asDouble() {
    if (value == null) {
      throw PickException(
          'value at location ${location()} is null and not an instance of double');
    }
    return required().asDouble();
  }

  double? asDoubleOrNull() {
    if (value == null) return null;
    try {
      return required().asDouble();
    } catch (_) {
      return null;
    }
  }
}
