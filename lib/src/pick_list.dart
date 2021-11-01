import 'package:deep_pick/src/pick.dart';

extension NullableListPick on Pick {
  /// Returns the items of the [List] as list, mapped each item with [map]
  ///
  /// {@template Pick.asList}
  /// Each item in the list gets mapped, even when the list contains `null`
  /// values. To simplify the api, only non-null values get mapped with the
  /// [map] function. By default, `null` values are ignored. To explicitly
  /// map `null` values, use the [whenNull] mapping function.
  ///
  /// ```dart
  /// final persons = pick([
  ///   {'name': 'John Snow'},
  ///   {'name': 'Daenerys Targaryen'},
  ///   null, // <-- valid value
  /// ]).asListOrThrow(
  ///   (pick) => Person.fromPick(pick),
  ///   whenNull: (it) => null,
  /// )
  ///
  /// // persons
  /// [
  ///   Person(name: 'John Snow'),
  ///   Person(name: 'Daenerys Targaryen'),
  ///   null,
  /// ]
  /// ```
  ///
  /// For some apis it is important to get the access to the [index] of an
  /// element in the list. Access it via [index] which is only available for
  /// list elements, otherwise `null`.
  ///
  /// Usage:
  ///
  /// ```dart
  /// pick(["John", "Paul", "George", "Ringo"]).asListOrThrow((pick) {
  ///  final index = pick.index!;
  ///  return Artist(id: index, name: pick.asStringOrThrow());
  /// );
  /// ```
  /// {@endtemplate}
  List<T> _parse<T>(
    T Function(RequiredPick) map, {
    T Function(Pick pick)? whenNull,
  }) {
    final value = required().value;
    if (value is List) {
      final result = <T>[];
      var index = -1;
      for (final item in value) {
        index++;
        if (item != null) {
          final picked =
              RequiredPick(item, path: [...path, index], context: context);
          result.add(map(picked));
          continue;
        }
        if (whenNull == null) {
          // skip null items when whenNull isn't provided
          continue;
        }
        try {
          final pick = Pick(null, path: [...path, index], context: context);
          result.add(whenNull(pick));
          continue;
        } catch (e) {
          // ignore: avoid_print
          print(
            'whenNull at location $debugParsingExit index: $index crashed instead of returning a $T',
          );
          rethrow;
        }
      }
      return result;
    }
    throw PickException(
      'Type ${value.runtimeType} of $debugParsingExit can not be casted to List<dynamic>',
    );
  }

  /// Returns the picked [value] as [List]. This method throws when [value] is
  /// not a `List` or [isAbsent]
  ///
  /// {@macro Pick.asList}
  List<T> asListOrThrow<T>(
    T Function(RequiredPick) map, {
    T Function(Pick pick)? whenNull,
  }) {
    withContext(
      requiredPickErrorHintKey,
      'Use asListOrEmpty()/asListOrNull() when the value may be null/absent at some point (List<$T>?).',
    );
    return _parse(map, whenNull: whenNull);
  }

  /// Returns the picked [value] as [List] or an empty list when the `value`
  /// isn't a [List] or [isAbsent].
  ///
  /// {@macro Pick.asList}
  List<T> asListOrEmpty<T>(
    T Function(RequiredPick) map, {
    T Function(Pick pick)? whenNull,
  }) {
    if (value == null) return <T>[];
    if (value is! List) return <T>[];
    return _parse(map, whenNull: whenNull);
  }

  /// Returns the picked [value] as [List] or null when the `value`
  /// isn't a [List] or [isAbsent].
  ///
  /// {@macro Pick.asList}
  List<T>? asListOrNull<T>(
    T Function(RequiredPick) map, {
    T Function(Pick pick)? whenNull,
  }) {
    if (value == null) return null;
    if (value is! List) return null;
    return _parse(map, whenNull: whenNull);
  }
}
