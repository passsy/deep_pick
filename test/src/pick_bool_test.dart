import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

import 'pick_test.dart';

void main() {
  group('pick().asBool*', () {
    test('asBoolOrNull()', () {
      expect(pick(true).asBoolOrNull(), isTrue);
      expect(pick('a').asBoolOrNull(), isNull);
      expect(nullPick().asBoolOrNull(), isNull);
    });

    test('asBoolOrTrue()', () {
      expect(pick(true).asBoolOrTrue(), isTrue);
      expect(pick(false).asBoolOrTrue(), isFalse);
      expect(pick('a').asBoolOrTrue(), isTrue);
      expect(nullPick().asBoolOrTrue(), isTrue);
    });

    test('asBoolOrFalse()', () {
      expect(pick(true).asBoolOrFalse(), isTrue);
      expect(pick(false).asBoolOrFalse(), isFalse);
      expect(pick('a').asBoolOrFalse(), isFalse);
      expect(nullPick().asBoolOrFalse(), isFalse);
    });

    test('asBoolOrThrow()', () {
      expect(pick(true).asBoolOrThrow(), isTrue);
      expect(pick('true').asBoolOrThrow(), isTrue);
      expect(pick('false').asBoolOrThrow(), isFalse);
      expect(
        () => pick('Bubblegum').asBoolOrThrow(),
        throwsA(
          pickException(containing: ['String', 'Bubblegum', '<root>', 'bool']),
        ),
      );
      expect(
        () => nullPick().asBoolOrThrow(),
        throwsA(
          pickException(
            containing: ['unknownKey', 'asBoolOrNull', 'null', 'bool?'],
          ),
        ),
      );
    });
  });

  group('pick().required().asBool*', () {
    test('asBoolOrNull()', () {
      expect(pick(true).required().asBoolOrNull(), isTrue);
      expect(pick('a').required().asBoolOrNull(), isNull);
    });

    test('asBoolOrTrue()', () {
      expect(pick(true).required().asBoolOrTrue(), isTrue);
      expect(pick(false).required().asBoolOrTrue(), isFalse);
      expect(pick('a').required().asBoolOrTrue(), isTrue);
    });

    test('asBoolOrFalse()', () {
      expect(pick(true).required().asBoolOrFalse(), isTrue);
      expect(pick(false).required().asBoolOrFalse(), isFalse);
      expect(pick('a').required().asBoolOrFalse(), isFalse);
    });

    test('asBoolOrThrow()', () {
      expect(pick(true).required().asBoolOrThrow(), isTrue);
      expect(pick('true').required().asBoolOrThrow(), isTrue);
      expect(pick('false').required().asBoolOrThrow(), isFalse);
      expect(
        () => pick('Bubblegum').required().asBoolOrThrow(),
        throwsA(
          pickException(containing: ['String', 'Bubblegum', '<root>', 'bool']),
        ),
      );
      expect(
        () => nullPick().required().asBoolOrThrow(),
        throwsA(
          pickException(containing: ['unknownKey', 'absent']),
        ),
      );
    });
  });
}
