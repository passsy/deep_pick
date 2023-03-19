import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

import 'pick_test.dart';

void main() {
  group('pick().asDateTime*', () {
    group('asDateTimeOrThrow', () {
      test('parse String', () {
        expect(
          pick('2012-02-27 13:27:00').asDateTimeOrThrow(),
          DateTime(2012, 2, 27, 13, 27),
        );
        expect(
          pick('2012-02-27 13:27:00.123456z').asDateTimeOrThrow(),
          DateTime.utc(2012, 2, 27, 13, 27, 0, 123, 456),
        );
      });

      test('parse DateTime', () {
        final time = DateTime.utc(2012, 2, 27, 13, 27, 0, 123, 456);
        expect(pick(time.toString()).asDateTimeOrThrow(), time);
        expect(pick(time).asDateTimeOrThrow(), time);
      });

      test('null throws', () {
        expect(
          () => nullPick().asDateTimeOrThrow(),
          throwsA(
            pickException(
              containing: [
                'Expected a non-null value but location "unknownKey" in pick(json, "unknownKey" (absent)) is absent. Use asDateTimeOrNull() when the value may be null/absent at some point (DateTime?).'
              ],
            ),
          ),
        );
      });

      test('wrong type throws', () {
        expect(
          () => pick(Object()).asDateTimeOrThrow(),
          throwsA(
            pickException(
              containing: [
                'Type Object of picked value "Instance of \'Object\'" using pick(<root>) can not be parsed as DateTime'
              ],
            ),
          ),
        );
        expect(
          () => pick('Bubblegum').asDateTimeOrThrow(),
          throwsA(
            pickException(containing: ['String', 'Bubblegum', 'DateTime']),
          ),
        );
      });
    });

    group('asDateTimeOrNull', () {
      test('parse String', () {
        expect(
          pick('2012-02-27 13:27:00').asDateTimeOrNull(),
          DateTime(2012, 2, 27, 13, 27),
        );
      });

      test('null returns null', () {
        expect(nullPick().asDateTimeOrNull(), isNull);
      });

      test('wrong type returns null', () {
        expect(pick(Object()).asDateTimeOrNull(), isNull);
      });
    });
  });

  group('pick().required().asDateTime*', () {
    group('asDateTimeOrThrow', () {
      test('parse String', () {
        expect(
          pick('2012-02-27 13:27:00').required().asDateTimeOrThrow(),
          DateTime(2012, 2, 27, 13, 27),
        );
        expect(
          pick('2012-02-27 13:27:00.123456z').required().asDateTimeOrThrow(),
          DateTime.utc(2012, 2, 27, 13, 27, 0, 123, 456),
        );
      });

      test('parse DateTime', () {
        final time = DateTime.utc(2012, 2, 27, 13, 27, 0, 123, 456);
        expect(pick(time.toString()).required().asDateTimeOrThrow(), time);
        expect(pick(time).required().asDateTimeOrThrow(), time);
      });

      test('null throws', () {
        expect(
          () => nullPick().required().asDateTimeOrThrow(),
          throwsA(
            pickException(
              containing: [
                'Expected a non-null value but location "unknownKey" in pick(json, "unknownKey" (absent)) is absent.'
              ],
            ),
          ),
        );
      });

      test('wrong type throws', () {
        expect(
          () => pick(Object()).required().asDateTimeOrThrow(),
          throwsA(
            pickException(
              containing: [
                'Type Object of picked value "Instance of \'Object\'" using pick(<root>) can not be parsed as DateTime'
              ],
            ),
          ),
        );
        expect(
          () => pick('Bubblegum').required().asDateTimeOrThrow(),
          throwsA(
            pickException(containing: ['String', 'Bubblegum', 'DateTime']),
          ),
        );
      });
    });

    group('asDateTimeOrNull', () {
      test('parse String', () {
        expect(
          pick('2012-02-27 13:27:00').required().asDateTimeOrNull(),
          DateTime(2012, 2, 27, 13, 27),
        );
      });

      test('wrong type returns null', () {
        expect(pick(Object()).required().asDateTimeOrNull(), isNull);
      });
    });

    group('ISO 8601', () {
      group('official dart tests', () {
        test('1', () {
          final date = DateTime.utc(1999, DateTime.june, 11, 18, 46, 53);
          expect(
            pick('Fri, 11 Jun 1999 18:46:53 GMT').asDateTimeOrThrow(),
            date,
          );
          expect(
            pick('Friday, 11-Jun-1999 18:46:53 GMT').asDateTimeOrThrow(),
            date,
          );
          expect(pick('Fri Jun 11 18:46:53 1999').asDateTimeOrThrow(), date);
        });

        test('2', () {
          // ignore: avoid_redundant_argument_values
          final date = DateTime.utc(1970, DateTime.january);
          expect(
            pick('Thu, 1 Jan 1970 00:00:00 GMT').asDateTimeOrThrow(),
            date,
          );
          expect(
            pick('Thursday, 1-Jan-1970 00:00:00 GMT').asDateTimeOrThrow(),
            date,
          );
          expect(pick('Thu Jan  1 00:00:00 1970').asDateTimeOrThrow(), date);
        });

        test('3', () {
          final date = DateTime.utc(2012, DateTime.march, 5, 23, 59, 59);
          expect(
            pick('Mon, 5 Mar 2012 23:59:59 GMT').asDateTimeOrThrow(),
            date,
          );
          expect(
            pick('Monday, 5-Mar-2012 23:59:59 GMT').asDateTimeOrThrow(),
            date,
          );
          expect(pick('Mon Mar  5 23:59:59 2012').asDateTimeOrThrow(), date);
        });
      });

      test('parse DateTime with timezone +0230', () {
        const input = '2023-01-09T12:31:54+0230';
        final time = DateTime.utc(2023, 01, 09, 10, 01, 54);
        expect(pick(input).asDateTimeOrThrow(), time);
      });

      test('parse DateTime with timezone EST', () {
        const input = '2023-01-09T12:31:54EST';
        final time = DateTime.utc(2023, 01, 09, 17, 31, 54);
        expect(pick(input).asDateTimeOrThrow(), time);
      });

      test('allow starting and trailing whitespace', () {
        expect(
          pick(' 2023-01-09T12:31:54EST ').asDateTimeOrThrow(),
          DateTime.utc(2023, 01, 09, 17, 31, 54),
        );

        expect(
          pick(' 2023-01-09T12:31:54+0230 ').asDateTimeOrThrow(),
          DateTime.utc(2023, 01, 09, 10, 01, 54),
        );

        expect(
          pick('2023-01-09T12:31:54+0230 ').asDateTimeOrThrow(),
          DateTime.utc(2023, 01, 09, 10, 01, 54),
        );

        expect(
          pick(' 2023-01-09T12:31:54+0230').asDateTimeOrThrow(),
          DateTime.utc(2023, 01, 09, 10, 01, 54),
        );
      });

      test('parse DateTime with timezone PDT', () {
        const input = '20230109T123154PDT';
        final time = DateTime.utc(2023, 01, 09, 20, 31, 54);
        expect(pick(input).asDateTimeOrThrow(), time);
      });

      group('explicit format uses only one parser', () {
        test(
            'asDateTimeOrNull: ISO-8601 String ca not be parsed by ansi c asctime',
            () {
          const iso8601 = '2005-08-15T15:52:01+0000';
          final value = pick(iso8601)
              .asDateTimeOrNull(format: PickDateFormat.ANSI_C_asctime);
          expect(value, isNull);
        });
        test(
            'asDateTimeOrThrow: ISO-8601 String can not be parsed by ansi c asctime',
            () {
          const iso8601 = '2005-08-15T15:52:01+0000';
          expect(
            () => pick(iso8601)
                .asDateTimeOrThrow(format: PickDateFormat.ANSI_C_asctime),
            throwsA(
              pickException(
                containing: ['2005-08-15T15:52:01+0000', 'DateTime'],
              ),
            ),
          );
        });
      });

      group('RFC 3339', () {
        test('parses the example date', () {
          final date = pick('2021-11-01T11:53:15+00:00')
              .asDateTimeOrThrow(format: PickDateFormat.ISO_8601);
          expect(date.day, equals(1));
          expect(date.month, equals(DateTime.november));
          expect(date.year, equals(2021));
          expect(date.hour, equals(11));
          expect(date.minute, equals(53));
          expect(date.second, equals(15));
          expect(date.timeZoneName, equals('UTC'));
        });

        // examples from https://datatracker.ietf.org/doc/html/rfc3339#section-5.8
        test('rfc339 examples 1', () {
          final date = pick('1985-04-12T23:20:50.52Z').asDateTimeOrThrow();
          expect(date.day, equals(12));
          expect(date.month, equals(DateTime.april));
          expect(date.year, equals(1985));
          expect(date.hour, equals(23));
          expect(date.minute, equals(20));
          expect(date.second, equals(50));
          expect(date.millisecond, equals(520));
          expect(date.timeZoneName, equals('UTC'));
        });
        test('rfc339 examples 2 - time zone', () {
          final date = pick('1996-12-19T16:39:57-08:00').asDateTimeOrThrow();
          expect(date.day, equals(20));
          expect(date.month, equals(DateTime.december));
          expect(date.year, equals(1996));
          expect(date.hour, equals(0));
          expect(date.minute, equals(39));
          expect(date.second, equals(57));
          expect(date.millisecond, equals(0));
          expect(date.timeZoneName, equals('UTC'));
        });
        test('rfc339 examples 3 - leap second', () {
          final date = pick('1990-12-31T23:59:60Z').asDateTimeOrThrow();
          expect(date.day, equals(1));
          expect(date.month, equals(DateTime.january));
          expect(date.year, equals(1991));
          expect(date.hour, equals(0));
          expect(date.minute, equals(0));
          expect(date.second, equals(0));
          expect(date.millisecond, equals(0));
          expect(date.timeZoneName, equals('UTC'));

          // example 4
          // same leap second, different time zone
          final date2 = pick('1990-12-31T23:59:60Z').asDateTimeOrThrow();
          expect(date2, date);
        });
      });
    });

    group('RFC 1123', () {
      test('parses the example date', () {
        final date = pick('Sun, 06 Nov 1994 08:49:37 GMT')
            .asDateTimeOrThrow(format: PickDateFormat.RFC_1123);
        expect(date.day, equals(6));
        expect(date.month, equals(DateTime.november));
        expect(date.year, equals(1994));
        expect(date.hour, equals(8));
        expect(date.minute, equals(49));
        expect(date.second, equals(37));
        expect(date.timeZoneName, equals('UTC'));
      });

      test('parse DateTime with timezone +0000', () {
        const input = 'Mon, 21 Nov 2021 11:53:15 +0000';
        final time = DateTime.utc(2021, 11, 21, 11, 53, 15);
        expect(pick(input).asDateTimeOrThrow(), time);
      });

      test('parse DateTime with timezone EST', () {
        const input = 'Mon, 11 Nov 24 11:58:15 EST';
        final time = DateTime.utc(2024, 11, 11, 16, 58, 15);
        expect(pick(input).asDateTimeOrThrow(), time);
      });

      test('parse DateTime with timezone PDT', () {
        const input = 'Mon, 01 Nov 99 11:53:11 PDT';
        final time = DateTime.utc(1999, 11, 01, 19, 53, 11);
        expect(pick(input).asDateTimeOrThrow(), time);
      });

      test('parse DateTime with timezone +0000', () {
        const input = 'Mon, 01 Jan 20 11:53:01 +0000';
        final time = DateTime.utc(2020, 01, 01, 11, 53, 01);
        expect(pick(input).asDateTimeOrThrow(), time);
      });

      test('parse DateTime with timezone +0730', () {
        const input = 'Mon, 01 Nov 21 11:53:15 +0730';
        final time = DateTime.utc(2021, 11, 01, 04, 23, 15);
        expect(pick(input).asDateTimeOrThrow(), time);
      });

      test('mozilla example', () {
        // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Date
        expect(
          pick('Wed, 21 Oct 2015 07:28:00 GMT').asDateTimeOrThrow(),
          DateTime.utc(2015, 10, 21, 7, 28),
        );
      });

      test('be flexible on whitespace', () {
        expect(
          pick('Sun,06 Nov 1994 08:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );

        expect(
          pick('Sun, 06Nov 1994 08:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );

        expect(
          pick('Sun, 06 Nov1994 08:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );

        expect(
          pick('Sun, 06 Nov 1994 08:49:37GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );

        expect(
          pick(' Sun,06Nov1994 08:49:37GMT ').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );
      });

      test('require whitespace', () {
        // year and minutes need to be separated
        expect(
          () => pick('Sun, 06 Nov 199408:49:37 GMT').asDateTimeOrThrow(),
          throwsA(
            pickException(
              containing: ['Sun, 06 Nov 199408:49:37 GMT', 'DateTime'],
            ),
          ),
        );
      });

      // Be flexible on input
      test('Do not require precise number lengths', () {
        // short day
        expect(
          pick('Sun, 6 Nov 1994 08:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );

        // short hour
        expect(
          pick('Sun, 06 Nov 1994 8:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );

        // short min
        expect(
          pick('Sun, 06 Nov 1994 08:9:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 9, 37),
        );

        // short seconds
        expect(
          pick('Sun, 06 Nov 1994 08:49:7 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 7),
        );
      });

      test('accepts days out of month range', () {
        // negative days
        expect(
          pick('Sun, 00 Nov 1994 08:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 10, 31, 8, 49, 37),
        );

        // day overlap
        expect(
          pick('Sun, 31 Nov 1994 08:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 12, 01, 8, 49, 37),
        );

        // day overlap
        expect(
          pick('Sun, 32 Aug 1994 08:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 09, 01, 8, 49, 37),
        );

        // hours overlap
        expect(
          pick('Sun, 06 Nov 1994 24:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 07, 0, 49, 37),
        );

        // minutes overlap
        expect(
          pick('Sun, 06 Nov 1994 08:60:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 06, 9, 00, 37),
        );

        // seconds overlap
        expect(
          pick('Sun, 06 Nov 1994 08:49:60 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 06, 8, 50),
        );
      });

      test('only allows short weekday names', () {
        expect(
          () => pick('Sunday, 6 Nov 1994 08:49:37 GMT').asDateTimeOrThrow(),
          throwsA(
            pickException(
              containing: ['Sunday, 6 Nov 1994 08:49:37 GMT', 'DateTime'],
            ),
          ),
        );
      });

      test('only allows short month names', () {
        expect(
          () => pick('Sun, 6 November 1994 08:49:37 GMT').asDateTimeOrThrow(),
          throwsA(
            pickException(
              containing: ['Sun, 6 November 1994 08:49:37 GMT', 'DateTime'],
            ),
          ),
        );
      });

      test('ignore whitespaces when possible', () {
        expect(
          pick('Sun, 6 Nov 1994 08:49:37 GMT ').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );

        expect(
          pick('Sun,  06 Nov 1994 08:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );

        expect(
          pick('Sun, 06  Nov 1994 08:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );

        expect(
          pick('Sun, 06 Nov  1994 08:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );

        expect(
          pick('Sun, 06 Nov 1994  08:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );

        expect(
          pick('Sun, 06 Nov 1994 08:49:37  GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );
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

      test('parse DateTime with timezone +0000', () {
        const input = 'Monday, 21-Nov-21 11:53:15 +0000';
        final time = DateTime.utc(2021, 11, 21, 11, 53, 15);
        expect(pick(input).asDateTimeOrThrow(), time);
      });

      test('parse DateTime with timezone EST', () {
        const input = 'Monday, 11-Nov-24 11:58:15 EST';
        final time = DateTime.utc(2024, 11, 11, 16, 58, 15);
        expect(pick(input).asDateTimeOrThrow(), time);
      });

      test('parse DateTime with timezone PDT', () {
        const input = 'Monday, 01-Nov-99 11:53:11 PDT';
        final time = DateTime.utc(1999, 11, 01, 19, 53, 11);
        expect(pick(input).asDateTimeOrThrow(), time);
      });

      test('parse DateTime with timezone +0000', () {
        const input = 'Monday, 01-Jan-20 11:53:01 +0000';
        final time = DateTime.utc(2020, 01, 01, 11, 53, 01);
        expect(pick(input).asDateTimeOrThrow(), time);
      });

      test('parse DateTime with timezone +0730', () {
        const input = 'Monday, 01-Nov-21 11:53:15 +0730';
        final time = DateTime.utc(2021, 11, 01, 04, 23, 15);
        expect(pick(input).asDateTimeOrThrow(), time);
      });

      test('require whitespace between year and hour', () {
        expect(
          () => pick('Sunday, 06-Nov-9408:49:37 GMT').asDateTimeOrThrow(),
          throwsA(
            pickException(
              containing: ['Sunday, 06-Nov-9408:49:37 GMT', 'DateTime'],
            ),
          ),
        );
      });

      test('be flexible on spacing', () {
        expect(
          pick('Sunday,  06-Nov-94 08:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );

        expect(
          pick('Sunday, 06-Nov-94  08:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );

        expect(
          pick('Sunday, 06-Nov-94 08:49:37  GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );

        expect(
          pick('Sunday,06-Nov-94 08:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );

        expect(
          pick('Sunday, 06-Nov-94 08:49:37GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );
      });

      test('Do not require precise number lengths', () {
        // short day
        expect(
          pick('Sunday, 6-Nov-94 08:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );

        // short hour
        expect(
          pick('Sunday, 06-Nov-94 8:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );

        // long year
        expect(
          pick('Sunday, 06-Nov-1994 08:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );
        expect(
          pick('Sunday, 06-Nov-2018 08:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(2018, 11, 6, 8, 49, 37),
        );

        // short min
        expect(
          pick('Sunday, 06-Nov-94 08:9:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 9, 37),
        );

        // short seconds
        expect(
          pick('Sunday, 06-Nov-94 08:49:7 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 7),
        );
      });

      test('accepts invalid dates', () {
        // negative days
        expect(
          pick('Sunday, 00-Nov-94 08:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 10, 31, 8, 49, 37),
        );

        // day overlap
        expect(
          pick('Sunday, 31-Nov-94 08:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 12, 01, 8, 49, 37),
        );

        // day overlap
        expect(
          pick('Sunday, 32-Aug-94 08:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 09, 01, 8, 49, 37),
        );

        // hours overlap
        expect(
          pick('Sunday, 06-Nov-94 24:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 07, 0, 49, 37),
        );

        // minutes overlap
        expect(
          pick('Sunday, 06-Nov-94 08:60:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 06, 9, 00, 37),
        );

        // seconds overlap
        expect(
          pick('Sunday, 06-Nov-94 08:49:60 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 06, 8, 50),
        );
      });

      test('throws for unsupported timezones', () {
        expect(
          () => pick('2023-01-09T12:31:54ABC').asDateTimeOrThrow(),
          throwsA(
            pickException(
              containing: [
                'Type String of picked value "2023-01-09T12:31:54ABC"',
                'Unknown time zone abbrevation ABC',
              ],
            ),
          ),
        );

        expect(
          () => pick('Mon, 11 Nov 24 11:58:15 ESTX').asDateTimeOrThrow(),
          throwsA(
            pickException(
              containing: [
                'Type String of picked value "Mon, 11 Nov 24 11:58:15 ESTX"',
                'Unknown time zone abbrevation ESTX'
              ],
            ),
          ),
        );
      });

      test('short weekday names are ok', () {
        expect(
          pick('Sun, 6-Nov-94 08:49:37 GMT').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );
      });

      test('only allows short month names', () {
        expect(
          () => pick('Sunday, 6-November-94 08:49:37 GMT').asDateTimeOrThrow(),
          throwsA(
            pickException(
              containing: ['Sunday, 6-November-94 08:49:37 GMT', 'DateTime'],
            ),
          ),
        );
      });

      test('allow trailing whitespace', () {
        expect(
          pick('Sunday, 6-Nov-94 08:49:37 GMT ').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );
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
          throwsA(
            pickException(containing: ['SunNov  6 08:49:37 1994', 'DateTime']),
          ),
        );

        expect(
          () => pick('Sun Nov  608:49:37 1994').asDateTimeOrThrow(),
          throwsA(
            pickException(containing: ['Sun Nov  608:49:37 1994', 'DateTime']),
          ),
        );

        expect(
          () => pick('Sun Nov  6 08:49:371994').asDateTimeOrThrow(),
          throwsA(
            pickException(containing: ['Sun Nov  6 08:49:371994', 'DateTime']),
          ),
        );
      });

      test('be flexible on spacing', () {
        expect(
          pick('Sun  Nov  6 08:49:37 1994').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );

        expect(
          pick('Sun Nov   6 08:49:37 1994').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );

        expect(
          pick('Sun Nov 6 08:49:37 1994').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );

        expect(
          pick('Sun Nov  6  08:49:37 1994').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );

        expect(
          pick('Sun Nov  6 08:49:37  1994').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );

        expect(
          pick(' Sun Nov6 08:49:37 1994 ').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 6, 8, 49, 37),
        );
      });

      test('accepts invalid dates', () {
        // negative days
        expect(
          pick('Sun Nov 0 08:49:37 1994').asDateTimeOrThrow(),
          DateTime.utc(1994, 10, 31, 8, 49, 37),
        );

        // day overlap
        expect(
          pick('Sun Nov 31 08:49:37 1994').asDateTimeOrThrow(),
          DateTime.utc(1994, 12, 01, 8, 49, 37),
        );

        // day overlap
        expect(
          pick('Sun Aug 32 08:49:37 1994').asDateTimeOrThrow(),
          DateTime.utc(1994, 09, 01, 8, 49, 37),
        );

        // hours overlap
        expect(
          pick('Sun Nov  6 24:49:37 1994').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 07, 0, 49, 37),
        );

        // minutes overlap
        expect(
          pick('Sun Nov  6 08:60:37 1994').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 06, 9, 00, 37),
        );

        // seconds overlap
        expect(
          pick('Sun Nov  6 08:49:60 1994').asDateTimeOrThrow(),
          DateTime.utc(1994, 11, 06, 8, 50),
        );
      });

      test('only allows short weekday names', () {
        expect(
          () => pick('Sunday Nov 0 08:49:37 1994').asDateTimeOrThrow(),
          throwsA(
            pickException(
              containing: ['Sunday Nov 0 08:49:37 1994', 'DateTime'],
            ),
          ),
        );
      });

      test('only allows short month names', () {
        expect(
          () => pick('Sun November 0 08:49:37 1994').asDateTimeOrThrow(),
          throwsA(
            pickException(
              containing: ['Sun November 0 08:49:37 1994', 'DateTime'],
            ),
          ),
        );
      });

      test('disallows trailing whitespace', () {
        expect(
          () => pick('Sun November 0 08:49:37 1994 ').asDateTimeOrThrow(),
          throwsA(
            pickException(
              containing: ['Sun November 0 08:49:37 1994 ', 'DateTime'],
            ),
          ),
        );
      });
    });

    group('RFC 1026', () {
      test('parse DateTime with timezone +0100', () {
        //RFC 103 Wdy, DD Mon YY HH:MM:SS TIMEZONE
        const input = 'Tue, 09 Jan 23 22:14:02 +0100';
        expect(
          pick(input).asDateTimeOrThrow(format: PickDateFormat.RFC_1123),
          DateTime.utc(2023, 01, 09, 21, 14, 02),
        );
      });
    });

    group('RFC 2822', () {
      test('parse date from RFC', () {
        const input = 'Fri, 21 Nov 1997 09:55:06 -0600';
        expect(
          pick(input).asDateTimeOrThrow(format: PickDateFormat.RFC_1123),
          DateTime.utc(1997, 11, 21, 15, 55, 06),
        );
      });
    });
  });
}
