import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

import 'pick_test.dart';

void main() {
  group('pick().asDateTime*', () {
    group('asDateTimeOrThrow', () {
      test('parse String', () {
        expect(pick('2012-02-27 13:27:00').asDateTimeOrThrow(),
            DateTime(2012, 2, 27, 13, 27));
        expect(pick('2012-02-27 13:27:00.123456z').asDateTimeOrThrow(),
            DateTime.utc(2012, 2, 27, 13, 27, 0, 123, 456));
      });

      test('parse DateTime', () {
        final time = DateTime.utc(2012, 2, 27, 13, 27, 0, 123, 456);
        expect(pick(time.toString()).asDateTimeOrThrow(), time);
        expect(pick(time).asDateTimeOrThrow(), time);
      });

      test('null throws', () {
        expect(
          () => nullPick().asDateTimeOrThrow(),
          throwsA(pickException(containing: [
            'Expected a non-null value but location "unknownKey" in pick(json, "unknownKey" (absent)) is absent. Use asDateTimeOrNull() when the value may be null/absent at some point (DateTime?).'
          ])),
        );
      });

      test('wrong type throws', () {
        expect(
          () => pick(Object()).asDateTimeOrThrow(),
          throwsA(pickException(containing: [
            'Type Object of picked value "Instance of \'Object\'" using pick(<root>) can not be parsed as DateTime'
          ])),
        );
        expect(
          () => pick('Bubblegum').asDateTimeOrThrow(),
          throwsA(
              pickException(containing: ['String', 'Bubblegum', 'DateTime'])),
        );
      });
    });

    test('deprecated asDateTime forwards to asDateTimeOrThrow', () {
      // ignore: deprecated_member_use_from_same_package
      expect(pick('2012-02-27 13:27:00').asDateTime(),
          DateTime(2012, 2, 27, 13, 27));
      expect(
        // ignore: deprecated_member_use_from_same_package
        () => nullPick().asDateTime(),
        throwsA(pickException(containing: [
          'Expected a non-null value but location "unknownKey" in pick(json, "unknownKey" (absent)) is absent. Use asDateTimeOrNull() when the value may be null/absent at some point (DateTime?).'
        ])),
      );
    });

    group('asDateTimeOrNull', () {
      test('parse String', () {
        expect(pick('2012-02-27 13:27:00').asDateTimeOrNull(),
            DateTime(2012, 2, 27, 13, 27));
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
        expect(pick('2012-02-27 13:27:00').required().asDateTimeOrThrow(),
            DateTime(2012, 2, 27, 13, 27));
        expect(
            pick('2012-02-27 13:27:00.123456z').required().asDateTimeOrThrow(),
            DateTime.utc(2012, 2, 27, 13, 27, 0, 123, 456));
      });

      test('parse DateTime', () {
        final time = DateTime.utc(2012, 2, 27, 13, 27, 0, 123, 456);
        expect(pick(time.toString()).required().asDateTimeOrThrow(), time);
        expect(pick(time).required().asDateTimeOrThrow(), time);
      });

      test('null throws', () {
        expect(
          () => nullPick().required().asDateTimeOrThrow(),
          throwsA(pickException(containing: [
            'Expected a non-null value but location "unknownKey" in pick(json, "unknownKey" (absent)) is absent.'
          ])),
        );
      });

      test('wrong type throws', () {
        expect(
          () => pick(Object()).required().asDateTimeOrThrow(),
          throwsA(pickException(containing: [
            'Type Object of picked value "Instance of \'Object\'" using pick(<root>) can not be parsed as DateTime'
          ])),
        );
        expect(
          () => pick('Bubblegum').required().asDateTimeOrThrow(),
          throwsA(
              pickException(containing: ['String', 'Bubblegum', 'DateTime'])),
        );
      });
    });

    test('deprecated asDateTime forwards to asDateTimeOrThrow', () {
      // ignore: deprecated_member_use_from_same_package
      expect(pick('2012-02-27 13:27:00').required().asDateTime(),
          DateTime(2012, 2, 27, 13, 27));
      expect(
        // ignore: deprecated_member_use_from_same_package
        () => nullPick().required().asDateTime(),
        throwsA(pickException(containing: [
          'Expected a non-null value but location "unknownKey" in pick(json, "unknownKey" (absent)) is absent.'
        ])),
      );
    });

    group('asDateTimeOrNull', () {
      test('parse String', () {
        expect(pick('2012-02-27 13:27:00').required().asDateTimeOrNull(),
            DateTime(2012, 2, 27, 13, 27));
      });

      test('wrong type returns null', () {
        expect(pick(Object()).required().asDateTimeOrNull(), isNull);
      });
    });
  });
}
