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
  /// {@endtemplate}
  PickedMap<RK, RV> _parse<RK, RV>(Object value) {
    if (value is Map) {
      final view = value.cast<RK, RV>();
      // create copy of casted view so all items are type checked here
      // and not lazily type checked when accessing them
      return PickedMap(Map.of(view), this);
    }
    throw PickException.fromPick(this, 'expected a Map');
  }

  /// Returns the picked [value] as [Map]. This method throws when [value] is
  /// not a [Map] or [isAbsent]
  ///
  /// {@macro Pick.asMap}
  PickedMap<RK, RV> asMapOrThrow<RK, RV>() {
    final value = this.value;
    if (value == null) {
      throw PickException.fromPick(
        this,
        'expected a non-null value',
        hint:
            'Use asMapOrEmpty()/asMapOrNull() when the value may be null/absent at some point (Map<$RK, $RV>?).',
      );
    }
    return _parse(value);
  }

  /// Returns the picked [value] as [Map] or an empty map when the `value`
  /// isn't a [Map] or [isAbsent].
  ///
  /// {@macro Pick.asMap}
  PickedMap<RK, RV> asMapOrEmpty<RK, RV>() {
    final value = this.value;
    if (value == null) return PickedMap(<RK, RV>{}, this);
    if (value is! Map) return PickedMap(<RK, RV>{}, this);
    return _parse(value);
  }

  /// Returns the picked [value] as [Map] or null when the `value`
  /// isn't a [Map] or [isAbsent].
  ///
  /// {@macro Pick.asMap}
  PickedMap<RK, RV>? asMapOrNull<RK, RV>() {
    final value = this.value;
    if (value == null) return null;
    if (value is! Map) return null;
    return _parse(value);
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
  /// {@endtemplate}
  PickedMap<String, Object?> _parseJsonObject(Object value) {
    if (value is Map) {
      final result = <String, Object?>{};
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is String) {
          result[key] = entry.value;
        }
      }
      return PickedMap(result, this);
    }
    throw PickException.fromPick(this, 'expected a Map');
  }

  /// Returns the picked [value] as JSON object. This method throws when
  /// [value] is not a [Map] or [isAbsent]
  ///
  /// {@macro Pick.asJsonObject}
  PickedMap<String, Object?> asJsonObjectOrThrow() {
    final value = this.value;
    if (value == null) {
      throw PickException.fromPick(
        this,
        'expected a non-null value',
        hint:
            'Use asJsonObjectOrEmpty()/asJsonObjectOrNull() when the value may be null/absent at some point (Map<String, Object?>?).',
      );
    }
    return _parseJsonObject(value);
  }

  /// Returns the picked [value] as JSON object or an empty map when the
  /// `value` isn't a [Map] or [isAbsent].
  ///
  /// {@macro Pick.asJsonObject}
  PickedMap<String, Object?> asJsonObjectOrEmpty() {
    final value = this.value;
    if (value == null) return PickedMap(<String, Object?>{}, this);
    if (value is! Map) return PickedMap(<String, Object?>{}, this);
    return _parseJsonObject(value);
  }

  /// Returns the picked [value] as JSON object or null when the `value`
  /// isn't a [Map] or [isAbsent].
  ///
  /// {@macro Pick.asJsonObject}
  PickedMap<String, Object?>? asJsonObjectOrNull() {
    final value = this.value;
    if (value == null) return null;
    if (value is! Map) return null;
    return _parseJsonObject(value);
  }
}
