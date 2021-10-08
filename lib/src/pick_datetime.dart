// ignore_for_file: constant_identifier_names
import 'package:deep_pick/src/pick.dart';

/// The format of the to-be-parsed String that will be converted to [DateTime]
enum PickDateFormat {
  /// ISO 8601 is the most common data time representation
  ///
  /// https://www.w3.org/TR/NOTE-datetime
  ///
  /// Example:
  /// - `2005-08-15T15:52:01+0000`
  ISO_8601,

  /// The typical HTTP date header
  ///
  /// [RFC-1123](http://tools.ietf.org/html/rfc1123) (specifically
  /// [RFC-5322 Section 3.3](https://datatracker.ietf.org/doc/html/rfc5322#section-3.3))
  /// based on [RFC-822](https://datatracker.ietf.org/doc/html/rfc822)
  ///
  /// See https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Date
  /// See https://www.rfc-editor.org/rfc/rfc2616#section-3.3
  ///
  /// Example:
  /// - `Date: Wed, 21 Oct 2015 07:28:00 GMT`
  RFC_1123,

  /// The C language `asctime()` date format, used as legacy format by HTTP date
  /// headers
  ///
  /// See https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Date
  /// See https://www.rfc-editor.org/rfc/rfc2616#section-3.3
  ///
  /// Example:
  /// - `Sun Nov  6 08:49:37 1994`
  /// - `Fri Feb 15 14:45:01 2013`
  ANSI_C_asctime,

  /// A valid but rarely used format for HTTP date headers
  ///
  /// https://datatracker.ietf.org/doc/html/rfc850, obsolete by
  /// [RFC 1036](https://datatracker.ietf.org/doc/html/rfc1036)
  ///
  /// Note in particular that ctime format is not acceptable
  ///
  /// See https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Date
  /// See https://www.rfc-editor.org/rfc/rfc2616#section-3.3
  ///
  /// Format:
  /// `Weekday, DD-Mon-YY HH:MM:SS TIMEZONE`
  ///
  /// Example:
  /// - `Thu Jan  1 00:00:00 1970`
  /// - `Sun, 6-Nov-94 08:49:37 GMT`
  /// - `Monday, 15-Aug-05 15:52:01 UTC`
  RFC_850,
}

extension NullableDateTimePick on Pick {
  @Deprecated('Use .asDateTimeOrThrow()')
  DateTime Function() get asDateTime => asDateTimeOrThrow;

  /// Parses the picked non-null [value] as [DateTime] or throws
  ///
  /// {@template Pick.asDateTime}
  /// Tries to parse the most common date formats such as ISO 8601, RFC 3339,
  /// RFC 1123, RFC 5322 and ANSI C's asctime()
  ///
  /// Optionally accepts a [format] defining the exact to be parsed format.
  /// By default, all formats will be attempted
  ///
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
  /// - `'Thu, 1 Jan 1970 00:00:00 GMT'`
  /// - `'Thursday, 1-Jan-1970 00:00:00 GMT'`
  /// - `'Thu Jan  1 00:00:00 1970'`
  /// {@endtemplate}
  DateTime _parse({PickDateFormat? format}) {
    final value = required().value;
    if (value is DateTime) {
      return value;
    }

    final formats = {
      PickDateFormat.ISO_8601: _parseIso8601,
      PickDateFormat.RFC_1123: _parseRfc1123,
      PickDateFormat.RFC_850: _parseRfc850,
      PickDateFormat.ANSI_C_asctime: _parseAnsiCAsctime,
    };

    if (format != null) {
      final dateTime = formats[format]!();
      if (dateTime != null) {
        return dateTime;
      }

      throw PickException(
          'Type ${value.runtimeType} of $debugParsingExit can not be parsed as DateTime using $format');
    }

    // without format, try all formats
    for (final entry in formats.entries) {
      final dateTime = entry.value();
      if (dateTime != null) {
        return dateTime;
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
  DateTime asDateTimeOrThrow({PickDateFormat? format}) {
    withContext(requiredPickErrorHintKey,
        'Use asDateTimeOrNull() when the value may be null/absent at some point (DateTime?).');
    return _parse(format: format);
  }

  /// Parses the picked [value] as ISO 8601 String to [DateTime] or returns `null`
  ///
  /// {@macro Pick.asDateTime}
  DateTime? asDateTimeOrNull({PickDateFormat? format}) {
    if (value == null) return null;
    try {
      return _parse(format: format);
    } catch (_) {
      return null;
    }
  }

  /// [PickDateFormat.ISO_8601]
  DateTime? _parseIso8601() {
    final value = required().value;
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  /// [PickDateFormat.RFC_1123]
  DateTime? _parseRfc1123() {
    final value = required().value;
    if (value is! String) return null;
    // not using HttpDate.parse because it is not available in the browsers
    try {
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
      return null;
    }
  }

  /// [PickDateFormat.ANSI_C_asctime]
  DateTime? _parseAnsiCAsctime() {
    final value = required().value;
    if (value is! String) return null;
    try {
      final asctimeRegex =
          RegExp(r'^\s*(\S{3})\s+(\S{3})\s*(\d+)\s+(\d+):(\d+):(\d+)\s+(\d+)');
      final match = asctimeRegex.firstMatch(value)!;
      final month = _months[match.group(2)!]!;
      final day = int.parse(match.group(3)!);
      final hour = int.parse(match.group(4)!);
      final minute = int.parse(match.group(5)!);
      final seconds = int.parse(match.group(6)!);
      final year = int.parse(match.group(7)!);
      return DateTime.utc(year, month, day, hour, minute, seconds);
    } catch (_) {
      return null;
    }
  }

  /// [PickDateFormat.RFC_850]
  DateTime? _parseRfc850() {
    final value = required().value;
    if (value is! String) return null;
    try {
      final rfc850Regex =
          RegExp(r'^\s*(\S+),\s*(\d+)-(\S{3})-(\d+)\s+(\d+):(\d+):(\d+)\s*GMT');
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
      return null;
    }
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
