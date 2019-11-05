import 'package:deep_pick/src/pick.dart';

extension ListPick on RequiredPick {
  List<T> asList<T>([T Function(Pick) map]) {
    if (value is List) {
      if (map == null) {
        return (value as List<dynamic>).cast<T>();
      } else {
        var i = 0;
        return (value as List<dynamic>)
            .map((it) => map(Pick(it, [...path, i++])))
            .toList(growable: false);
      }
    } else {
      throw PickException(
          "value $value of type ${value.runtimeType} at location ${location()} can't be casted to List<dynamic>");
    }
  }
}

extension NullableListPick on Pick {
  List<T> asList<T>([T Function(Pick) map]) {
    if (value == null) {
      throw PickException(
          "value at location ${location()} is null and not an instance of List<$T>");
    }
    return required().asList(map);
  }

  List<T> asListOrEmpty<T>([T Function(Pick) map]) {
    if (value == null) return <T>[];
    try {
      return required().asList(map);
    } catch (_) {
      return <T>[];
    }
  }

  List<T> /*?*/ asListOrNull<T>([T Function(Pick) map]) {
    if (value == null) return null;
    try {
      return required().asList(map);
    } catch (_) {
      return null;
    }
  }
}
