import 'package:deep_pick/src/pick.dart';

extension NullableDateTimePick on Pick {
  @Deprecated('Use .asDateTimeOrThrow()')
  DateTime Function() get asDateTime => asDateTimeOrThrow;

  /// Parses the picked non-null [value] as [DateTime] or throws
  ///
  /// {@template Pick.asDateTime}
  /// Examples of parsable date formats:
  ///
  /// - `'2012-02-27 13:27:00'`
  /// - `'2012-02-27 13:27:00.123456z'`
  /// - `'2012-02-27 13:27:00,123456z'`
  /// - `'20120227 13:27:00'`
  /// - `'20120227T132700'`
  /// - `'20120227'`
  /// - `'+20120227'`
  /// - `'2012-02-27T14Z'`
  /// - `'2012-02-27T14+00:00'`
  /// - `'-123450101 00:00:00 Z'`: in the year -12345.
  /// - `'2002-02-27T14:00:00-0500'`: Same as `'2002-02-27T19:00:00Z'`
  /// {@endtemplate}
  DateTime _parse() {
    final value = required().value;
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      final dateTime = DateTime.tryParse(value);
      if (dateTime != null) {
        return dateTime;
      }
    }
    throw PickException(
        'Type ${value.runtimeType} of $debugParsingExit can not be parsed as DateTime');
  }

  /// Parses the picked [value] as [DateTime] or throws
  ///
  /// Shorthand for `.required().asDateTime()`
  ///
  /// {@macro Pick.asDateTime}
  DateTime asDateTimeOrThrow() {
    withContext(requiredPickErrorHintKey,
        'Use asDateTimeOrNull() when the value may be null/absent at some point (DateTime?).');
    return _parse();
  }

  /// Parses the picked [value] as [DateTime] or returns `null`
  ///
  /// {@macro Pick.asDateTime}
  DateTime? asDateTimeOrNull() {
    if (value == null) return null;
    try {
      return _parse();
    } catch (_) {
      return null;
    }
  }
}
