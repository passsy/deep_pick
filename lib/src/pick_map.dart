import 'package:deep_pick/src/pick.dart';

extension MapPick on RequiredPick {
  Map<RK, RV> asMap<RK, RV>() {
    if (value is Map) {
      final view = (value as Map<dynamic, dynamic>).cast<RK, RV>();
      // create copy of casted view so all items are type checked here
      // and not lazily type checked when accessing them
      return Map.of(view);
    } else {
      throw PickException(
          "value $value of type ${value.runtimeType} at location ${location()} can't be casted to Map<dynamic, dynamic>");
    }
  }
}

extension NullableMapPick on Pick {
  @Deprecated(
      'By default values are optional and can only be converted when a fallback is provided '
      'i.e. .asMapOrNull() which falls back to `null`. '
      'Use .required().asMap() in cases the value is mandatory. '
      "It will crash when the value couldn't be picked.")
  Map<RK, RV> asMap<RK, RV>() {
    if (value == null) {
      throw PickException(
          'value at location ${location()} is null and not an instance of Map<dynamic, dynamic>');
    }
    return required().asMap();
  }

  Map<RK, RV> asMapOrEmpty<RK, RV>() {
    if (value == null) return <RK, RV>{};
    if (value is! Map) return <RK, RV>{};
    return required().asMap();
  }

  Map<RK, RV>? asMapOrNull<RK, RV>() {
    if (value == null) return null;
    if (value is! Map) return null;
    return required().asMap();
  }
}
