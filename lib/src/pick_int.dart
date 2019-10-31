import 'package:deep_pick/deep_pick.dart';

extension IntPick on Pick {
  int asInt() {
    if (value == null) {
      throw PickException(
          "value at location ${location()} is null and not an instance of int");
    }
    if (value is int) {
      return value as int;
    } else if (value is num) {
      return (value as num).toInt();
    } else if (value is String) {
      final parsed = int.tryParse(value as String);
      if (parsed != null) {
        return parsed;
      }
    }
    throw PickException(
        "value $value of type ${value.runtimeType} at location ${location()} can't be casted to int");
  }

  int /*?*/ asIntOrNull() {
    if (value == null) return null;
    if (value is int) {
      return value as int;
    } else if (value is num) {
      return (value as num).toInt();
    } else if (value is String) {
      final parsed = int.tryParse(value as String);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }
}
