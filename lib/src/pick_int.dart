import 'package:deep_pick/src/pick.dart';

extension IntPick on RequiredPick {
  /// Returns the picked [value] as [int]
  ///
  /// {@template Pick.asInt}
  /// Parses the picked value as [int]. Other types are parsable as well
  /// - [String] is gets parsed via [int.tryParse]
  /// - [double] is gets converted to [int] via [num.toInt()]
  /// {@endtemplate}
  int asInt() {
    final value = this.value;
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    throw PickException('value $value of type ${value.runtimeType} '
        'at location ${location()} can not be parsed as int');
  }
}

extension NullableIntPick on Pick {
  @Deprecated('Use .asIntOrThrow()')
  int Function() get asInt => asIntOrThrow;

  /// Returns the picked [value] as [int] or throws
  ///
  /// {@macro Pick.asInt}
  int asIntOrThrow() {
    withContext(requiredPickErrorHintKey,
        'Use asIntOrNull() when the value may be null/absent at some point (int?).');
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
