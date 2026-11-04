import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

void main() {
  group('Atom dates (RFC 4287)', () {
    final examples = {
      '2003-12-13T18:30:02Z': DateTime.utc(2003, 12, 13, 18, 30, 2),
      '2003-12-13T18:30:02+01:00': DateTime.utc(2003, 12, 13, 17, 30, 2),
      '2003-12-13T18:30:02-05:30': DateTime.utc(2003, 12, 14, 0, 0, 2),
      '2003-12-13T18:30:02.123456+00:00':
          DateTime.utc(2003, 12, 13, 18, 30, 2, 123, 456),
    };
    for (final entry in examples.entries) {
      test(entry.key, () {
        final selected = pick(entry.key);
        for (final format in [null, PickDateFormat.ISO_8601]) {
          expect(selected.asDateTimeOrThrow(format: format), entry.value);
          expect(selected.asDateTimeOrNull(format: format), entry.value);
          expect(selected.required().asDateTimeOrThrow(format: format),
              entry.value);
          expect(selected.asDateTimeOrThrow(format: format).isUtc, isTrue);
        }
      });
    }
    test('an unrelated explicit parser does not accept Atom dates', () {
      expect(
        pick('2003-12-13T18:30:02+01:00')
            .asDateTimeOrNull(format: PickDateFormat.RFC_1123),
        isNull,
      );
    });
  });
}
