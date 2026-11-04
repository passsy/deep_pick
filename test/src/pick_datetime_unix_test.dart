import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

void main() {
  const format = PickDateFormat.UNIX_SECONDS;
  group('Unix seconds', () {
    final examples = <num, DateTime>{
      1000000000: DateTime.utc(2001, 9, 9, 1, 46, 40),
      0: DateTime.utc(1970),
      -1: DateTime.utc(1969, 12, 31, 23, 59, 59),
      1.25: DateTime.utc(1970, 1, 1, 0, 0, 1, 250),
      -1.25: DateTime.utc(1969, 12, 31, 23, 59, 58, 750),
      0.000001: DateTime.utc(1970, 1, 1, 0, 0, 0, 0, 1),
      0.0000006: DateTime.utc(1970, 1, 1, 0, 0, 0, 0, 1),
      -0.0000006: DateTime.utc(1970).subtract(const Duration(microseconds: 1)),
      8640000000000:
          DateTime.fromMillisecondsSinceEpoch(8640000000000000, isUtc: true),
      -8640000000000:
          DateTime.fromMillisecondsSinceEpoch(-8640000000000000, isUtc: true),
    };
    for (final entry in examples.entries) {
      test('parse ${entry.key}', () {
        final selected = pick({'time': entry.key}, 'time');
        final actual = selected.asDateTimeOrThrow(format: format);
        expect(actual, entry.value);
        expect(actual.isUtc, isTrue);
        expect(selected.asDateTimeOrNull(format: format), entry.value);
        expect(
            selected.required().asDateTimeOrThrow(format: format), entry.value);
        expect(
            selected.required().asDateTimeOrNull(format: format), entry.value);
      });
    }
    for (final input in <Object?>[
      null,
      '1000000000',
      '2001-09-09T01:46:40Z',
      true,
      <int>[],
      double.nan,
      double.infinity,
      double.negativeInfinity,
      8640000000001,
      -8640000000001,
      9223372036854775807,
      1e100,
    ]) {
      test('reject $input', () {
        final selected = pick({'time': input}, 'time');
        expect(selected.asDateTimeOrNull(format: format), isNull);
        expect(() => selected.asDateTimeOrThrow(format: format),
            throwsA(isA<PickException>()));
      });
    }
    test('absent value follows the nullable contract', () {
      final selected = pick(<String, Object>{}, 'time');
      expect(selected.asDateTimeOrNull(format: format), isNull);
      expect(() => selected.asDateTimeOrThrow(format: format),
          throwsA(isA<PickException>()));
    });
    test('numeric input requires explicit units', () {
      expect(pick(1000000000).asDateTimeOrNull(), isNull);
      expect(() => pick(1000000000).asDateTimeOrThrow(),
          throwsA(isA<PickException>()));
      expect(pick(1000000000).asDateTimeOrNull(format: PickDateFormat.ISO_8601),
          isNull);
    });
    test('DateTime values remain unchanged', () {
      final date = DateTime(2001, 9, 9);
      expect(pick(date).asDateTimeOrThrow(format: format), same(date));
    });
    test('invalid timestamps retain path and redaction', () {
      expect(
        () => pick({'time': 'PRIVATE'})
            .redactValues()('time')
            .asDateTimeOrThrow(format: format),
        throwsA(isA<PickException>()
            .having((e) => e.toString(), 'path', contains('time'))
            .having((e) => e.toString(), 'format', contains('$format'))
            .having(
                (e) => e.toString(), 'redaction', isNot(contains('PRIVATE')))),
      );
    });
  });
}
