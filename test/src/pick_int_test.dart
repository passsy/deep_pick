import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

import 'pick_test.dart';

void main() {
  group('pick().asInt*', () {
    group('asIntOrThrow', () {
      test('parse Int', () {
        expect(pick(1).asIntOrThrow(), 1);
        expect(pick(35).asIntOrThrow(), 35);
      });

      test('round double to int', () {
        expect(pick(1.234).asIntOrThrow(roundDouble: true), 1);
        expect(pick(12.945).asIntOrThrow(roundDouble: true), 13);
      });

      test('truncate double to int', () {
        expect(pick(1.234).asIntOrThrow(truncateDouble: true), 1);
        expect(pick(12.945).asIntOrThrow(truncateDouble: true), 12);
      });

      test('parse int String', () {
        expect(pick('1').asIntOrThrow(), 1);
        expect(pick('123').asIntOrThrow(), 123);
      });

      test('round and truncate true at the same time throws', () {
        expect(
          () => pick(123).asIntOrThrow(roundDouble: true, truncateDouble: true),
          throwsA(
            pickException(
              containing: [
                '[roundDouble] and [truncateDouble] can not be true at the same time'
              ],
            ),
          ),
        );
      });

      test('null throws', () {
        expect(
          () => nullPick().asIntOrThrow(),
          throwsA(
            pickException(
              containing: [
                'Expected a non-null value but location "unknownKey" in pick(json, "unknownKey" (absent)) is absent. Use asIntOrNull() when the value may be null/absent at some point (int?).'
              ],
            ),
          ),
        );
      });

      test('wrong type throws', () {
        expect(
          () => pick(Object()).asIntOrThrow(),
          throwsA(
            pickException(
              containing: [
                'Type Object of picked value "Instance of \'Object\'" using pick(<root>) can not be parsed as int'
              ],
            ),
          ),
        );

        expect(
          () => pick('Bubblegum').asIntOrThrow(),
          throwsA(pickException(containing: ['String', 'Bubblegum', 'int'])),
        );
      });
    });

    group('asIntOrNull', () {
      test('parse String', () {
        expect(pick('2012').asIntOrNull(), 2012);
      });

      test('null returns null', () {
        expect(nullPick().asIntOrNull(), isNull);
      });

      test('wrong type returns null', () {
        expect(pick(Object()).asIntOrNull(), isNull);
      });
    });
  });

  group('pick().required().asInt*', () {
    group('asIntOrThrow', () {
      test('parse Int', () {
        expect(pick(1).required().asIntOrThrow(), 1);
        expect(pick(35).required().asIntOrThrow(), 35);
      });

      test('parse int String', () {
        expect(pick('1').required().asIntOrThrow(), 1);
        expect(pick('123').required().asIntOrThrow(), 123);
      });

      test('null throws', () {
        expect(
          () => nullPick().required().asIntOrThrow(),
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
          () => pick(Object()).required().asIntOrThrow(),
          throwsA(
            pickException(
              containing: [
                'Type Object of picked value "Instance of \'Object\'" using pick(<root>) can not be parsed as int'
              ],
            ),
          ),
        );

        expect(
          () => pick('Bubblegum').required().asIntOrThrow(),
          throwsA(pickException(containing: ['String', 'Bubblegum', 'int'])),
        );
      });
    });

    group('asIntOrNull', () {
      test('parse String', () {
        expect(pick('2012').required().asIntOrNull(), 2012);
      });

      test('wrong type returns null', () {
        expect(pick(Object()).required().asIntOrNull(), isNull);
      });
    });
  });
}
