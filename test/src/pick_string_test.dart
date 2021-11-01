import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

import 'pick_test.dart';

void main() {
  group('pick().asString*', () {
    group('asStringOrThrow', () {
      test('parse anything to String', () {
        expect(pick('adam').asStringOrThrow(), 'adam');
        expect(pick(1).asStringOrThrow(), '1');
        expect(pick(2.0).asStringOrThrow(), '2.0');
        expect(
          pick(DateTime(2000)).asStringOrThrow(),
          '2000-01-01 00:00:00.000',
        );
      });

      test('asString() alsow works for Maps and Lists calling their toString',
          () {
        expect(pick(['a', 'b']).asStringOrThrow(), '[a, b]');
        expect(pick({'a': 1}).asStringOrThrow(), '{a: 1}');
      });

      test('null throws', () {
        expect(
          () => nullPick().asStringOrThrow(),
          throwsA(
            pickException(
              containing: [
                'Expected a non-null value but location "unknownKey" in pick(json, "unknownKey" (absent)) is absent. Use asStringOrNull() when the value may be null/absent at some point (String?).'
              ],
            ),
          ),
        );
      });
    });

    group('asStringOrNull', () {
      test('parse String', () {
        expect(pick('2012').asStringOrNull(), '2012');
      });

      test('null returns null', () {
        expect(nullPick().asStringOrNull(), isNull);
      });

      test('as long it is not null it prints toString', () {
        expect(pick(Object()).asStringOrNull(), "Instance of 'Object'");
      });
    });
  });

  group('pick().required().asString*', () {
    group('asStringOrThrow', () {
      test('parse anything to String', () {
        expect(pick('adam').required().asStringOrThrow(), 'adam');
        expect(pick(1).required().asStringOrThrow(), '1');
        expect(pick(2.0).required().asStringOrThrow(), '2.0');
        expect(
          pick(DateTime(2000)).required().asStringOrThrow(),
          '2000-01-01 00:00:00.000',
        );
      });

      test("asString() doesn't transform Maps and Lists with toString", () {
        expect(pick(['a', 'b']).required().asStringOrThrow(), '[a, b]');
        expect(pick({'a': 1}).required().asStringOrThrow(), '{a: 1}');
      });

      test('null throws', () {
        expect(
          () => nullPick().required().asStringOrThrow(),
          throwsA(
            pickException(
              containing: [
                'Expected a non-null value but location "unknownKey" in pick(json, "unknownKey" (absent)) is absent.'
              ],
            ),
          ),
        );
      });
    });

    group('asStringOrNull', () {
      test('parse String', () {
        expect(pick('2012').required().asStringOrNull(), '2012');
      });

      test('as long it is not null it prints toString', () {
        expect(
          pick(Object()).required().asStringOrNull(),
          "Instance of 'Object'",
        );
      });
    });

    test('required().asString()', () {
      expect(pick('adam').required().asString(), 'adam');
      expect(pick([]).required().asString(), '[]');
    });
  });
}
