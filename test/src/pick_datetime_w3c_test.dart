import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

void main() {
  group('W3C date profile', () {
    // All six granularities from https://www.w3.org/TR/NOTE-datetime.
    final examples = {
      '1997': DateTime(1997),
      '1997-07': DateTime(1997, 7),
      '1997-07-16': DateTime(1997, 7, 16),
      '1997-07-16T19:20+01:00': DateTime.utc(1997, 7, 16, 18, 20),
      '1997-07-16T19:20:30+01:00': DateTime.utc(1997, 7, 16, 18, 20, 30),
      '1997-07-16T19:20:30.45+01:00':
          DateTime.utc(1997, 7, 16, 18, 20, 30, 450),
      '1997-07-16T19:20:30.123456Z':
          DateTime.utc(1997, 7, 16, 19, 20, 30, 123, 456),
      '1997-07-16T19:20-05:30': DateTime.utc(1997, 7, 17, 0, 50),
      '0000': DateTime(0),
      ' 1997-12 ': DateTime(1997, 12),
    };
    for (final entry in examples.entries) {
      test(entry.key, () {
        for (final format in [null, PickDateFormat.ISO_8601]) {
          final selected = pick(entry.key);
          final actual = selected.asDateTimeOrThrow(format: format);
          expect(actual, entry.value);
          expect(actual.isUtc, entry.value.isUtc);
          expect(selected.asDateTimeOrNull(format: format), entry.value);
          expect(selected.required().asDateTimeOrThrow(format: format),
              entry.value);
        }
      });
    }
    for (final input in ['1997-00', '1997-13', '1997-1', '199', '1997x']) {
      test('reject invalid reduced date $input', () {
        expect(pick(input).asDateTimeOrNull(), isNull);
        expect(() => pick(input).asDateTimeOrThrow(),
            throwsA(isA<PickException>()));
      });
    }
    test('an unrelated explicit format rejects reduced dates', () {
      expect(pick('1997').asDateTimeOrNull(format: PickDateFormat.RFC_1123),
          isNull);
    });
  });
}
