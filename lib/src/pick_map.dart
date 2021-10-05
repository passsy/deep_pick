import 'package:deep_pick/src/pick.dart';

extension NullableMapPick on Pick {
  @Deprecated('Use .asMapOrThrow()')
  Map<RK, RV> Function<RK, RV>() get asMap => asMapOrThrow;

  /// Returns the picked [value] as [Map]
  ///
  /// {@template Pick.asMap}
  /// Provides a view of this map as having [RK] keys and [RV] instances,
  /// if necessary.
  ///
  /// If this map is already a `Map<RK, RV>`, it is returned unchanged.
  ///
  /// If this set contains only keys of type [RK] and values of type [RV],
  /// all read operations will work correctly.
  /// If any operation exposes a non-[RK] key or non-[RV] value,
  /// the operation will throw instead.
  ///
  /// Entries added to the map must be valid for both a `Map<K, V>` and a
  /// `Map<RK, RV>`.
  /// via [Map] cast function
  /// {@endtemplate}
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

  /// Returns the picked [value] as [Map]. This method throws when [value] is
  /// not a `Map` or [isAbsent]
  ///
  /// {@macro Pick.asMap}
  Map<RK, RV> asMapOrThrow<RK, RV>() {
    withContext(requiredPickErrorHintKey,
        'Use asMapOrEmpty()/asMapOrNull() when the value may be null/absent at some point (Map<$RK, $RV>?).');
    return _parse();
  }

  /// Returns the picked [value] as [Map] or an empty map when the `value`
  /// isn't a [Map] or [isAbsent].
  ///
  /// {@macro Pick.asMap}
  Map<RK, RV> asMapOrEmpty<RK, RV>() {
    if (value == null) return <RK, RV>{};
    if (value is! Map) return <RK, RV>{};
    return _parse();
  }

  /// Returns the picked [value] as [Map] or null when the `value`
  /// isn't a [Map] or [isAbsent].
  ///
  /// {@macro Pick.asMap}
  Map<RK, RV>? asMapOrNull<RK, RV>() {
    if (value == null) return null;
    if (value is! Map) return null;
    return _parse();
  }
}
