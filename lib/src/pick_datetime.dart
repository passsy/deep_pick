// ignore_for_file: constant_identifier_names
import 'package:deep_pick/src/pick.dart';

/// The format of the to-be-parsed String that will be converted to [DateTime]
enum PickDateFormat {
  /// ISO 8601 is the most common data time representation
  ///
  /// https://www.w3.org/TR/NOTE-datetime
  ///
  /// Also covers [RFC-3339](https://datatracker.ietf.org/doc/html/rfc3339#section-5.6)
  ///
  /// Example:
  /// - `2005-08-15T15:52:01+0000`
  ISO_8601,

  /// A typical format used in the web that's not ISO8601
  ///
  /// [RFC-1123](http://tools.ietf.org/html/rfc1123) (specifically
  /// [RFC-5322 Section 3.3](https://datatracker.ietf.org/doc/html/rfc5322#section-3.3))
  /// based on [RFC-822](https://datatracker.ietf.org/doc/html/rfc822)
  ///
  /// Used as
  /// - HTTP date header https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Date, https://www.rfc-editor.org/rfc/rfc2616#section-3.3
  /// - RSS2 pubDate, lastBuildDate https://validator.w3.org/feed/docs/rss2.html
  ///
  /// Also matches [RFC 1036](https://datatracker.ietf.org/doc/html/rfc1036#section-2.1.2), which is just a specific version of RFC 822.
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

  /// A valid but rarely used format for HTTP date headers, and cookies
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

    final Map<PickDateFormat, DateTime? Function()> formats = {
      PickDateFormat.ISO_8601: _parseIso8601,
      PickDateFormat.RFC_1123: _parseRfc1123,
      PickDateFormat.RFC_850: _parseRfc850,
      PickDateFormat.ANSI_C_asctime: _parseAnsiCAsctime,
    };

    if (format != null) {
      // Use one specific format
      final dateTime = formats[format]!();
      if (dateTime != null) {
        return dateTime;
      }

      throw PickException(
        'Type ${value.runtimeType} of $debugParsingExit can not be parsed as DateTime using $format',
      );
    }

    // Try all available formats
    final errorsByFormat = <PickDateFormat, Object>{};
    for (final entry in formats.entries) {
      try {
        final dateTime = entry.value();
        if (dateTime != null) {
          return dateTime;
        }
      } catch (e) {
        errorsByFormat[entry.key] = e;
      }
    }

    throw PickException(
      'Type ${value.runtimeType} of $debugParsingExit can not be parsed as DateTime. '
      'The different parsers produced the following errors: $errorsByFormat',
    );
  }

  /// Parses the picked [value] as ISO 8601 String to [DateTime] or throws
  ///
  /// Shorthand for `.required().asDateTime()`
  ///
  /// {@macro Pick.asDateTime}
  DateTime asDateTimeOrThrow({PickDateFormat? format}) {
    withContext(
      requiredPickErrorHintKey,
      'Use asDateTimeOrNull() when the value may be null/absent at some point (DateTime?).',
    );
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

    // DartTime.tryParse() does not support timezones like EST, PDT, etc.
    // deep_pick takes care of the time zone and DartTime.parse() of the rest
    final trimmedValue = value.trim();
    final timeZoneComponent =
        RegExp(r'(?<=[\d\W])[a-zA-Z]+$').firstMatch(trimmedValue)?.group(0);

    if (timeZoneComponent == null) {
      // no timeZoneComponent, DartTime can 100% parse it
      return DateTime.tryParse(trimmedValue);
    }

    final timeZoneOffset = _parseTimeZoneOffset(timeZoneComponent);
    // Remove the timezone from the string and add Z, so that it's parsed as UTC
    final withoutTimezone =
        '${trimmedValue.substring(0, trimmedValue.length - timeZoneComponent.length)}Z';
    // combine both again
    return DateTime.tryParse(withoutTimezone)?.add(timeZoneOffset);
  }

  /// [PickDateFormat.RFC_1123]
  DateTime? _parseRfc1123() {
    final value = required().value;
    if (value is! String) return null;
    // not using HttpDate.parse because it is not available in the browsers
    try {
      final rfc1123Regex = RegExp(
        r'^\s*(\S{3}),\s*(\d+)\s*(\S{3})\s*(\d+)\s+(\d+):(\d+):(\d+)\s*([\w+-]+)\s*',
      );
      final match = rfc1123Regex.firstMatch(value)!;
      final day = int.parse(match.group(2)!);
      final month = _months[match.group(3)!]!;
      final year = _normalizeYear(int.parse(match.group(4)!));
      final hour = int.parse(match.group(5)!);
      final minute = int.parse(match.group(6)!);
      final seconds = int.parse(match.group(7)!);
      final timezone = match.group(8);
      final timeZoneOffset = _parseTimeZoneOffset(timezone);
      return DateTime.utc(year, month, day, hour, minute, seconds)
          .add(timeZoneOffset);
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
      final rfc850Regex = RegExp(
        r'^\s*(\S+),\s*(\d+)-(\S{3})-(\d+)\s+(\d+):(\d+):(\d+)\s*([\w+-]+)\s*',
      );
      final match = rfc850Regex.firstMatch(value)!;
      final day = int.parse(match.group(2)!);
      final month = _months[match.group(3)!]!;
      final year = _normalizeYear(int.parse(match.group(4)!));
      final hour = int.parse(match.group(5)!);
      final minute = int.parse(match.group(6)!);
      final seconds = int.parse(match.group(7)!);
      final timezone = match.group(8);
      final timeZoneOffset = _parseTimeZoneOffset(timezone);
      return DateTime.utc(year, month, day, hour, minute, seconds)
          .add(timeZoneOffset);
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

/// This returns a 4-digit year from 2-digit input
///
/// For years 0-49 it returns 2000-2049
/// For years 50-99 it returns 1950-1999
///
/// Logic taken from:
/// https://www.ietf.org/rfc/rfc2822.txt
int _normalizeYear(int year) {
  if (year < 100) {
    if (year < 50) {
      return 2000 + year;
    } else {
      return 1900 + year;
    }
  }
  return year;
}

/// The Duration to add to a DateTime to get the correct time in UTC
///
/// Handles timezone abbreviations (GMT, EST, ...) and offsets (+0400, -0130)
Duration _parseTimeZoneOffset(String? timeZone) {
  if (timeZone == null) {
    return Duration.zero;
  }
  if (RegExp(r'^[+-]\d{4}$').hasMatch(timeZone)) {
    // matches format +0000 or -0000
    final sign = timeZone[0] == '-' ? 1 : -1;
    final hours = timeZone.substring(1, 3);
    final minutes = timeZone.substring(3, 5);
    return Duration(
      hours: int.parse(hours) * sign,
      minutes: int.parse(minutes) * sign,
    );
  }
  // do a simple lookup
  final timeZoneOffset = _timeZoneOffsets[timeZone.toUpperCase()];
  if (timeZoneOffset == null) {
    throw PickException('Unknown time zone abbrevation $timeZone');
  }
  return timeZoneOffset;
}

/// Incomplete list of time zone abbreviations and their offsets towards UTC
///
/// Those are the most common used. Please open a PR if you need more.
const Map<String, Duration> _timeZoneOffsets = {
  'M': Duration(hours: -12),
  'A': Duration(hours: -1),
  'UT': Duration.zero,
  'GMT': Duration.zero,
  'Z': Duration.zero,
  'N': Duration(hours: 1),
  'EST': Duration(hours: 5),
  'EDT': Duration(hours: 5),
  'CST': Duration(hours: 6),
  'CDT': Duration(hours: 6),
  'MST': Duration(hours: 7),
  'MDT': Duration(hours: 7),
  'PST': Duration(hours: 8),
  'PDT': Duration(hours: 8),
  'Y': Duration(hours: 12),
};
