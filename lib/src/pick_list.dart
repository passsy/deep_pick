import 'package:deep_pick/src/pick.dart';

extension ListPick on RequiredPick {
  List<T> asList<T>([T Function(Pick)? map]) {
    final value = this.value;
    if (value is List) {
      if (map == null) {
        return value.cast<T>();
      }
      var i = 0;
      return value
          .map((it) => map(Pick(it, path: [...path, i++], context: context)))
          .toList(growable: false);
    }
    throw PickException('value $value of type ${value.runtimeType} '
        'at location ${location()} can not be casted to List<dynamic>');
  }
}

extension NullableListPick on Pick {
  @Deprecated('Use .asListOrThrow()')
  List<T> asList<T>([T Function(Pick)? map]) {
    return asListOrThrow(map);
  }

  List<T> asListOrThrow<T>([T Function(Pick)? map]) {
    withContext(requiredPickErrorHintKey,
        'Use asListOrEmpty()/asListOrNull() when the value may be null/absent at some point (List<$T>?).');
    return required().asList(map);
  }

  List<T> asListOrEmpty<T>([T Function(Pick)? map]) {
    if (value == null) return <T>[];
    if (value is! List) return <T>[];
    return required().asList(map);
  }

  List<T>? asListOrNull<T>([T Function(Pick)? map]) {
    if (value == null) return null;
    if (value is! List) return null;
    return required().asList(map);
  }
}
