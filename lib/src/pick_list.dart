import 'package:deep_pick/src/pick.dart';

extension NullableListPick on Pick {
  @Deprecated('Use .asListOrThrow()')
  List<T> asList<T>([T Function(Pick)/*?*/ map]) {
    return asListOrThrow((it) {
      final mapFn = map ?? (Pick it) => it.value as T;
      return mapFn(it.nullable());
    }, whenNull: (it) => it.value as T);
  }

  List<T> _parse<T>(T Function(RequiredPick) map,
      {T Function(Pick pick)/*?*/ whenNull}) {
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
              'whenNull at location $debugParsingExit index: $index crashed instead of returning a $T');
          rethrow;
        }
      }
      return result;
    }
    throw PickException(
        'Type ${value.runtimeType} of $debugParsingExit can not be casted to List<dynamic>');
  }

  List<T> asListOrThrow<T>(T Function(RequiredPick) map,
      {T Function(Pick pick)/*?*/ whenNull}) {
    withContext(requiredPickErrorHintKey,
        'Use asListOrEmpty()/asListOrNull() when the value may be null/absent at some point (List<$T>?).');
    return _parse(map, whenNull: whenNull);
  }

  List<T> asListOrEmpty<T>(T Function(RequiredPick) map,
      {T Function(Pick pick)/*?*/ whenNull}) {
    if (value == null) return <T>[];
    if (value is! List) return <T>[];
    return _parse(map, whenNull: whenNull);
  }

  List<T>/*?*/ asListOrNull<T>(T Function(RequiredPick) map,
      {T Function(Pick pick)/*?*/ whenNull}) {
    if (value == null) return null;
    if (value is! List) return null;
    return _parse(map, whenNull: whenNull);
  }
}
