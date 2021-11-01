import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

import 'pick_test.dart';

void main() {
  group('pick().asMap*', () {
    group('asMapOrThrow', () {
      test('pipe through Map', () {
        expect(pick({'ab': 'cd'}).asMapOrThrow(), {'ab': 'cd'});
      });

      test('null throws', () {
        expect(
          () => nullPick().asMapOrThrow<String, bool>(),
          throwsA(
            pickException(
              containing: [
                'Expected a non-null value but location "unknownKey" in pick(json, "unknownKey" (absent)) is absent. Use asMapOrEmpty()/asMapOrNull() when the value may be null/absent at some point (Map<String, bool>?).'
              ],
            ),
          ),
        );
      });

      test('throws for cast error', () {
        final dynamic data = {
          'a': {'some': 'value'}
        };

        try {
          final parsed = pick(data).asMapOrThrow<String, bool>();
          fail(
            'casted map without verifying the types. '
            'Expected Map<String, bool> but was ${parsed.runtimeType}',
          );
          // ignore: avoid_catching_errors
        } on TypeError catch (e) {
          expect(
            e,
            const TypeMatcher<TypeError>().having(
              (e) => e.toString(),
              'message',
              stringContainsInOrder(
                ['<String, String>', 'is not a subtype of type', 'bool'],
              ),
            ),
          );
        }
      });

      test('wrong type throws', () {
        expect(
          () => pick('Bubblegum').asMapOrThrow(),
          throwsA(
            pickException(
              containing: ['String', 'Bubblegum', 'Map<dynamic, dynamic>'],
            ),
          ),
        );
        expect(
          () => pick(Object()).asMapOrThrow(),
          throwsA(
            pickException(
              containing: [
                'Type Object of picked value "Instance of \'Object\'" using pick(<root>) can not be casted to Map<dynamic, dynamic>'
              ],
            ),
          ),
        );
      });
    });

    group('asMapOrEmpty', () {
      test('pick value', () {
        expect(pick({'ab': 'cd'}).asMapOrEmpty(), {'ab': 'cd'});
      });

      test('null returns null', () {
        expect(nullPick().asMapOrEmpty(), {});
      });

      test('wrong type returns empty', () {
        expect(pick(Object()).asMapOrEmpty(), {});
      });

      test('reports errors correctly', () {
        final dynamic data = {
          'a': {'some': 'value'}
        };

        try {
          final parsed = pick(data).asMapOrEmpty<String, bool>();
          fail(
            'casted map without verifying the types. '
            'Expected Map<String, bool> but was ${parsed.runtimeType}',
          );
          // ignore: avoid_catching_errors
        } on TypeError catch (e) {
          expect(
            e,
            const TypeMatcher<TypeError>().having(
              (e) => e.toString(),
              'message',
              stringContainsInOrder(
                ['<String, String>', 'is not a subtype of type', 'bool'],
              ),
            ),
          );
          // ignore: avoid_catching_errors, deprecated_member_use
        }
      });
    });

    group('asMapOrNull', () {
      test('pick value', () {
        expect(pick({'ab': 'cd'}).asMapOrNull(), {'ab': 'cd'});
      });

      test('null returns null', () {
        expect(nullPick().asMapOrNull(), isNull);
      });

      test('wrong type returns empty', () {
        expect(pick(Object()).asMapOrNull(), isNull);
      });
    });
  });
}
