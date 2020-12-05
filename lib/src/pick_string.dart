import 'package:deep_pick/src/pick.dart';

extension StringPick on RequiredPick {
  /// Returns the picked [value] as String representation; only throws when
  /// the value is `null`.
  ///
  /// {@template Pick.asString}
  /// Parses the picked value as String. If the value is not already a [String]
  /// its [Object.toString()] will be called. This means that this method works
  /// for [int], [double] and any other [Object] which isn't a collection of
  /// values such as a [List] or [Map]
  /// {@endtemplate}
  String asString() {
    final value = this.value;
    if (value is String) {
      return value;
    }
    if (value is List || value is Map) {
      throw PickException(
          'value at location ${location()} is of type ${value.runtimeType}. '
          'Drill further down to a value which is not a List or Map. '
          'value: $value');
    }
    return value.toString();
  }
}

extension NullableStringPick on Pick {
  @Deprecated('Use .asStringOrThrow()')
  String Function() get asString => asStringOrThrow;

  /// Returns the picked [value] as String representation; only throws when
  /// the value is `null`.
  ///
  /// {@macro Pick.asString}
  String asStringOrThrow() {
    withContext(requiredPickErrorHintKey,
        'Use asStringOrNull() when the value may be null/absent at some point (String?).');
    return required().asString();
  }

  /// Returns the picked [value] as [String] or returns `null` when the picked value isn't available
  ///
  /// {@macro Pick.asString}
  String? asStringOrNull() {
    if (value == null) return null;
    try {
      return required().asString();
    } catch (_) {
      return null;
    }
  }
}
