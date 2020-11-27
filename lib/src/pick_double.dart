import 'package:deep_pick/src/pick.dart';

extension DoublePick on RequiredPick {
  double asDouble() {
    final value = this.value;
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    throw PickException(
        "value $value of type ${value.runtimeType} at location ${location(false)} can't be casted to double");
  }
}

extension NullableDoublePick on Pick {
  @Deprecated('Use .asDoubleOrThrow()')
  double Function() get asDouble => asDoubleOrThrow;

  double asDoubleOrThrow() {
    if (value == null) {
      throw PickException(
          'value at location ${location(isAbsent())} is null and not an instance of double');
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
