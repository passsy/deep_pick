import 'package:deep_pick/src/pick.dart';

extension StringPick on RequiredPick {
  /// Returns the picked [value] as String
  ///
  /// {@template Pick.asString}
  /// Parses the picked value as String. If the value is not already a [String]
  /// its [Object.toString()] will be called. This means that this method works
  /// for [int], [double] and any other [Object] which isn't a collection of
  /// values such as a [List] or [Map]
  /// {@endtemplate}
  String asString() {
    if (value is String) {
      return value as String;
    } else {
      if (value is List || value is Map) {
        throw PickException(
            'value at location ${location()} is of type ${value.runtimeType}. '
            'Drill further down to a value which is not a List or Map. '
            'value: $value');
      }
      return value.toString();
    }
  }
}

extension NullableStringPick on Pick {
  // This deprecation is used to promote the `.required()` in auto-completion.
  // Therefore it is not intended to be ever removed
  @Deprecated(
      'Use .required().asString() or .asRequiredString() when you require the value to be non-null. '
      'Use .asStringOrNull() when you expect the value to be nullable')
  String asString() {
    if (value == null) {
      throw PickException(
          'value at location ${location()} is null and not a String. '
          'Use asStringOrNull() when null is a valid value (String?)');
    }
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
