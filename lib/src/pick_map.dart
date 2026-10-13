import 'package:deep_pick/src/pick.dart';

extension NullableMapPick on Pick {
  /// Returns the picked [value] as [Map]
  ///
  /// {@template Pick.asMap}
  /// Provides a view of this map as having [RK] keys and [RV] instances,
  /// if necessary.
  ///
  /// If this map is already a `Map<RK, RV>`, it is returned unchanged.
  ///
  /// If any operation exposes a non-[RK] key or non-[RV] value,
  /// the operation will throw instead.
  ///
  /// If any operation exposes a duplicate [RK] key [RV] value is replaced
  /// with new one,
  ///
  /// Entries added to the map must be valid for both a `Map<K, V>` and a
  /// `Map<RK, RV>`.
  /// via [Map] cast function
  ///
  /// ```dart
  /// final map = pick({
  ///   'a': 'John Snow',
  ///   'b': 1,
  ///   'c': null,
  ///   'a': 'John Snow updated',
  /// }).asMapOrThrow()
  ///
  /// // map
  /// {
  ///   'a': 'John Snow updated',
  ///   'b': 1,
  ///   'c': null,
  /// }
  /// ```
  ///
  /// {@macro Pick.mapEntries}
  ///
  /// ```dart
  /// final Map<String, Shoe> shoes = pick({
  ///   'nike': {'id': '421'},
  ///   'adidas': {'id': '532'},
  /// }).asMapOrThrow(mapValue: Shoe.fromPick);
  /// ```
  /// {@endtemplate}
  Map<RK, RV> _parse<RK, RV>(
    Object value,
    RK Function(Pick key)? mapKey,
    RV Function(RequiredPick pick)? mapValue,
    RV Function(Pick pick)? whenNullValue,
  ) {
    if (value is! Map) {
      throw PickException.fromPick(this, 'expected a Map');
    }
    if (mapKey == null && mapValue == null && whenNullValue == null) {
      final view = value.cast<RK, RV>();
      // create copy of casted view so all items are type checked here
      // and not lazily type checked when accessing them
      return Map.of(view);
    }
    return _mapEntries(
      value,
      onlyStringKeys: false,
      mapKey: mapKey,
      mapValue: mapValue,
      whenNullValue: whenNullValue,
    );
  }

  /// Converts the entries of [map], the picked value
  ///
  /// {@template Pick.mapEntries}
  /// Use [mapValue] to parse the values, like the mapper of `asList*` does
  /// for the items of a list. It receives a pick of the value, an error
  /// reports the full location.
  ///
  /// Entries with a `null` value are ignored when [mapValue] is set. To map
  /// them as well, use [whenNullValue].
  ///
  /// [mapKey] converts the keys. It receives a pick of the key, so the usual
  /// parsers work on it, i.e. `mapKey: (key) => key.asIntOrThrow()`.
  /// {@endtemplate}
  Map<K, V> _mapEntries<K, V>(
    Map<dynamic, dynamic> map, {
    required bool onlyStringKeys,
    K Function(Pick key)? mapKey,
    V Function(RequiredPick pick)? mapValue,
    V Function(Pick pick)? whenNullValue,
  }) {
    // ignore: deprecated_member_use_from_same_package
    final location = path;
    // a path holds no null, a null key shows up as the word
    List<Object> locationOf(Object? key) => [...location, key ?? 'null'];

    final result = <K, V>{};
    for (final entry in map.entries) {
      final key = entry.key;
      if (onlyStringKeys && key is! String) {
        continue;
      }
      final value = entry.value;
      final V mappedValue;
      if (value != null) {
        if (mapValue == null) {
          mappedValue = value as V;
        } else {
          mappedValue = mapValue(
            RequiredPick(value, path: locationOf(key), context: context),
          );
        }
      } else if (whenNullValue != null) {
        mappedValue =
            whenNullValue(Pick(null, path: locationOf(key), context: context));
      } else if (mapValue != null) {
        // null values are skipped, like the null items of asList*
        continue;
      } else {
        mappedValue = value as V;
      }

      final K mappedKey;
      if (mapKey == null) {
        mappedKey = key as K;
      } else {
        // a path can't point at a key, the pick of a key is located at its map
        mappedKey = mapKey(Pick(key, path: location, context: context));
      }
      result[mappedKey] = mappedValue;
    }
    return result;
  }

  /// Returns the picked [value] as [Map]. This method throws when [value] is
  /// not a [Map] or [isAbsent]
  ///
  /// {@macro Pick.asMap}
  Map<RK, RV> asMapOrThrow<RK, RV>({
    RK Function(Pick key)? mapKey,
    RV Function(RequiredPick pick)? mapValue,
    RV Function(Pick pick)? whenNullValue,
  }) {
    final value = this.value;
    if (value == null) {
      throw PickException.fromPick(
        this,
        'expected a non-null value',
        hint:
            'Use asMapOrEmpty()/asMapOrNull() when the value may be null/absent at some point (Map<$RK, $RV>?).',
      );
    }
    return _parse(value, mapKey, mapValue, whenNullValue);
  }

  /// Returns the picked [value] as [Map] or an empty map when the `value`
  /// isn't a [Map] or [isAbsent].
  ///
  /// {@macro Pick.asMap}
  Map<RK, RV> asMapOrEmpty<RK, RV>({
    RK Function(Pick key)? mapKey,
    RV Function(RequiredPick pick)? mapValue,
    RV Function(Pick pick)? whenNullValue,
  }) {
    final value = this.value;
    if (value == null) return <RK, RV>{};
    if (value is! Map) return <RK, RV>{};
    return _parse(value, mapKey, mapValue, whenNullValue);
  }

  /// Returns the picked [value] as [Map] or null when the `value`
  /// isn't a [Map] or [isAbsent].
  ///
  /// {@macro Pick.asMap}
  Map<RK, RV>? asMapOrNull<RK, RV>({
    RK Function(Pick key)? mapKey,
    RV Function(RequiredPick pick)? mapValue,
    RV Function(Pick pick)? whenNullValue,
  }) {
    final value = this.value;
    if (value == null) return null;
    if (value is! Map) return null;
    return _parse(value, mapKey, mapValue, whenNullValue);
  }

  /// Returns the picked [value] as JSON object
  ///
  /// {@template Pick.asJsonObject}
  /// A JSON object is a [Map] with [String] keys, the type `fromJson`
  /// functions expect.
  ///
  /// Entries with a key that isn't a [String] are ignored. Use
  /// [asMapOrThrow] for maps with other keys.
  ///
  /// ```dart
  /// final user = User.fromJson(pick(json, 'user').asJsonObjectOrThrow());
  /// ```
  ///
  /// {@macro Pick.mapEntries}
  ///
  /// ```dart
  /// final Map<String, Shoe> shoes = pick({
  ///   'nike': {'id': '421'},
  ///   'adidas': {'id': '532'},
  /// }).asJsonObjectOrThrow(mapValue: Shoe.fromPick);
  /// ```
  ///
  /// The keys stay [String]s, [mapKey] can rename them or return a type that
  /// is a [String], like an extension type. Use [asMapOrThrow] to convert
  /// the keys to any other type.
  ///
  /// If [mapKey] maps multiple retained entries to the same key, the value
  /// from the last entry in the source map's iteration order replaces the
  /// earlier values.
  /// {@endtemplate}
  Map<K, V> _parseJsonObject<K extends String, V>(
    Object value,
    K Function(Pick key)? mapKey,
    V Function(RequiredPick pick)? mapValue,
    V Function(Pick pick)? whenNullValue,
  ) {
    if (value is! Map) {
      throw PickException.fromPick(this, 'expected a Map');
    }
    return _mapEntries(
      value,
      onlyStringKeys: true,
      mapKey: mapKey,
      mapValue: mapValue,
      whenNullValue: whenNullValue,
    );
  }

  /// Returns the picked [value] as JSON object. This method throws when
  /// [value] is not a [Map] or [isAbsent]
  ///
  /// {@macro Pick.asJsonObject}
  Map<K, V> asJsonObjectOrThrow<K extends String, V extends Object?>({
    K Function(Pick key)? mapKey,
    V Function(RequiredPick pick)? mapValue,
    V Function(Pick pick)? whenNullValue,
  }) {
    final value = this.value;
    if (value == null) {
      throw PickException.fromPick(
        this,
        'expected a non-null value',
        hint:
            'Use asJsonObjectOrEmpty()/asJsonObjectOrNull() when the value may be null/absent at some point (Map<$K, $V>?).',
      );
    }
    return _parseJsonObject(value, mapKey, mapValue, whenNullValue);
  }

  /// Returns the picked [value] as JSON object or an empty map when the
  /// `value` isn't a [Map] or [isAbsent].
  ///
  /// {@macro Pick.asJsonObject}
  Map<K, V> asJsonObjectOrEmpty<K extends String, V extends Object?>({
    K Function(Pick key)? mapKey,
    V Function(RequiredPick pick)? mapValue,
    V Function(Pick pick)? whenNullValue,
  }) {
    final value = this.value;
    if (value == null) return <K, V>{};
    if (value is! Map) return <K, V>{};
    return _parseJsonObject(value, mapKey, mapValue, whenNullValue);
  }

  /// Returns the picked [value] as JSON object or null when the `value`
  /// isn't a [Map] or [isAbsent].
  ///
  /// {@macro Pick.asJsonObject}
  Map<K, V>? asJsonObjectOrNull<K extends String, V extends Object?>({
    K Function(Pick key)? mapKey,
    V Function(RequiredPick pick)? mapValue,
    V Function(Pick pick)? whenNullValue,
  }) {
    final value = this.value;
    if (value == null) return null;
    if (value is! Map) return null;
    return _parseJsonObject(value, mapKey, mapValue, whenNullValue);
  }
}
