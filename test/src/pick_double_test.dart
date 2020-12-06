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

      test('null throws', () {
        expect(
          () => nullPick().asDoubleOrThrow(),
          throwsA(pickException(containing: [
            'required value at location `unknownKey` is absent. Use asDoubleOrNull() when the value may be null/absent at some point (double?).'
          ])),
        );

        expect(
          () => nullPick().asDoubleOrThrow(),
          throwsA(pickException(containing: ['unknownKey', 'null', 'double'])),
        );
      });

      test('wrong type throws', () {
        expect(
          () => pick(Object()).asDoubleOrThrow(),
          throwsA(pickException(containing: [
            "value Instance of 'Object' of type Object at location `<root>` can not be parsed as double"
          ])),
        );

        expect(
          () => pick('Bubblegum').asDoubleOrThrow(),
          throwsA(pickException(containing: ['Bubblegum', 'String', 'double'])),
        );
      });
    });

    test('deprecated asDouble forwards to asDoubleOrThrow', () {
      // ignore: deprecated_member_use_from_same_package
      expect(pick('1').asDouble(), 1.0);
      expect(
        // ignore: deprecated_member_use_from_same_package
        () => pick(Object()).asDouble(),
        throwsA(pickException(containing: [
          "value Instance of 'Object' of type Object at location `<root>` can not be parsed as double"
        ])),
      );
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
}
