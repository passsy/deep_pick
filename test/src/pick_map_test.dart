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
                'expected a non-null value at unknownKey, but it is absent',
                'Use asMapOrEmpty()/asMapOrNull() when the value may be null/absent at some point (Map<String, bool>?).',
              ],
            ),
          ),
        );
      });

      test('throws for cast error', () {
        final dynamic data = {
          'a': {'some': 'value'},
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
              containing: [
                'expected a Map at <root>',
                'Bubblegum',
                '(a String)',
              ],
            ),
          ),
        );
        expect(
          () => pick(Object()).asMapOrThrow(),
          throwsA(
            pickException(
              containing: [
                'expected a Map at <root>',
                '(an Object)',
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
          'a': {'some': 'value'},
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

  group('pick().asJsonObject*', () {
    group('asJsonObjectOrThrow', () {
      test('pipe through Map', () {
        expect(pick({'ab': 'cd'}).asJsonObjectOrThrow(), {'ab': 'cd'});
      });

      test('can be passed to a fromJson function', () {
        final dynamic data = {
          'user': {'name': 'John Snow'},
        };
        final user = _User.fromJson(pick(data, 'user').asJsonObjectOrThrow());
        expect(user.name, 'John Snow');
      });

      test('ignores entries with non-String keys', () {
        final data = {
          'a': 1,
          2: 'two',
          DateTime(2026): 'date',
          null: 'null',
          'b': null,
        };
        expect(pick(data).asJsonObjectOrThrow(), {'a': 1, 'b': null});
      });

      test('keeps nested values as they are', () {
        final nested = {1: 'one'};
        final result = pick({'nested': nested}).asJsonObjectOrThrow();
        expect(result['nested'], same(nested));
      });

      test('returns a copy', () {
        final data = {'a': 1};
        pick(data).asJsonObjectOrThrow()['b'] = 2;
        expect(data, {'a': 1});
      });

      test('null throws', () {
        expect(
          () => nullPick().asJsonObjectOrThrow(),
          throwsA(
            pickException(
              containing: [
                'expected a non-null value at unknownKey, but it is absent',
                'Use asJsonObjectOrEmpty()/asJsonObjectOrNull() when the value may be null/absent at some point (Map<String, Object?>?).',
              ],
            ),
          ),
        );
      });

      test('wrong type throws', () {
        expect(
          () => pick('Bubblegum').asJsonObjectOrThrow(),
          throwsA(
            pickException(
              containing: [
                'expected a Map at <root>',
                'Bubblegum',
                '(a String)',
              ],
            ),
          ),
        );
      });
    });

    group('asJsonObjectOrEmpty', () {
      test('pick value', () {
        expect(pick({'ab': 'cd', 1: 2}).asJsonObjectOrEmpty(), {'ab': 'cd'});
      });

      test('null returns empty', () {
        expect(nullPick().asJsonObjectOrEmpty(), <String, Object?>{});
      });

      test('wrong type returns empty', () {
        expect(pick(Object()).asJsonObjectOrEmpty(), <String, Object?>{});
      });
    });

    group('asJsonObjectOrNull', () {
      test('pick value', () {
        expect(pick({'ab': 'cd', 1: 2}).asJsonObjectOrNull(), {'ab': 'cd'});
      });

      test('null returns null', () {
        expect(nullPick().asJsonObjectOrNull(), isNull);
      });

      test('wrong type returns null', () {
        expect(pick(Object()).asJsonObjectOrNull(), isNull);
      });
    });
  });
}

class _User {
  _User.fromJson(Map<String, dynamic> json) : name = json['name'] as String;

  final String name;
}
