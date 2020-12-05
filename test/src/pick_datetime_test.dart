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
            'required value at location `unknownKey` is absent. Use asDateTimeOrNull() when the value may be null/absent at some point (DateTime?).'
          ])),
        );

        expect(
          () => nullPick().asDateTimeOrThrow(),
          throwsA(
              pickException(containing: ['unknownKey', 'null', 'DateTime'])),
        );
      });

      test('wrong type throws', () {
        expect(
          () => pick(Object()).asDateTimeOrThrow(),
          throwsA(pickException(containing: [
            "value Instance of 'Object' of type Object at location `<root>` can not be parsed as DateTime"
          ])),
        );
        expect(
          () => pick('Bubblegum').asDateTimeOrThrow(),
          throwsA(
              pickException(containing: ['Bubblegum', 'String', 'DateTime'])),
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
          'required value at location `unknownKey` is absent. Use asDateTimeOrNull() when the value may be null/absent at some point (DateTime?).'
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
}
