import 'package:deep_pick/src/pick.dart';

extension NullableMapPick on Pick {
  @Deprecated('Use .asMapOrThrow()')
  Map<RK, RV> Function<RK, RV>() get asMap => asMapOrThrow;

  Map<RK, RV> _parse<RK, RV>() {
    final value = required().value;
    if (value is Map) {
      final view = value.cast<RK, RV>();
      // create copy of casted view so all items are type checked here
      // and not lazily type checked when accessing them
      return Map.of(view);
    }
    throw PickException(
        'Type ${value.runtimeType} of $debugParsingExit can not be casted to Map<dynamic, dynamic>');
  }

  Map<RK, RV> asMapOrThrow<RK, RV>() {
    withContext(requiredPickErrorHintKey,
        'Use asMapOrEmpty()/asMapOrNull() when the value may be null/absent at some point (Map<$RK, $RV>?).');
    return _parse();
  }

  Map<RK, RV> asMapOrEmpty<RK, RV>() {
    if (value == null) return <RK, RV>{};
    if (value is! Map) return <RK, RV>{};
    return _parse();
  }

  Map<RK, RV> /*?*/ asMapOrNull<RK, RV>() {
    if (value == null) return null;
    if (value is! Map) return null;
    return _parse();
  }
}
