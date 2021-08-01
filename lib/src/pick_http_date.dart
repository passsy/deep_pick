import 'package:deep_pick/src/pick.dart';

extension NullableDateHeaderPick on Pick {
  /// {@template Pick.asHttpDate}
  /// Parses the `Date` http header String of the formats
  /// [RFC-1123](http://tools.ietf.org/html/rfc1123 'RFC-1123'),
  /// [RFC-850](http://tools.ietf.org/html/rfc850 'RFC-850') or
  /// ANSI C's asctime() format. These formats are listed here.
  ///
  ///     Thu, 1 Jan 1970 00:00:00 GMT
  ///     Thursday, 1-Jan-1970 00:00:00 GMT
  ///     Thu Jan  1 00:00:00 1970
  ///
  /// See https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Date
  /// {@endtemplate}
  DateTime _parse() {
    final value = required().value;
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      // not using HttpDate.parse because it is not available in the browsers
      return _parseHttpDate(value);
    }
    throw PickException(
        'Type ${value.runtimeType} of $debugParsingExit can not be parsed as DateTime');
  }

  /// Parses the picked [value] as [DateTime] or throws
  ///
  /// {@macro Pick.asHttpDate}
  DateTime asHttpDateOrThrow() {
    withContext(requiredPickErrorHintKey,
        'Use asDateTimeOrNull() when the value may be null/absent at some point (DateTime?).');
    return _parse();
  }

  /// Parses the picked [value] as [DateTime] or returns `null`
  ///
  /// {@macro Pick.asHttpDate}
  DateTime? asHttpDateOrNull() {
    if (value == null) return null;
    try {
      return _parse();
    } catch (_) {
      return null;
    }
  }
}

enum _DateHeaderFormat {
  formatRfc1123,
  formatRfc850,
  formatAsctime,
}

DateTime _parseHttpDate(String date) {
  const asciiSpace = 32;
  const wkdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  var index = 0;
  String tmp;

  _DateHeaderFormat expectWeekday() {
    int weekday;
    // The formatting of the weekday signals the format of the date string.
    final pos = date.indexOf(',', index);
    if (pos == -1) {
      final pos = date.indexOf(' ', index);
      if (pos == -1) throw FormatException('Invalid HTTP date $date');
      tmp = date.substring(index, pos);
      index = pos + 1;
      weekday = wkdays.indexOf(tmp);
      if (weekday != -1) {
        return _DateHeaderFormat.formatAsctime;
      }
    } else {
      tmp = date.substring(index, pos);
      index = pos + 1;
      weekday = wkdays.indexOf(tmp);
      if (weekday != -1) {
        return _DateHeaderFormat.formatRfc1123;
      }
      weekday = weekdays.indexOf(tmp);
      if (weekday != -1) {
        return _DateHeaderFormat.formatRfc850;
      }
    }
    throw FormatException('Invalid HTTP date $date');
  }

  void expect(String s) {
    if (date.length - index < s.length) {
      throw FormatException('Invalid HTTP date $date');
    }
    final tmp = date.substring(index, index + s.length);
    if (tmp != s) {
      throw FormatException('Invalid HTTP date $date');
    }
    index += s.length;
  }

  int expectMonth(String separator) {
    final pos = date.indexOf(separator, index);
    if (pos - index != 3) throw FormatException('Invalid HTTP date $date');
    tmp = date.substring(index, pos);
    index = pos + 1;
    final month = months.indexOf(tmp);
    if (month != -1) return month;
    throw FormatException('Invalid HTTP date $date');
  }

  int expectNum(String separator, {int? maxDigits, int? minDigits}) {
    int pos;
    if (separator.isNotEmpty) {
      pos = date.indexOf(separator, index);
    } else {
      pos = date.length;
    }
    try {
      final tmp = date.substring(index, pos);
      if (maxDigits != null && tmp.length > maxDigits) {
        throw FormatException('Expected max a $maxDigits-digits number');
      }
      if (minDigits != null && tmp.length < minDigits) {
        throw FormatException('Expected a least a $minDigits-digits number');
      }

      index = pos + separator.length;
      final value = int.parse(tmp);
      return value;
      // ignore: avoid_catching_errors
    } on RangeError {
      throw FormatException('Expected a $maxDigits-digits number');
    }
  }

  void expectEnd() {
    if (index != date.length) {
      throw FormatException('Invalid HTTP date $date');
    }
  }

  final format = expectWeekday();
  int year;
  int month;
  int day;
  int hours;
  int minutes;
  int seconds;

  switch (format) {
    case _DateHeaderFormat.formatRfc1123:
      expect(' ');
      day = expectNum(' ', minDigits: 1, maxDigits: 2);
      month = expectMonth(' ');
      year = expectNum(' ', minDigits: 4, maxDigits: 4);
      hours = expectNum(':', minDigits: 1, maxDigits: 2);
      minutes = expectNum(':', minDigits: 1, maxDigits: 2);
      seconds = expectNum(' ', minDigits: 1, maxDigits: 2);
      expect('GMT');
      break;
    case _DateHeaderFormat.formatRfc850:
      expect(' ');
      day = expectNum('-', minDigits: 1, maxDigits: 2);
      month = expectMonth('-');
      year = expectNum(' ', minDigits: 2, maxDigits: 4);
      if (year < 100) {
        year = 1900 + year;
      }
      hours = expectNum(':', minDigits: 1, maxDigits: 2);
      minutes = expectNum(':', minDigits: 1, maxDigits: 2);
      seconds = expectNum(' ', minDigits: 1, maxDigits: 2);
      expect('GMT');
      break;
    case _DateHeaderFormat.formatAsctime:
      month = expectMonth(' ');
      if (date.codeUnitAt(index) == asciiSpace) index++;
      day = expectNum(' ', minDigits: 1, maxDigits: 3);
      hours = expectNum(':', minDigits: 1, maxDigits: 2);
      minutes = expectNum(':', minDigits: 1, maxDigits: 2);
      seconds = expectNum(' ', minDigits: 1, maxDigits: 2);
      year = expectNum('', minDigits: 2, maxDigits: 4);
      if (year < 100) {
        year = 1900 + year;
      }
      break;
  }
  expectEnd();
  //ignore: avoid_redundant_argument_values
  return DateTime.utc(year, month + 1, day, hours, minutes, seconds, 0, 0);
}
