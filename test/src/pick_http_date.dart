import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

import 'pick_test.dart';

void main() {
  group('asHttpDateHeaderOrThrow', () {
    group('official dart tests', () {
      test('1', () {
        final date = DateTime.utc(1999, DateTime.june, 11, 18, 46, 53);
        expect(pick('Fri, 11 Jun 1999 18:46:53 GMT').asDateTimeOrThrow(), date);
        expect(
            pick('Friday, 11-Jun-1999 18:46:53 GMT').asDateTimeOrThrow(), date);
        expect(pick('Fri Jun 11 18:46:53 1999').asDateTimeOrThrow(), date);
      });

      test('2', () {
        final date = DateTime.utc(1970, DateTime.january);
        expect(pick('Thu, 1 Jan 1970 00:00:00 GMT').asDateTimeOrThrow(), date);
        expect(pick('Thursday, 1-Jan-1970 00:00:00 GMT').asDateTimeOrThrow(),
            date);
        expect(pick('Thu Jan  1 00:00:00 1970').asDateTimeOrThrow(), date);
      });

      test('3', () {
        final date = DateTime.utc(2012, DateTime.march, 5, 23, 59, 59);
        expect(pick('Mon, 5 Mar 2012 23:59:59 GMT').asDateTimeOrThrow(), date);
        expect(
            pick('Monday, 5-Mar-2012 23:59:59 GMT').asDateTimeOrThrow(), date);
        expect(pick('Mon Mar  5 23:59:59 2012').asDateTimeOrThrow(), date);
      });
    });

    group('RFC 1123', () {
      test('parses the example date', () {
        final date = pick('Sun, 06 Nov 1994 08:49:37 GMT').asDateTimeOrThrow();
        expect(date.day, equals(6));
        expect(date.month, equals(DateTime.november));
        expect(date.year, equals(1994));
        expect(date.hour, equals(8));
        expect(date.minute, equals(49));
        expect(date.second, equals(37));
        expect(date.timeZoneName, equals('UTC'));
      });

      test('mozilla example', () {
        // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Date
        expect(pick('Wed, 21 Oct 2015 07:28:00 GMT').asDateTimeOrThrow(),
            DateTime.utc(2015, 10, 21, 7, 28, 00));
      });

      test('be flexible on whitespace', () {
        expect(pick('Sun,06 Nov 1994 08:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));

        expect(pick('Sun, 06Nov 1994 08:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));

        expect(pick('Sun, 06 Nov1994 08:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));

        expect(pick('Sun, 06 Nov 1994 08:49:37GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));

        expect(pick(' Sun,06Nov1994 08:49:37GMT ').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));
      });

      test('require whitespace', () {
        // year and minutes need to be separated
        expect(
          () => pick('Sun, 06 Nov 199408:49:37 GMT').asDateTimeOrThrow(),
          throwsA(pickException(
              containing: ['Sun, 06 Nov 199408:49:37 GMT', 'DateTime'])),
        );
      });

      // Be flexible on input
      test('Do not require precise number lengths', () {
        // short day
        expect(pick('Sun, 6 Nov 1994 08:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));

        // short hour
        expect(pick('Sun, 06 Nov 1994 8:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));

        // short min
        expect(pick('Sun, 06 Nov 1994 08:9:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 9, 37));

        // short seconds
        expect(pick('Sun, 06 Nov 1994 08:49:7 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 7));
      });

      test('accepts days out of month range', () {
        // negative days
        expect(pick('Sun, 00 Nov 1994 08:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 10, 31, 8, 49, 37));

        // day overlap
        expect(pick('Sun, 31 Nov 1994 08:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 12, 01, 8, 49, 37));

        // day overlap
        expect(pick('Sun, 32 Aug 1994 08:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 09, 01, 8, 49, 37));

        // hours overlap
        expect(pick('Sun, 06 Nov 1994 24:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 07, 0, 49, 37));

        // minutes overlap
        expect(pick('Sun, 06 Nov 1994 08:60:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 06, 9, 00, 37));

        // seconds overlap
        expect(pick('Sun, 06 Nov 1994 08:49:60 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 06, 8, 50));
      });

      test('requires reasonable numbers', () {
        // Don't parse two digit year as 19XX
        expect(pick('Sun, 06 Nov 94 08:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(94, 11, 6, 8, 49, 37));
      });

      test('only allows short weekday names', () {
        expect(
          () => pick('Sunday, 6 Nov 1994 08:49:37 GMT').asDateTimeOrThrow(),
          throwsA(pickException(
              containing: ['Sunday, 6 Nov 1994 08:49:37 GMT', 'DateTime'])),
        );
      });

      test('only allows short month names', () {
        expect(
          () => pick('Sun, 6 November 1994 08:49:37 GMT').asDateTimeOrThrow(),
          throwsA(pickException(
              containing: ['Sun, 6 November 1994 08:49:37 GMT', 'DateTime'])),
        );
      });

      test('only allows GMT', () {
        expect(
          () => pick('Sun, 6 Nov 1994 08:49:37 PST').asDateTimeOrThrow(),
          throwsA(pickException(
              containing: ['Sun, 6 Nov 1994 08:49:37 PST', 'DateTime'])),
        );
      });

      test('ignore whitespaces when possible', () {
        expect(pick('Sun, 6 Nov 1994 08:49:37 GMT ').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));
        expect(pick('Sun,  06 Nov 1994 08:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));

        expect(pick('Sun, 06  Nov 1994 08:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));

        expect(pick('Sun, 06 Nov  1994 08:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));

        expect(pick('Sun, 06 Nov 1994  08:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));

        expect(pick('Sun, 06 Nov 1994 08:49:37  GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));
      });
    });

    group('RFC 850', () {
      test('parses the example date', () {
        final date = pick('Sunday, 06-Nov-94 08:49:37 GMT').asDateTimeOrThrow();
        expect(date.day, equals(6));
        expect(date.month, equals(DateTime.november));
        expect(date.year, equals(1994));
        expect(date.hour, equals(8));
        expect(date.minute, equals(49));
        expect(date.second, equals(37));
        expect(date.timeZoneName, equals('UTC'));
      });

      test('require whitespace between year and hour', () {
        expect(
          () => pick('Sunday, 06-Nov-9408:49:37 GMT').asDateTimeOrThrow(),
          throwsA(pickException(
              containing: ['Sunday, 06-Nov-9408:49:37 GMT', 'DateTime'])),
        );
      });

      test('be flexible on spacing', () {
        expect(pick('Sunday,  06-Nov-94 08:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));

        expect(pick('Sunday, 06-Nov-94  08:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));

        expect(pick('Sunday, 06-Nov-94 08:49:37  GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));

        expect(pick('Sunday,06-Nov-94 08:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));

        expect(pick('Sunday, 06-Nov-94 08:49:37GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));
      });

      test('Do not require precise number lengths', () {
        // short day
        expect(pick('Sunday, 6-Nov-94 08:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));

        // short hour
        expect(pick('Sunday, 06-Nov-94 8:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));

        // long year
        expect(pick('Sunday, 06-Nov-1994 08:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));
        expect(pick('Sunday, 06-Nov-2018 08:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(2018, 11, 6, 8, 49, 37));

        // short min
        expect(pick('Sunday, 06-Nov-94 08:9:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 9, 37));

        // short seconds
        expect(pick('Sunday, 06-Nov-94 08:49:7 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 7));
      });

      test('accepts invalid dates', () {
        // negative days
        expect(pick('Sunday, 00-Nov-94 08:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 10, 31, 8, 49, 37));

        // day overlap
        expect(pick('Sunday, 31-Nov-94 08:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 12, 01, 8, 49, 37));

        // day overlap
        expect(pick('Sunday, 32-Aug-94 08:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 09, 01, 8, 49, 37));

        // hours overlap
        expect(pick('Sunday, 06-Nov-94 24:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 07, 0, 49, 37));

        // minutes overlap
        expect(pick('Sunday, 06-Nov-94 08:60:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 06, 9, 00, 37));

        // seconds overlap
        expect(pick('Sunday, 06-Nov-94 08:49:60 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 06, 8, 50));
      });

      test('short weekday names are ok', () {
        expect(pick('Sun, 6-Nov-94 08:49:37 GMT').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));
      });

      test('only allows short month names', () {
        expect(
          () => pick('Sunday, 6-November-94 08:49:37 GMT').asDateTimeOrThrow(),
          throwsA(pickException(
              containing: ['Sunday, 6-November-94 08:49:37 GMT', 'DateTime'])),
        );
      });

      test('only allows GMT', () {
        expect(
          () => pick('Sunday, 6-Nov-94 08:49:37 PST').asDateTimeOrThrow(),
          throwsA(pickException(
              containing: ['Sunday, 6-Nov-94 08:49:37 PST', 'DateTime'])),
        );
      });

      test('allow trailing whitespace', () {
        expect(pick('Sunday, 6-Nov-94 08:49:37 GMT ').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));
      });
    });

    group('asctime()', () {
      test('parses the example date', () {
        final date = pick('Sun Nov  6 08:49:37 1994').asDateTimeOrThrow();
        expect(date.day, equals(6));
        expect(date.month, equals(DateTime.november));
        expect(date.year, equals(1994));
        expect(date.hour, equals(8));
        expect(date.minute, equals(49));
        expect(date.second, equals(37));
        expect(date.timeZoneName, equals('UTC'));
      });

      test('parses a date with a two-digit day', () {
        final date = pick('Sun Nov 16 08:49:37 1994').asDateTimeOrThrow();
        expect(date.day, equals(16));
        expect(date.month, equals(DateTime.november));
        expect(date.year, equals(1994));
        expect(date.hour, equals(8));
        expect(date.minute, equals(49));
        expect(date.second, equals(37));
        expect(date.timeZoneName, equals('UTC'));
      });

      test('parses a date with a single-digit day', () {
        final date = pick('Sun Nov  1 08:49:37 1994').asDateTimeOrThrow();
        expect(date.day, equals(1));
        expect(date.month, equals(DateTime.november));
        expect(date.year, equals(1994));
        expect(date.hour, equals(8));
        expect(date.minute, equals(49));
        expect(date.second, equals(37));
        expect(date.timeZoneName, equals('UTC'));
      });

      test('whitespace is required', () {
        expect(
          () => pick('SunNov  6 08:49:37 1994').asDateTimeOrThrow(),
          throwsA(pickException(
              containing: ['SunNov  6 08:49:37 1994', 'DateTime'])),
        );

        expect(
          () => pick('Sun Nov  608:49:37 1994').asDateTimeOrThrow(),
          throwsA(pickException(
              containing: ['Sun Nov  608:49:37 1994', 'DateTime'])),
        );

        expect(
          () => pick('Sun Nov  6 08:49:371994').asDateTimeOrThrow(),
          throwsA(pickException(
              containing: ['Sun Nov  6 08:49:371994', 'DateTime'])),
        );
      });

      test('be flexible on spacing', () {
        expect(pick('Sun  Nov  6 08:49:37 1994').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));

        expect(pick('Sun Nov   6 08:49:37 1994').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));

        expect(pick('Sun Nov 6 08:49:37 1994').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));

        expect(pick('Sun Nov  6  08:49:37 1994').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));

        expect(pick('Sun Nov  6 08:49:37  1994').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));

        expect(pick(' Sun Nov6 08:49:37 1994 ').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 6, 8, 49, 37));
      });

      test('accepts invalid dates', () {
        // negative days
        expect(pick('Sun Nov 0 08:49:37 1994').asDateTimeOrThrow(),
            DateTime.utc(1994, 10, 31, 8, 49, 37));

        // day overlap
        expect(pick('Sun Nov 31 08:49:37 1994').asDateTimeOrThrow(),
            DateTime.utc(1994, 12, 01, 8, 49, 37));

        // day overlap
        expect(pick('Sun Aug 32 08:49:37 1994').asDateTimeOrThrow(),
            DateTime.utc(1994, 09, 01, 8, 49, 37));

        // hours overlap
        expect(pick('Sun Nov  6 24:49:37 1994').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 07, 0, 49, 37));

        // minutes overlap
        expect(pick('Sun Nov  6 08:60:37 1994').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 06, 9, 00, 37));

        // seconds overlap
        expect(pick('Sun Nov  6 08:49:60 1994').asDateTimeOrThrow(),
            DateTime.utc(1994, 11, 06, 8, 50));
      });

      test('only allows short weekday names', () {
        expect(
          () => pick('Sunday Nov 0 08:49:37 1994').asDateTimeOrThrow(),
          throwsA(pickException(
              containing: ['Sunday Nov 0 08:49:37 1994', 'DateTime'])),
        );
      });

      test('only allows short month names', () {
        expect(
          () => pick('Sun November 0 08:49:37 1994').asDateTimeOrThrow(),
          throwsA(pickException(
              containing: ['Sun November 0 08:49:37 1994', 'DateTime'])),
        );
      });

      test('disallows trailing whitespace', () {
        expect(
          () => pick('Sun November 0 08:49:37 1994 ').asDateTimeOrThrow(),
          throwsA(pickException(
              containing: ['Sun November 0 08:49:37 1994 ', 'DateTime'])),
        );
      });
    });
  });
}
