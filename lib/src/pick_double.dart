import 'package:deep_pick/deep_pick.dart';

extension DoublePick on Pick {
  double asDouble() {
    if (value == null) {
      throw PickException(
          "value at location ${location()} is null and not an instance of double");
    }
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

  double asDoubleOrNull() {
    if (value == null) return null;
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
    return null;
  }
}
