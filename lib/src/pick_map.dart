import 'package:deep_pick/src/pick.dart';

extension MapPick on RequiredPick {
  Map<RK, RV> asMap<RK, RV>() {
    final value = this.value;
    if (value is Map) {
      final view = value.cast<RK, RV>();
      // create copy of casted view so all items are type checked here
      // and not lazily type checked when accessing them
      return Map.of(view);
    }
    throw PickException(
        "value $value of type ${value.runtimeType} at location ${location()} can't be casted to Map<dynamic, dynamic>");
  }
}

extension NullableMapPick on Pick {
  @Deprecated('Use .asMapOrThrow()')
  Map<RK, RV> Function<RK, RV>() get asMap => asMapOrThrow;

  Map<RK, RV> asMapOrThrow<RK, RV>() {
    withContext(requiredPickErrorHintKey,
        'Use asMapOrEmpty() when the value may be null at some point (Map<$RK, $RV>?).');
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
