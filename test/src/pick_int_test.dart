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

      test('parse double', () {
        expect(pick(1.0).asIntOrThrow(), 1);
      });

      test('parse int String', () {
        expect(pick('1').asIntOrThrow(), 1);
        expect(pick('123').asIntOrThrow(), 123);
      });

      test('null throws', () {
        expect(
          () => nullPick().asIntOrThrow(),
          throwsA(pickException(containing: [
            'required value at location "unknownKey" in pick(json, "unknownKey" (absent)) is absent. Use asIntOrNull() when the value may be null/absent at some point (int?).'
          ])),
        );
      });

      test('wrong type throws', () {
        expect(
          () => pick(Object()).asIntOrThrow(),
          throwsA(pickException(containing: [
            "value Instance of 'Object' of type Object at location \"<root>\" in pick(<root>) can not be parsed as int"
          ])),
        );

        expect(
          () => pick('Bubblegum').asIntOrThrow(),
          throwsA(pickException(containing: ['Bubblegum', 'String', 'int'])),
        );
      });
    });

    test('deprecated asInt forwards to asIntOrThrow', () {
      // ignore: deprecated_member_use_from_same_package
      expect(pick('1').asInt(), 1.0);
      expect(
        // ignore: deprecated_member_use_from_same_package
        () => pick(Object()).asInt(),
        throwsA(pickException(containing: [
          "value Instance of 'Object' of type Object at location \"<root>\" in pick(<root>) can not be parsed as int"
        ])),
      );
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
}
