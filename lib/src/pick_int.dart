import 'package:deep_pick/src/pick.dart';

extension NullableIntPick on Pick {
  /// Returns the picked [value] as [int]
  ///
  /// {@template Pick.asInt}
  /// Parses the picked value as [int]. Also tries to parse [String] as [int]
  /// Set [roundDouble] to round [double] to [int]
  /// Set [truncateDouble] to cut off decimals
  /// [roundDouble] and [truncateDouble] can not be true at the same time
  /// via [int.tryParse]
  /// {@endtemplate}
  int _parse(bool roundDouble, bool truncateDouble) {
    final value = required().value;
    if (roundDouble && truncateDouble) {
      throw PickException(
        '[roundDouble] and [truncateDouble] can not be true at the same time',
      );
    }
    if (value is int) {
      return value;
    }
    if (value is num && roundDouble) {
      return value.round();
    }
    if (value is num && truncateDouble) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }

    throw PickException(
      'Type ${value.runtimeType} of $debugParsingExit can not be parsed as int, set [roundDouble] or [truncateDouble] to parse from double',
    );
  }

  /// Returns the picked [value] as [int] or throws
  ///
  /// {@macro Pick.asInt}
  int asIntOrThrow({bool roundDouble = false, bool truncateDouble = false}) {
    withContext(
      requiredPickErrorHintKey,
      'Use asIntOrNull() when the value may be null/absent at some point (int?).',
    );
    return _parse(roundDouble, truncateDouble);
  }

  /// Returns the picked [value] as [int?] or returns `null` when the picked
  /// value is absent
  ///
  /// {@macro Pick.asInt}
  int? asIntOrNull({bool roundDouble = false, bool truncateDouble = false}) {
    if (value == null) return null;
    try {
      return _parse(roundDouble, truncateDouble);
    } catch (_) {
      return null;
    }
  }
}
