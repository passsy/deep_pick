import 'package:deep_pick/src/pick.dart';

extension MapPick on RequiredPick {
  Map<RK, RV> asMap<RK, RV>() {
    if (value is Map) {
      return (value as Map<dynamic, dynamic>).cast();
    } else {
      throw PickException(
          "value $value of type ${value.runtimeType} at location ${location()} can't be casted to Map<dynamic, dynamic>");
    }
  }
}

extension NullableMapPick on Pick {
  @Deprecated("Use .required().asMap()")
  Map<RK, RV> asMap<RK, RV>() {
    if (value == null) {
      throw PickException(
          "value at location ${location()} is null and not an instance of Map<dynamic, dynamic>");
    }
    return required().asMap();
  }

  Map<RK, RV> asMapOrEmpty<RK, RV>() {
    if (value == null) return <RK, RV>{};

    try {
      return required().asMap();
    } catch (_) {
      return <RK, RV>{};
    }
  }

  Map<RK, RV> /*?*/ asMapOrNull<RK, RV>() {
    if (value == null) return null;
    try {
      return required().asMap();
    } catch (_) {
      return null;
    }
  }
}
