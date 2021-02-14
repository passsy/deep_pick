import 'package:deep_pick/src/pick.dart';

extension NullableIntPick on Pick {
  @Deprecated('Use .asIntOrThrow()')
  int Function() get asInt => asIntOrThrow;

  /// Returns the picked [value] as [int]
  ///
  /// {@template Pick.asInt}
  /// Parses the picked value as [int]. Also tries to parse [String] as [int]
  /// via [int.tryParse]
  /// {@endtemplate}
  int _parse() {
    final value = required().value;
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
        'Type ${value.runtimeType} of $debugParsingExit can not be parsed as int');
  }

  /// Returns the picked [value] as [int] or throws
  ///
  /// {@macro Pick.asInt}
  int asIntOrThrow() {
    withContext(requiredPickErrorHintKey,
        'Use asIntOrNull() when the value may be null/absent at some point (int?).');
    return _parse();
  }

  /// Returns the picked [value] as [int?] or returns `null` when the picked
  /// value is absent
  ///
  /// {@macro Pick.asInt}
  int? asIntOrNull() {
    if (value == null) return null;
    try {
      return _parse();
    } catch (_) {
      return null;
    }
  }
}
