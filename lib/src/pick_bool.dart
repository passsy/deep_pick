import 'package:deep_pick/deep_pick.dart';

extension BoolPick on Pick {
  bool asBool() {
    if (value == null) {
      throw PickException(
          "value at location ${location()} is null and not an instance of bool");
    }
    if (value is bool) {
      return value as bool;
    } else {
      throw PickException(
          "value $value of type ${value.runtimeType} at location ${location()} can't be casted to bool");
    }
  }

  bool /*?*/ asBoolOrNull() {
    if (value == null) return null;
    if (value is bool) {
      return value as bool;
    } else {
      return null;
    }
  }

  bool asBoolOrTrue() {
    if (value == null) return true;
    if (value is bool) {
      return value as bool;
    } else {
      return true;
    }
  }

  bool asBoolOrFalse() {
    if (value == null) return false;
    if (value is bool) {
      return value as bool;
    } else {
      return false;
    }
  }
}
