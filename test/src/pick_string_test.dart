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
            pick(DateTime(2000)).asStringOrThrow(), '2000-01-01 00:00:00.000');
      });

      test('null throws', () {
        expect(
          () => nullPick().asStringOrThrow(),
          throwsA(pickException(containing: [
            'required value at location `unknownKey` is absent. Use asStringOrNull() when the value may be null/absent at some point (String?).'
          ])),
        );
      });
    });

    test('deprecated asString forwards to asStringOrThrow', () {
      // ignore: deprecated_member_use_from_same_package
      expect(pick('1').asString(), '1');
      expect(
        // ignore: deprecated_member_use_from_same_package
        () => nullPick().asString(),
        throwsA(pickException(containing: [
          'required value at location `unknownKey` is absent. Use asStringOrNull() when the value may be null/absent at some point (String?).'
        ])),
      );
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
}
