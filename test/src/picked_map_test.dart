import 'dart:convert';

import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

import 'pick_test.dart';

void main() {
  final data = {
    'persons': {
      'jon': {'name': 'John Snow'},
      'dany': {'name': 'Daenerys Targaryen'},
    },
  };
  Person parse(RequiredPick pick) => Person.fromPick(pick);

  group('PickedMap', () {
    test('asJsonObject* and asMap* return it, it is a regular Map', () {
      final jsonObject = pick(data, 'persons').asJsonObjectOrThrow();
      expect(jsonObject, isA<PickedMap<String, Object?>>());
      expect(jsonObject, isA<Map<String, dynamic>>());
      expect(jsonObject, data['persons']);
      expect(jsonEncode(jsonObject), jsonEncode(data['persons']));

      expect(
        pick({1: 'gold'}).asMapOrThrow<int, String>(),
        isA<PickedMap<int, String>>(),
      );
    });

    test('a custom parser can return one', () {
      final custom = pick({
        'jon': {'name': 'John Snow'},
        'count': 1,
      }).asObjectMap();
      expect(custom, isA<PickedMap<String, Object?>>());
      expect(custom.mapValues(parse), {'jon': Person(name: 'John Snow')});
    });

    group('mapValues', () {
      test('parses the values', () {
        final persons =
            pick(data, 'persons').asJsonObjectOrThrow().mapValues(parse);
        expect(persons, isA<Map<String, Person>>());
        expect(persons, {
          'jon': Person(name: 'John Snow'),
          'dany': Person(name: 'Daenerys Targaryen'),
        });
      });

      test('works for the typed values of asMap*', () {
        final doubled = pick({'a': 1, 'b': 2})
            .asMapOrThrow<String, int>()
            .mapValues((pick) => pick.asIntOrThrow() * 2);
        expect(doubled, {'a': 2, 'b': 4});
      });

      test('reports the location of a broken value', () {
        final broken = {
          'persons': {
            'jon': {'name': 'John Snow'},
            'dany': {'nick': 'Dany'},
          },
        };
        expect(
          () => pick(broken, 'persons').asJsonObjectOrThrow().mapValues(parse),
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

      test('skips null values', () {
        final withNull = {
          'jon': {'name': 'John Snow'},
          'nobody': null,
        };
        expect(
          pick(withNull).asJsonObjectOrThrow().mapValues(parse),
          {'jon': Person(name: 'John Snow')},
        );
      });

      test('locates values of keys that are not Strings, also null', () {
        final byId = {
          1: {'name': 'John Snow'},
          null: {'nick': 'nobody'},
        };
        final persons = pick({'persons': byId}, 'persons')
            .asMapOrThrow<int?, Map<String, String>>();
        expect(
          persons.mapValues((pick) => pick.index),
          {1: 1, null: null},
        );
        expect(
          () => persons.mapValues(parse),
          throwsA(
            pickException(
              containing: [
                'expected a non-null value at persons.null.name, but it is absent',
              ],
            ),
          ),
        );
      });

      test('passes the context and the redaction of the map on', () {
        final root =
            pick(data, 'persons').withContext('lang', 'de').redactValues();
        final persons = root.asJsonObjectOrThrow();
        expect(
          persons.mapValues((pick) => pick.context['lang']),
          {'jon': 'de', 'dany': 'de'},
        );
        expect(
          () => persons.mapValues((pick) => pick('name').asIntOrThrow()),
          throwsA(
            pickException(
              containing: [
                'could not parse an int at persons.jon.name',
                '<String>',
              ],
            ),
          ),
        );
      });

      test('each value gets a context of its own', () {
        final root = pick(data, 'persons');
        root.asJsonObjectOrThrow().mapValues((pick) {
          pick.context['seen'] = true;
          return pick.context.length;
        });
        expect(root.context, isEmpty);
      });

      test('uses the values the map holds now', () {
        final persons = pick(data, 'persons').asJsonObjectOrThrow();
        persons['jon'] = {'name': 'Aegon Targaryen'};
        persons['arya'] = {'nick': 'No One'};
        persons.remove('dany');

        expect(
          persons.mapValues((pick) => pick('name').asStringOrNull()),
          {'jon': 'Aegon Targaryen', 'arya': null},
        );
        expect(
          () => persons.mapValues(parse),
          throwsA(
            pickException(
              containing: [
                'expected a non-null value at persons.arya.name, but it is absent',
              ],
            ),
          ),
        );
      });

      test('an empty or missing map maps to an empty map', () {
        expect(nullPick().asJsonObjectOrEmpty().mapValues(parse), isEmpty);
        expect(pick('a').asMapOrEmpty<String, Object?>().mapValues(parse),
            isEmpty);
        expect(nullPick().asJsonObjectOrNull()?.mapValues(parse), isNull);
      });
    });

    group('mapKeys', () {
      test('converts the keys with the parsers of a pick', () {
        final medals = pick({'1': 'gold', '2': 'silver'})
            .asJsonObjectOrThrow()
            .mapKeys((key) => key.asIntOrThrow());
        expect(medals, isA<PickedMap<int, Object?>>());
        expect(medals, {1: 'gold', 2: 'silver'});
      });

      test('receives keys of any type, also null', () {
        final keys = <Object?>[];
        final result = pick({1: 'int', 'a': 'String', null: 'null'})
            .asMapOrThrow<Object?, String>()
            .mapKeys((key) {
          keys.add(key.value);
          return key.asStringOrNull() ?? 'none';
        });
        expect(keys, [1, 'a', null]);
        expect(result, {'1': 'int', 'a': 'String', 'none': 'null'});
      });

      test('reports a broken key at the location of its map', () {
        expect(
          () => pick({
            'medals': {'first': 'gold'},
          }, 'medals')
              .asJsonObjectOrThrow()
              .mapKeys((key) => key.asIntOrThrow()),
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

      test('passes the context and the redaction of the map on', () {
        final root = pick({'first': 'gold'}).withContext('lang', 'de');
        expect(
          root.asJsonObjectOrThrow().mapKeys(
                (key) => '${key.context['lang']}-${key.asStringOrThrow()}',
              ),
          {'de-first': 'gold'},
        );
        expect(
          () => root
              .redactValues()
              .asJsonObjectOrThrow()
              .mapKeys((key) => key.asIntOrThrow()),
          throwsA(
            pickException(containing: ['could not parse an int', '<String>']),
          ),
        );
      });

      test('the later entry wins when two keys become the same', () {
        final byLength = pick({'ab': 1, 'cd': 2, 'efg': 3})
            .asJsonObjectOrThrow()
            .mapKeys((key) => key.asStringOrThrow().length);
        expect(byLength, {2: 2, 3: 3});
      });

      test('mapValues still locates the values by their original key', () {
        final broken = {
          'persons': {
            'jon': {'name': 'John Snow'},
            'dany': {'nick': 'Dany'},
          },
        };
        final byLength = pick(broken, 'persons')
            .asJsonObjectOrThrow()
            .mapKeys((key) => key.asStringOrThrow().length)
            .mapKeys((key) => key.asIntOrThrow() * 10);
        expect(byLength.keys, [30, 40]);
        expect(
          byLength.mapValues((pick) => pick('name').asStringOrNull()),
          {30: 'John Snow', 40: null},
        );
        expect(
          () => byLength.mapValues(parse),
          throwsA(
            pickException(
              containing: [
                'expected a non-null value at persons.dany.name, but it is absent',
              ],
            ),
          ),
        );
      });

      test('keys and values in one chain', () {
        final Map<int, Person> persons = pick(data, 'persons')
            .asJsonObjectOrThrow()
            .mapKeys((key) => key.asStringOrThrow().length)
            .mapValues(parse);
        expect(persons, {
          3: Person(name: 'John Snow'),
          4: Person(name: 'Daenerys Targaryen'),
        });
      });
    });
  });
}

extension on Pick {
  /// A custom parser that returns a [PickedMap], it keeps the entries that
  /// hold an object
  PickedMap<String, Object?> asObjectMap() {
    final objects = <String, Object?>{};
    for (final entry in asJsonObjectOrThrow().entries) {
      if (entry.value is Map) {
        objects[entry.key] = entry.value;
      }
    }
    return PickedMap(objects, this);
  }
}
