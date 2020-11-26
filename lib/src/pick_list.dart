import 'package:deep_pick/src/pick.dart';

typedef T WhenNullMapper<T>(int index, Map<String, dynamic> context);

extension ListPick on RequiredPick {
  List<T> asList<T>(T Function(RequiredPick) map,
      {WhenNullMapper<T>? whenNull}) {
    final value = this.value;
    if (value is List) {
      final result = <T>[];
      var index = -1;
      for (final item in value) {
        index++;
        if (item != null) {
          final picked = RequiredPick(item as Object,
              path: [...path, index++], context: context);
          result.add(map(picked));
          continue;
        }
        if (whenNull == null) {
          // skip null items when whenNull isn't provided
          continue;
        }
        try {
          result.add(whenNull(index, context));
          continue;
        } catch (e) {
          print('whenNull at location ${location()} index: $index crashed instead of returning a $T');
          rethrow;
        }
      }
      return result;
    }
    throw PickException(
        "value $value of type ${value.runtimeType} at location ${location()} can't be casted to List<dynamic>");
  }
}

extension NullableListPick on Pick {
  // This deprecation is used to promote the `.required()` in auto-completion.
  // Therefore it is not intended to be ever removed
  @Deprecated(
      'By default values are optional and can only be converted when a fallback is provided '
      'i.e. .asListOrNull() which falls back to `null`. '
      'Use .required().asList() in cases the value is mandatory. '
      "It will crash when the value couldn't be picked.")
  List<T> asList<T>(T Function(RequiredPick) map) {
    if (value == null) {
      throw PickException(
          'value at location ${location()} is null and not an instance of List<$T>');
    }
    return required().asList(map);
  }

  List<T> asListOrEmpty<T>(T Function(RequiredPick) map,
      {WhenNullMapper<T>? whenNull}) {
    if (value == null) return <T>[];
    if (value is! List) return <T>[];
    return required().asList(map, whenNull: whenNull);
  }

  List<T>? asListOrNull<T>(T Function(RequiredPick) map,
      {WhenNullMapper<T>? whenNull}) {
    if (value == null) return null;
    if (value is! List) return null;
    return required().asList(map, whenNull: whenNull);
  }
}
