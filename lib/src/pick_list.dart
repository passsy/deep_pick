import 'package:deep_pick/src/pick.dart';

extension ListPick on RequiredPick {
  List<T> asList<T>(T Function(RequiredPick) map,
      {T Function(Pick pick)? whenNull}) {
    final value = this.value;
    if (value is List) {
      final result = <T>[];
      var index = -1;
      for (final item in value) {
        index++;
        if (item != null) {
          final picked = RequiredPick(item as Object,
              path: [...fullPath, index], context: context);
          result.add(map(picked));
          continue;
        }
        if (whenNull == null) {
          // skip null items when whenNull isn't provided
          continue;
        }
        try {
          final pick =
              Pick(null, fullPath: [...fullPath, index], context: context);
          result.add(whenNull(pick));
          continue;
        } catch (e) {
          // ignore: avoid_print
          print(
              'whenNull at location ${location()} index: $index crashed instead of returning a $T');
          rethrow;
        }
      }
      return result;
    }
    throw PickException('value $value of type ${value.runtimeType} '
        'at location ${location()} can not be casted to List<dynamic>');
  }
}

extension NullableListPick on Pick {
  @Deprecated('Use .asListOrThrow()')
  List<T> asList<T>([T Function(Pick) map]) {
    return asListOrThrow((it) => map(it.nullable()));
  }

  List<T> asListOrThrow<T>([T Function(RequiredPick) map]) {
    withContext(requiredPickErrorHintKey,
        'Use asListOrEmpty()/asListOrNull() when the value may be null/absent at some point (List<$T>?).');
    return required().asList(map);
  }

  List<T> asListOrEmpty<T>(T Function(RequiredPick) map,
      {T Function(Pick pick)? whenNull}) {
    if (value == null) return <T>[];
    if (value is! List) return <T>[];
    return required().asList(map, whenNull: whenNull);
  }

  List<T>? asListOrNull<T>(T Function(RequiredPick) map,
      {T Function(Pick pick)? whenNull}) {
    if (value == null) return null;
    if (value is! List) return null;
    return required().asList(map, whenNull: whenNull);
  }
}
