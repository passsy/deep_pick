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
        "value $value of type ${value.runtimeType} at location ${location(false)} can't be casted to int");
  }
}

extension NullableIntPick on Pick {
  @Deprecated('Use .asIntOrThrow()')
  int Function() get asInt => asIntOrThrow;

  int asIntOrThrow() {
    if (value == null) {
      throw PickException(
          'value at location ${location(isAbsent())} is null and not an instance of int');
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
