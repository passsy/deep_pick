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
      try {
        final parsed = _parseDateTime();
        if (parsed != null) {
          return parsed;
        }
      } on PickException catch (e, stack) {
        // continue parsing
      }
    }
    if (value is String) {
      try {
        final parsed = _parseHttpDate();
        if (parsed != null) {
          return parsed;
        }
      } on PickException catch (e, stack) {
        // continue parsing
      }
    }

    throw PickException(
        'Type ${value.runtimeType} of $debugParsingExit can not be parsed as DateTime');
  }

  /// Parses the picked [value] as ISO 8601 String to [DateTime] or throws
  ///
  /// Shorthand for `.required().asDateTime()`
  ///
  /// {@macro Pick.asDateTime}
  DateTime asDateTimeOrThrow() {
    withContext(requiredPickErrorHintKey,
        'Use asDateTimeOrNull() when the value may be null/absent at some point (DateTime?).');
    return _parse();
  }

  /// Parses the picked [value] as ISO 8601 String to [DateTime] or returns `null`
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
  DateTime _parseDateTime() {
    final value = required().value;
    if (value is String) {
      final dateTime = DateTime.tryParse(value);
      if (dateTime != null) {
        return dateTime;
      }
    }
    throw PickException(
        'Type ${value.runtimeType} of $debugParsingExit can not be parsed as DateTime');
  }

  /// {@template Pick.asHttpDate}
  /// Parses the `Date` http header String of the formats
  /// [RFC-1123](http://tools.ietf.org/html/rfc1123) (specifically
  /// [RFC-5322 Section 3.3](https://datatracker.ietf.org/doc/html/rfc5322#section-3.3)),
  /// [RFC-850](http://tools.ietf.org/html/rfc850 'RFC-850') or
  /// ANSI C's asctime() format. These formats are listed here.
  ///
  /// - Thu, 1 Jan 1970 00:00:00 GMT
  /// - Thursday, 1-Jan-1970 00:00:00 GMT
  /// - Thu Jan  1 00:00:00 1970
  ///
  /// See https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Date
  /// {@endtemplate}
  DateTime _parseHttpDate() {
    final value = required().value;
    if (value is String) {
      // not using HttpDate.parse because it is not available in the browsers
      try {
        // 95% of all date headers use RFC1123 these days
        final rfc1123Regex = RegExp(
            r'^\s*(\S{3}),\s*(\d+)\s*(\S{3})\s*(\d+)\s+(\d+):(\d+):(\d+)\s*GMT');
        final match = rfc1123Regex.firstMatch(value)!;
        final day = int.parse(match.group(2)!);
        final month = _months[match.group(3)!]!;
        final year = int.parse(match.group(4)!);
        final hour = int.parse(match.group(5)!);
        final minute = int.parse(match.group(6)!);
        final seconds = int.parse(match.group(7)!);
        return DateTime.utc(year, month, day, hour, minute, seconds);
      } catch (_) {
        // ignore
      }

      try {
        // fallback to  ANSI C's asctime()
        final asctimeRegex = RegExp(
            r'^\s*(\S{3})\s+(\S{3})\s*(\d+)\s+(\d+):(\d+):(\d+)\s+(\d+)');
        final match = asctimeRegex.firstMatch(value)!;
        final month = _months[match.group(2)!]!;
        final day = int.parse(match.group(3)!);
        final hour = int.parse(match.group(4)!);
        final minute = int.parse(match.group(5)!);
        final seconds = int.parse(match.group(6)!);
        final year = int.parse(match.group(7)!);
        return DateTime.utc(year, month, day, hour, minute, seconds);
      } catch (_) {
        // ignore
      }

      try {
        // fallback to ancient rfc850
        final rfc850Regex = RegExp(
            r'^\s*(\S+),\s*(\d+)-(\S{3})-(\d+)\s+(\d+):(\d+):(\d+)\s*GMT');
        final match = rfc850Regex.firstMatch(value)!;
        final day = int.parse(match.group(2)!);
        final month = _months[match.group(3)!]!;
        var year = int.parse(match.group(4)!);
        if (year < 100) {
          year = 1900 + year;
        }
        final hour = int.parse(match.group(5)!);
        final minute = int.parse(match.group(6)!);
        final seconds = int.parse(match.group(7)!);
        return DateTime.utc(year, month, day, hour, minute, seconds);
      } catch (_) {
        // ignore
      }
      throw PickException('"$value" can not be parsed as DateTime');
    }
    throw PickException(
        'Type ${value.runtimeType} of $debugParsingExit can not be parsed as DateTime');
  }
}

const _months = {
  'Jan': 1,
  'Feb': 2,
  'Mar': 3,
  'Apr': 4,
  'May': 5,
  'Jun': 6,
  'Jul': 7,
  'Aug': 8,
  'Sep': 9,
  'Oct': 10,
  'Nov': 11,
  'Dec': 12,
};
