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

  group('pick().asMap* with mappers', () {
    final data = {
      'jon': {'name': 'John Snow'},
      'dany': {'name': 'Daenerys Targaryen'},
    };

    test('mapValue parses the values', () {
      final Map<String, Person> persons =
          pick(data).asMapOrThrow(mapValue: (pick) => Person.fromPick(pick));
      expect(persons, {
        'jon': Person(name: 'John Snow'),
        'dany': Person(name: 'Daenerys Targaryen'),
      });
    });

    test('mapValue alone leaves the key type open', () {
      final persons =
          pick(data).asMapOrThrow(mapValue: (pick) => Person.fromPick(pick));
      expect(persons, isA<Map<dynamic, Person>>());
      expect(persons, isNot(isA<Map<String, Person>>()));
    });

    test('mapValue reports the location of a broken value', () {
      final broken = {
        'jon': {'name': 'John Snow'},
        'dany': {'nick': 'Dany'},
      };
      expect(
        () => pick({'persons': broken}, 'persons').asMapOrThrow(
          mapValue: (pick) => Person.fromPick(pick),
        ),
        throwsA(
          pickException(
            containing: [
              'expected a non-null value at persons.dany.name, but it is absent',
              'persons.dany = {"nick": "Dany"}',
            ],
          ),
        ),
      );
    });

    test('mapValue skips null values', () {
      final withNull = {
        'jon': {'name': 'John Snow'},
        'nobody': null,
      };
      final persons = pick(withNull).asMapOrThrow<String, Person>(
        mapValue: (pick) => Person.fromPick(pick),
      );
      expect(persons, {'jon': Person(name: 'John Snow')});
    });

    test('mapValue receives the context and the redaction of the map', () {
      final root = pick(data).withContext('lang', 'de').redactValues();
      final contexts = root.asMapOrThrow<String, Object?>(
        mapValue: (pick) => pick.context['lang'],
      );
      expect(contexts, {'jon': 'de', 'dany': 'de'});

      expect(
        () => root.asMapOrThrow<String, int>(
          mapValue: (pick) => pick('name').asIntOrThrow(),
        ),
        throwsA(
          pickException(
            containing: ['could not parse an int at jon.name', '<String>'],
          ),
        ),
      );
    });

    test('mapValue works for keys that are not Strings', () {
      final byId = {
        1: {'name': 'John Snow'},
      };
      final persons = pick(byId).asMapOrThrow<int, Person>(
        mapValue: (pick) => Person.fromPick(pick),
      );
      expect(persons, {1: Person(name: 'John Snow')});
    });

    test('mapValue works for a null key', () {
      final nullKey = {
        null: {'name': 'John Snow'},
      };
      final persons = pick(nullKey).asMapOrThrow<String?, Person>(
        mapValue: (pick) => Person.fromPick(pick),
      );
      expect(persons, {null: Person(name: 'John Snow')});

      final broken = {
        null: {'nick': 'Jon'},
      };
      expect(
        () =>
            pick({'persons': broken}, 'persons').asMapOrThrow<String?, Person>(
          mapValue: (pick) => Person.fromPick(pick),
        ),
        throwsA(
          pickException(
            containing: [
              'expected a non-null value at persons.null.name, but it is absent',
            ],
          ),
        ),
      );
    });

    test('mapKey converts the keys and casts the values', () {
      final Map<int, String> medals = pick({'1': 'gold', '2': 'silver'})
          .asMapOrThrow(mapKey: (key) => key.asIntOrThrow());
      expect(medals, {1: 'gold', 2: 'silver'});

      expect(
        () => pick({'1': 'gold'}).asMapOrThrow<int, bool>(
          mapKey: (key) => key.asIntOrThrow(),
        ),
        throwsA(isA<TypeError>()),
      );
    });

    test('mapKey receives keys of any type, also null', () {
      final keys = <Object?>[];
      final result = pick({1: 'int', 'a': 'String', null: 'null'})
          .asMapOrThrow<String, String>(
        mapKey: (key) {
          keys.add(key.value);
          return key.asStringOrNull() ?? 'none';
        },
      );
      expect(keys, [1, 'a', null]);
      expect(result, {'1': 'int', 'a': 'String', 'none': 'null'});
    });

    test('mapKey reports a broken key at the location of its map', () {
      expect(
        () => pick({
          'medals': {'first': 'gold'},
        }, 'medals')
            .asMapOrThrow<int, String>(mapKey: (key) => key.asIntOrThrow()),
        throwsA(
          pickException(
            containing: [
              'could not parse an int at medals',
              'found   "first"  (a String)',
            ],
          ),
        ),
      );
    });

    test('mapKey receives the context and the redaction of the map', () {
      final root = pick({'first': 'gold'}).withContext('lang', 'de');
      final result = root.asMapOrThrow<String, String>(
        mapKey: (key) => '${key.context['lang']}-${key.asStringOrThrow()}',
      );
      expect(result, {'de-first': 'gold'});

      expect(
        () => root.redactValues().asMapOrThrow<int, String>(
              mapKey: (key) => key.asIntOrThrow(),
            ),
        throwsA(
          pickException(containing: ['could not parse an int', '<String>']),
        ),
      );
    });

    test('mapKey and mapValue together', () {
      final persons = pick(data).asMapOrThrow(
        mapKey: (key) => key.asStringOrThrow().length,
        mapValue: (pick) => Person.fromPick(pick),
      );
      expect(persons, isA<Map<int, Person>>());
      expect(persons, {
        3: Person(name: 'John Snow'),
        4: Person(name: 'Daenerys Targaryen'),
      });
    });

    test('whenNullValue maps the null values that mapValue skips', () {
      final withNull = {
        'jon': {'name': 'John Snow'},
        'nobody': null,
      };
      final Map<String, Person?> persons = pick(withNull).asMapOrThrow(
        mapValue: (pick) => Person.fromPick(pick),
        whenNullValue: (pick) => null,
      );
      expect(persons, {'jon': Person(name: 'John Snow'), 'nobody': null});
    });

    test('whenNullValue receives a pick of the null value at its key', () {
      final withNull = {
        'persons': {
          'jon': {'name': 'John Snow'},
          'nobody': null,
        },
      };
      final picks = <Pick>[];
      final persons = pick(withNull, 'persons')
          .withContext('lang', 'de')
          .asMapOrThrow<String, Person>(
            mapValue: (pick) => Person.fromPick(pick),
            whenNullValue: (pick) {
              picks.add(pick);
              return Person(name: 'unknown');
            },
          );
      expect(persons['nobody'], Person(name: 'unknown'));
      expect(picks.single.value, isNull);
      expect(picks.single.isAbsent, isFalse);
      expect(picks.single.context, {'lang': 'de'});
      expect(
        () => picks.single.required(),
        throwsA(
          pickException(
            containing: [
              'expected a non-null value at persons.nobody, but it is null',
            ],
          ),
        ),
      );
    });

    test('whenNullValue alone replaces null values and casts the others', () {
      final scores = pick({'a': 1, 'b': null})
          .asMapOrThrow<String, int>(whenNullValue: (pick) => 0);
      expect(scores, {'a': 1, 'b': 0});
    });

    test('asMapOrEmpty and asMapOrNull take the same mappers', () {
      Person parse(RequiredPick pick) => Person.fromPick(pick);
      String upper(Pick key) => key.asStringOrThrow().toUpperCase();
      final expected = {
        'JON': Person(name: 'John Snow'),
        'DANY': Person(name: 'Daenerys Targaryen'),
      };

      expect(
        pick(data).asMapOrEmpty(mapKey: upper, mapValue: parse),
        expected,
      );
      expect(nullPick().asMapOrEmpty(mapKey: upper, mapValue: parse), isEmpty);
      expect(pick('a').asMapOrEmpty(mapKey: upper, mapValue: parse), isEmpty);

      expect(
        pick(data).asMapOrNull(mapKey: upper, mapValue: parse),
        expected,
      );
      expect(nullPick().asMapOrNull(mapKey: upper, mapValue: parse), isNull);
      expect(pick('a').asMapOrNull(mapKey: upper, mapValue: parse), isNull);
    });
  });

  group('pick().asJsonObject* with mappers', () {
    final data = {
      'jon': {'name': 'John Snow'},
      'dany': {'name': 'Daenerys Targaryen'},
    };
    Person parse(RequiredPick pick) => Person.fromPick(pick);

    test('parses the values, the keys are Strings', () {
      final persons = pick(data).asJsonObjectOrThrow(mapValue: parse);
      expect(persons, isA<Map<String, Person>>());
      expect(persons, {
        'jon': Person(name: 'John Snow'),
        'dany': Person(name: 'Daenerys Targaryen'),
      });
    });

    test('ignores non-String keys and null values', () {
      final mixed = {
        'jon': {'name': 'John Snow'},
        7: {'name': 'Seven'},
        'nobody': null,
      };
      expect(
        pick(mixed).asJsonObjectOrThrow(mapValue: parse),
        {'jon': Person(name: 'John Snow')},
      );
    });

    test('reports the location of a broken value', () {
      final broken = {
        'persons': {
          'dany': {'nick': 'Dany'},
        },
      };
      expect(
        () => pick(broken, 'persons').asJsonObjectOrThrow(mapValue: parse),
        throwsA(
          pickException(
            containing: [
              'expected a non-null value at persons.dany.name, but it is absent',
            ],
          ),
        ),
      );
    });

    test('a missing value names the mapped type in the hint', () {
      expect(
        () => nullPick().asJsonObjectOrThrow(mapValue: parse),
        throwsA(
          pickException(
            containing: [
              'expected a non-null value at unknownKey, but it is absent',
              '(Map<String, Person>?).',
            ],
          ),
        ),
      );
    });

    test('whenNullValue maps the null values that mapValue skips', () {
      final withNull = {
        'jon': {'name': 'John Snow'},
        'nobody': null,
      };
      final persons = pick(withNull).asJsonObjectOrThrow(
        mapValue: parse,
        whenNullValue: (pick) => Person(name: 'unknown'),
      );
      expect(persons, isA<Map<String, Person>>());
      expect(persons, {
        'jon': Person(name: 'John Snow'),
        'nobody': Person(name: 'unknown'),
      });

      final nullable = pick(withNull).asJsonObjectOrThrow<String, Person?>(
        mapValue: parse,
        whenNullValue: (pick) => null,
      );
      expect(nullable, {'jon': Person(name: 'John Snow'), 'nobody': null});
    });

    test('mapKey renames the keys, they stay Strings', () {
      final persons = pick(data).asJsonObjectOrThrow(
        mapKey: (key) => key.asStringOrThrow().toUpperCase(),
        mapValue: parse,
      );
      expect(persons, isA<Map<String, Person>>());
      expect(persons.keys, ['JON', 'DANY']);
    });

    test('mapKey never sees a key that is not a String', () {
      final keys = <Object?>[];
      final result = pick({'a': 1, 2: 'two', null: 3}).asJsonObjectOrThrow(
        mapKey: (key) {
          keys.add(key.value);
          return key.asStringOrThrow();
        },
      );
      expect(keys, ['a']);
      expect(result, {'a': 1});
    });

    test('mapKey reports a broken key at the location of its map', () {
      expect(
        () => pick({
          'medals': {'first': 'gold'},
        }, 'medals')
            .asJsonObjectOrThrow(
          mapKey: (key) => key.asIntOrThrow().toString(),
        ),
        throwsA(
          pickException(
            containing: [
              'could not parse an int at medals',
              'found   "first"  (a String)',
            ],
          ),
        ),
      );
    });

    test('a call without mappers still is a Map<String, Object?>', () {
      final plain = pick({'a': 1}).asJsonObjectOrThrow();
      // not a Map<String, dynamic>, the type parameters fall back to their
      // bounds
      expect('${plain.runtimeType}', contains('<String, Object?>'));
      expect('${nullPick().asJsonObjectOrEmpty().runtimeType}',
          contains('<String, Object?>'));
    });

    test('asJsonObjectOrEmpty and asJsonObjectOrNull take the mapper', () {
      final expected = {
        'jon': Person(name: 'John Snow'),
        'dany': Person(name: 'Daenerys Targaryen'),
      };
      String same(Pick key) => key.asStringOrThrow();
      Person unknown(Pick pick) => Person(name: 'unknown');

      expect(
        pick(data).asJsonObjectOrEmpty(
          mapKey: same,
          mapValue: parse,
          whenNullValue: unknown,
        ),
        expected,
      );
      expect(nullPick().asJsonObjectOrEmpty(mapValue: parse), isEmpty);
      expect(pick('a').asJsonObjectOrEmpty(mapValue: parse), isEmpty);

      expect(
        pick(data).asJsonObjectOrNull(
          mapKey: same,
          mapValue: parse,
          whenNullValue: unknown,
        ),
        expected,
      );
      expect(nullPick().asJsonObjectOrNull(mapValue: parse), isNull);
      expect(pick('a').asJsonObjectOrNull(mapValue: parse), isNull);
    });

    test('without a mapper the values are cast to the expected type', () {
      final Map<String, int> numbers = pick({'a': 1}).asJsonObjectOrThrow();
      expect(numbers, {'a': 1});

      expect(
        () {
          final Map<String, int> broken =
              pick({'a': 'one'}).asJsonObjectOrThrow();
          return broken;
        },
        throwsA(isA<TypeError>()),
      );
    });
  });
}

class _User {
  _User.fromJson(Map<String, dynamic> json) : name = json['name'] as String;

  final String name;
}
