import 'package:deep_pick/src/pick.dart';

extension IntPick on RequiredPick {
  /// Returns the picked [value] as [int]
  ///
  /// {@template Pick.asInt}
  /// Parses the picked value as [int]. Also tries to parse [String] as [int]
  /// via [int.tryParse]
  /// {@endtemplate}
  int asInt() {
    final value = this.value;
    if (value is int) {
      return value;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    throw PickException(
        "value $value of type ${value.runtimeType} at location ${location()} can't be casted to int");
  }
}

extension NullableIntPick on Pick {
  // This deprecation is used to promote the `.required()` in auto-completion.
  // Therefore it is not intended to be ever removed
  @Deprecated(
      'By default values are optional and can only be converted when a fallback is provided '
      'i.e. .asIntOrNUll() which falls back to `null`. '
      'Use .required().asInt() in cases the value is mandatory. '
      "It will crash when the value couldn't be picked.")
  int asInt() {
    if (value == null) {
      throw PickException(
          'value at location ${location()} is null and not an instance of int');
    }
    return required().asInt();
  }

  /// Returns the picked [value] as [int?] or returns `null` when the picked
  /// value is absent
  ///
  /// {@macro Pick.asInt}
  int? asIntOrNull() {
    if (value == null) return null;
    try {
      return required().asInt();
    } catch (_) {
      return null;
    }
  }
}
