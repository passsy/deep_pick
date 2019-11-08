import 'package:deep_pick/src/pick.dart';

extension BoolPick on RequiredPick {
  bool asBool() {
    if (value is bool) {
      return value as bool;
    } else {
      throw PickException(
          "value $value of type ${value.runtimeType} at location ${location()} can't be casted to bool");
    }
  }
}

extension NullableBoolPick on Pick {
  @Deprecated("Use .required().asBool()")
  bool asBool() {
    if (value == null) {
      throw PickException(
          "value at location ${location()} is null and not an instance of bool");
    }
    return required().asBool();
  }

  bool /*?*/ asBoolOrNull() {
    if (value == null) return null;
    try {
      return required().asBool();
    } catch (_) {
      return null;
    }
  }

  bool asBoolOrTrue() {
    if (value == null) return true;
    try {
      return required().asBool();
    } catch (_) {
      return true;
    }
  }

  bool asBoolOrFalse() {
    if (value == null) return false;
    try {
      return required().asBool();
    } catch (_) {
      return false;
    }
  }
}
