part of 'pick.dart';

/// The [Map] the `asMap*` and `asJsonObject*` parsers return
///
/// It is a regular [Map] and can be passed to any `fromJson` function. On
/// top of that it knows where it was picked from, which allows parsing its
/// keys and values with picks:
///
/// ```dart
/// // {"nike": {"id": "421"}, "adidas": {"id": "532"}}
/// final Map<String, Shoe> shoes =
///     pick(json).asJsonObjectOrEmpty().mapValues(Shoe.fromPick);
/// ```
///
/// An error while parsing a value reports the full location, i.e.
/// `adidas.id`.
class PickedMap<K, V> extends MapView<K, V> {
  /// A view of [map], the parsed value of [source]
  ///
  /// Use it in a custom parser that returns a [Map], so that its keys and
  /// values can be mapped with [mapKeys] and [mapValues].
  ///
  /// The keys of [map] have to be the keys of the [Map] that [source] holds,
  /// they locate the values for [mapValues].
  PickedMap(Map<K, V> map, Pick source)
      : _source = source,
        _sourceKeys = null,
        super(map);

  PickedMap._(Map<K, V> map, this._source, this._sourceKeys) : super(map);

  /// The pick of the map
  final Pick _source;

  /// The key each key had in [_source] before [mapKeys] converted it, `null`
  /// while the keys are unchanged
  final Map<K, Object?>? _sourceKeys;

  /// The key that [key] has in the map of [_source]
  Object? _sourceKeyOf(K key) {
    final sourceKeys = _sourceKeys;
    if (sourceKeys == null || !sourceKeys.containsKey(key)) {
      // a key that was not converted, or was added to this map later
      return key;
    }
    return sourceKeys[key];
  }

  /// Parses each value with [map], like the mapper of `asList*` does for the
  /// items of a list
  ///
  /// [map] receives a pick of the value, located at its key. Entries with a
  /// `null` value are ignored.
  ///
  /// ```dart
  /// final Map<String, Shoe> shoes =
  ///     pick(json).asJsonObjectOrEmpty().mapValues(Shoe.fromPick);
  /// ```
  Map<K, R> mapValues<R>(R Function(RequiredPick pick) map) {
    final result = <K, R>{};
    for (final entry in entries) {
      final value = entry.value;
      if (value == null) {
        // null values are skipped, like the null items of asList*
        continue;
      }
      final sourceKey = _sourceKeyOf(entry.key);
      final pick = RequiredPick._from(
        value,
        // a path holds no null, a null key shows up as the word
        path: _extended(_source._path, [sourceKey ?? 'null']),
        context: Map.of(_source.context),
      );
      result[entry.key] = map(pick);
    }
    return result;
  }

  /// Converts each key with [map]
  ///
  /// [map] receives a pick of the key, so the usual parsers work on it. A
  /// path can't point at a key, the pick of a key is located at its map.
  ///
  /// The returned map still knows where its values come from, [mapValues]
  /// can follow.
  ///
  /// ```dart
  /// // {"421": {"name": "Nike Zoom Fly 3"}}
  /// final Map<int, Shoe> shoes = pick(json)
  ///     .asJsonObjectOrEmpty()
  ///     .mapKeys((key) => key.asIntOrThrow())
  ///     .mapValues(Shoe.fromPick);
  /// ```
  ///
  /// When two keys are converted to the same key the later entry wins.
  PickedMap<R, V> mapKeys<R>(R Function(Pick key) map) {
    final result = <R, V>{};
    final sourceKeys = <R, Object?>{};
    for (final entry in entries) {
      final pick = Pick._from(
        null,
        entry.key,
        path: _extended(_source._path, const []),
        context: Map.of(_source.context),
      );
      final key = map(pick);
      result[key] = entry.value;
      sourceKeys[key] = _sourceKeyOf(entry.key);
    }
    return PickedMap._(result, _source, sourceKeys);
  }
}
