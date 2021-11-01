import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

import 'pick_test.dart';

void main() {
  group('pick().asDouble*', () {
    group('asDoubleOrThrow', () {
      test('parse double', () {
        expect(pick(1.0).asDoubleOrThrow(), 1.0);
        expect(pick(double.infinity).asDoubleOrThrow(), double.infinity);
      });

      test('parse int', () {
        expect(pick(1).asDoubleOrThrow(), 1.0);
      });
      test('parse int String', () {
        expect(pick('1').asDoubleOrThrow(), 1.0);
      });

      test('parse double String', () {
        expect(pick('1.0').asDoubleOrThrow(), 1.0);
        expect(pick('25.4634').asDoubleOrThrow(), 25.4634);
        expect(pick('12345.01').asDoubleOrThrow(), 12345.01);
      });

      test('parse german doubles', () {
        expect(pick('1,0').asDoubleOrThrow(), 1.0);
        expect(pick('12345,01').asDoubleOrThrow(), 12345.01);
      });

      test('parse double with separators', () {
        expect(pick('12,345.01').asDoubleOrThrow(), 12345.01);
        expect(pick('12 345,01').asDoubleOrThrow(), 12345.01);
        expect(pick('12.345,01').asDoubleOrThrow(), 12345.01);
      });

      test('null throws', () {
        expect(
          () => nullPick().asDoubleOrThrow(),
          throwsA(
            pickException(
              containing: [
                'Expected a non-null value but location "unknownKey" in pick(json, "unknownKey" (absent)) is absent. Use asDoubleOrNull() when the value may be null/absent at some point (double?).'
              ],
            ),
          ),
        );
      });

      test('wrong type throws', () {
        expect(
          () => pick(Object()).asDoubleOrThrow(),
          throwsA(
            pickException(
              containing: [
                'Type Object of picked value "Instance of \'Object\'" using pick(<root>) can not be parsed as double'
              ],
            ),
          ),
        );

        expect(
          () => pick('Bubblegum').asDoubleOrThrow(),
          throwsA(pickException(containing: ['String', 'Bubblegum', 'double'])),
        );
      });
    });

    group('asDoubleOrNull', () {
      test('parse String', () {
        expect(pick('2012').asDoubleOrNull(), 2012);
      });

      test('null returns null', () {
        expect(nullPick().asDoubleOrNull(), isNull);
      });

      test('wrong type returns null', () {
        expect(pick(Object()).asDoubleOrNull(), isNull);
      });
    });
  });

  group('pick().required().asDouble*', () {
    group('asDoubleOrThrow', () {
      test('parse double', () {
        expect(pick(1.0).required().asDoubleOrThrow(), 1.0);
        expect(
          pick(double.infinity).required().asDoubleOrThrow(),
          double.infinity,
        );
      });

      test('parse int', () {
        expect(pick(1).required().asDoubleOrThrow(), 1.0);
      });
      test('parse int String', () {
        expect(pick('1').required().asDoubleOrThrow(), 1.0);
      });

      test('parse double String', () {
        expect(pick('1.0').required().asDoubleOrThrow(), 1.0);
        expect(pick('25.4634').required().asDoubleOrThrow(), 25.4634);
        expect(pick('12345.01').required().asDoubleOrThrow(), 12345.01);
      });

      test('parse german doubles', () {
        expect(pick('1,0').required().asDoubleOrThrow(), 1.0);
        expect(pick('12345,01').required().asDoubleOrThrow(), 12345.01);
      });

      test('parse double with separators', () {
        expect(pick('12,345.01').required().asDoubleOrThrow(), 12345.01);
        expect(pick('12 345,01').required().asDoubleOrThrow(), 12345.01);
        expect(pick('12.345,01').required().asDoubleOrThrow(), 12345.01);
      });

      test('null throws', () {
        expect(
          () => nullPick().required().asDoubleOrThrow(),
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
          () => pick(Object()).required().asDoubleOrThrow(),
          throwsA(
            pickException(
              containing: [
                'Type Object of picked value "Instance of \'Object\'" using pick(<root>) can not be parsed as double'
              ],
            ),
          ),
        );

        expect(
          () => pick('Bubblegum').required().asDoubleOrThrow(),
          throwsA(pickException(containing: ['String', 'Bubblegum', 'double'])),
        );
      });
    });

    group('asDoubleOrNull', () {
      test('parse String', () {
        expect(pick('2012').required().asDoubleOrNull(), 2012);
      });

      test('wrong type returns null', () {
        expect(pick(Object()).required().asDoubleOrNull(), isNull);
      });
    });
  });
}
