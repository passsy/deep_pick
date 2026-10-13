import 'dart:async';

import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

import 'pick_test.dart';

void main() {
  group('pick().asList*', () {
    group('asListOrThrow', () {
      test('redacted list null callback diagnostics never print sibling values',
          () {
        const secret = 'PRIVATE_CUSTOMER_VALUE';
        final root = pick([
          {'secret': secret},
          null,
        ]).redactValues();
        expect(root.value, hasLength(2));
        expect(root.redactsValues, isTrue);
        final messages = <String>[];
        final callbackError = StateError('callback failed');
        var reachedNullCallback = false;
        runZoned(
          () {
            expect(
              () => root.asListOrThrow<int>(
                (item) => 1,
                whenNull: (item) {
                  expect(item.value, isNull);
                  expect(item.path, [1]);
                  expect(item.redactsValues, isTrue);
                  reachedNullCallback = true;
                  throw callbackError;
                },
              ),
              throwsA(same(callbackError)),
            );
          },
          zoneSpecification: ZoneSpecification(print: (_, __, ___, message) {
            messages.add(message);
          }),
        );
        expect(reachedNullCallback, isTrue);
        expect(messages, isEmpty);
        expect(messages.join('\n'), isNot(contains(secret)));
      });
      test('pipe through List', () {
        expect(
          pick([1, 2, 3]).asListOrThrow((it) => it.asIntOrThrow()),
          [1, 2, 3],
        );
      });

      test('null throws', () {
        expect(
          () => nullPick().asListOrThrow((it) => it.asStringOrThrow()),
          throwsA(
            pickException(
              containing: [
                'expected a non-null value at unknownKey, but it is absent',
                'Use asListOrEmpty()/asListOrNull() when the value may be null/absent at some point (List<String>?).',
              ],
            ),
          ),
        );
      });

      test('map empty list to empty list', () {
        expect(
          pick([]).asListOrThrow((pick) => Person.fromPick(pick)),
          [],
        );
      });

      test('map to List<Person>', () {
        expect(
          pick([
            {'name': 'John Snow'},
            {'name': 'Daenerys Targaryen'},
          ]).asListOrThrow((pick) => Person.fromPick(pick)),
          [
            Person(name: 'John Snow'),
            Person(name: 'Daenerys Targaryen'),
          ],
        );
      });

      test('map to List<Person> ignoring null values', () {
        expect(
          pick([
            {'name': 'John Snow'},
            {'name': 'Daenerys Targaryen'},
            null, // <-- valid value
          ]).asListOrThrow((pick) => Person.fromPick(pick)),
          [
            Person(name: 'John Snow'),
            Person(name: 'Daenerys Targaryen'),
            // not 3rd item
          ],
        );
      });

      test('map to List<Person?> with whenNull', () {
        expect(
          pick([
            {'name': 'John Snow'},
            {'name': 'Daenerys Targaryen'},
            null, // <-- valid value
          ]).asListOrThrow(
            (pick) => Person.fromPick(pick),
            whenNull: (it) => null,
          ),
          [
            Person(name: 'John Snow'),
            Person(name: 'Daenerys Targaryen'),
            null,
          ],
        );
      });

      test('map reports item parsing errors', () {
        expect(
          () => pick([
            {'name': 'John Snow'},
            {'asdf': 'Daenerys Targaryen'}, // <-- missing name key
          ]).asListOrThrow((pick) => Person.fromPick(pick)),
          throwsA(
            pickException(
              containing: [
                'expected a non-null value at [1].name, but it is absent',
                'no such key',
              ],
            ),
          ),
        );
      });

      test('wrong type throws', () {
        expect(
          () => pick('Bubblegum').asListOrThrow((it) => it.asStringOrThrow()),
          throwsA(
            pickException(
              containing: [
                'expected a List at <root>',
                'Bubblegum',
                '(a String)',
              ],
            ),
          ),
        );
        expect(
          () => pick(Object()).asListOrThrow((it) => it.asStringOrThrow()),
          throwsA(
            pickException(
              containing: [
                'expected a List at <root>',
                '(an Object)',
              ],
            ),
          ),
        );
      });
    });

    group('asListOrEmpty', () {
      test('pick value', () {
        expect(
          pick([1, 2, 3]).asListOrEmpty((it) => it.asIntOrThrow()),
          [1, 2, 3],
        );
      });

      test('null returns null', () {
        expect(nullPick().asListOrEmpty((it) => it.asIntOrThrow()), []);
      });

      test('wrong type returns empty', () {
        expect(pick(Object()).asListOrEmpty((it) => it.asIntOrThrow()), []);
      });

      test('map empty list to empty list', () {
        expect(
          pick([]).asListOrEmpty((pick) => Person.fromPick(pick)),
          [],
        );
      });

      test('map null list to empty list', () {
        expect(
          nullPick().asListOrEmpty((pick) => Person.fromPick(pick)),
          [],
        );
      });

      test('map to List<Person>', () {
        expect(
          pick([
            {'name': 'John Snow'},
            {'name': 'Daenerys Targaryen'},
          ]).asListOrEmpty((pick) => Person.fromPick(pick)),
          [
            Person(name: 'John Snow'),
            Person(name: 'Daenerys Targaryen'),
          ],
        );
      });

      test('map to List<Person> ignoring null values', () {
        expect(
          pick([
            {'name': 'John Snow'},
            {'name': 'Daenerys Targaryen'},
            null, // <-- valid value
          ]).asListOrEmpty((pick) => Person.fromPick(pick)),
          [
            Person(name: 'John Snow'),
            Person(name: 'Daenerys Targaryen'),
            // not 3rd item
          ],
        );
      });

      test('map to List<Person?> with whenNull', () {
        expect(
          pick([
            {'name': 'John Snow'},
            {'name': 'Daenerys Targaryen'},
            null, // <-- valid value
          ]).asListOrEmpty(
            (pick) => Person.fromPick(pick),
            whenNull: (it) => null,
          ),
          [
            Person(name: 'John Snow'),
            Person(name: 'Daenerys Targaryen'),
            null,
          ],
        );
      });

      test('map reports item parsing errors', () {
        expect(
          () => pick([
            {'name': 'John Snow'},
            {'asdf': 'Daenerys Targaryen'}, // <-- missing name key
          ]).asListOrEmpty((pick) => Person.fromPick(pick)),
          throwsA(
            pickException(
              containing: [
                'expected a non-null value at [1].name, but it is absent',
              ],
            ),
          ),
        );
      });
    });

    group('asListOrNull', () {
      test('pick value', () {
        expect(
          pick([1, 2, 3]).asListOrNull((it) => it.asIntOrThrow()),
          [1, 2, 3],
        );
      });

      test('null returns null', () {
        expect(nullPick().asListOrNull((it) => it.asIntOrThrow()), isNull);
      });

      test('wrong type returns empty', () {
        expect(pick(Object()).asListOrNull((it) => it.asIntOrThrow()), isNull);
      });

      test('map empty list to empty list', () {
        expect(
          pick([]).asListOrNull((pick) => Person.fromPick(pick)),
          [],
        );
      });

      test('map null list to null', () {
        expect(
          nullPick().asListOrNull((pick) => Person.fromPick(pick)),
          null,
        );
      });

      test('map to List<Person>', () {
        expect(
          pick([
            {'name': 'John Snow'},
            {'name': 'Daenerys Targaryen'},
          ]).asListOrNull((pick) => Person.fromPick(pick)),
          [
            Person(name: 'John Snow'),
            Person(name: 'Daenerys Targaryen'),
          ],
        );
      });

      test('map to List<Person> ignoring null values', () {
        expect(
          pick([
            {'name': 'John Snow'},
            {'name': 'Daenerys Targaryen'},
            null, // <-- valid value
          ]).asListOrNull((pick) => Person.fromPick(pick)),
          [
            Person(name: 'John Snow'),
            Person(name: 'Daenerys Targaryen'),
            // not 3rd item
          ],
        );
      });

      test('map to List<Person?> with whenNull', () {
        expect(
          pick([
            {'name': 'John Snow'},
            {'name': 'Daenerys Targaryen'},
            null, // <-- valid value
          ]).asListOrNull(
            (pick) => Person.fromPick(pick),
            whenNull: (it) => null,
          ),
          [
            Person(name: 'John Snow'),
            Person(name: 'Daenerys Targaryen'),
            null,
          ],
        );
      });

      test('Crashes in whenNull are thrown directly', () {
        expect(
          () => pick([null]).asListOrNull(
            (pick) => Person.fromPick(pick),
            whenNull: (it) => throw 'oops',
          ),
          throwsA(isA<String>().having((e) => e, 'value', 'oops')),
        );
      });

      test('map reports item parsing errors', () {
        final data = [
          {'name': 'John Snow'},
          {'asdf': 'Daenerys Targaryen'}, // <-- missing name key
        ];
        expect(
          () => pick(data).asListOrNull((pick) => Person.fromPick(pick)),
          throwsA(
            pickException(
              containing: [
                'expected a non-null value at [1].name, but it is absent',
              ],
            ),
          ),
        );
      });
    });

    group('index in asList* items', () {
      test('index is available in lists', () {
        final entries = pick(['a', 'b', 'c']).asListOrThrow(
          (pick) => MapEntry(pick.asStringOrThrow(), pick.index),
        );
        expect(Map.fromEntries(entries), {'a': 0, 'b': 1, 'c': 2});
      });
      test('index increments for null values', () {
        final entries = pick(['a', null, null, 'b', null, 'c']).asListOrThrow(
          (pick) => MapEntry(pick.asStringOrThrow(), pick.index),
        );
        expect(Map.fromEntries(entries), {'a': 0, 'b': 3, 'c': 5});
      });
      test('whenNull has access to index', () {
        final entries = pick(['a', null, null, 'b', null, 'c']).asListOrThrow(
          (pick) => MapEntry(pick.asStringOrThrow(), pick.index),
          whenNull: (pick) => MapEntry(pick.index, pick.index! * 2),
        );
        expect(Map.fromEntries(entries), {
          'a': 0,
          1: 2,
          2: 4,
          'b': 3,
          4: 8,
          'c': 5,
        });
      });
    });
  });

  group('pick().asPlainList*', () {
    group('asPlainListOrThrow', () {
      test('returns the original items, null included', () {
        final nested = {'name': 'John Snow'};
        final result = pick(['a', 1, null, nested]).asPlainListOrThrow();
        expect(result, ['a', 1, null, nested]);
        expect(result[3], same(nested));
      });

      test('without a type it is a List<Object?>', () {
        final result = pick(['a', 1]).asPlainListOrThrow();
        // not a List<dynamic>, the type parameter falls back to its bound
        expect('${result.runtimeType}', contains('<Object?>'));
      });

      test('returns a copy', () {
        final data = ['a'];
        pick(data).asPlainListOrThrow().add('b');
        expect(data, ['a']);
      });

      test('the expected type makes it a typed list', () {
        final List<String> tags = pick(['a', 'b']).asPlainListOrThrow();
        expect(tags, isA<List<String>>());
        expect(tags, ['a', 'b']);

        final List<String?> nullable = pick(['a', null]).asPlainListOrThrow();
        expect(nullable, ['a', null]);

        final List<Map<String, dynamic>> objects = pick([
          <String, dynamic>{'name': 'John Snow'},
        ]).asPlainListOrThrow();
        expect(objects.single['name'], 'John Snow');
      });

      test('an item of another type throws and is not converted', () {
        expect(
          () => pick({
            'tags': ['a', 1],
          }, 'tags')
              .asPlainListOrThrow<String>(),
          throwsA(
            pickException(
              containing: [
                'expected an item of type String at tags[1]',
                'found   1  (an int)',
              ],
            ),
          ),
        );
      });

      test('a null item throws for a non-nullable type', () {
        expect(
          () => pick(['a', null]).asPlainListOrThrow<String>(),
          throwsA(
            pickException(
              containing: [
                'expected an item of type String at [1], but it is null',
              ],
            ),
          ),
        );
      });

      test('a broken item is redacted with the list', () {
        expect(
          () => pick(['a', 'secret']).redactValues().asPlainListOrThrow<int>(),
          throwsA(
            isA<PickException>().having(
              (e) => e.message,
              'message',
              allOf(contains('<String>'), isNot(contains('secret'))),
            ),
          ),
        );
      });

      test('null throws', () {
        expect(
          () => nullPick().asPlainListOrThrow<String>(),
          throwsA(
            pickException(
              containing: [
                'expected a non-null value at unknownKey, but it is absent',
                'Use asPlainListOrEmpty()/asPlainListOrNull() when the value may be null/absent at some point (List<String>?).',
              ],
            ),
          ),
        );
      });

      test('wrong type throws', () {
        expect(
          () => pick('Bubblegum').asPlainListOrThrow(),
          throwsA(
            pickException(
              containing: ['expected a List at <root>', 'Bubblegum'],
            ),
          ),
        );
      });

      test('leaves the context untouched', () {
        final list = pick(['a']).withContext('lang', 'de');
        list.asPlainListOrThrow();
        expect(list.context, {'lang': 'de'});
      });
    });

    group('asPlainListOrEmpty', () {
      test('pick value', () {
        expect(pick(['a', 1, null]).asPlainListOrEmpty(), ['a', 1, null]);
        final List<int> numbers = pick([1, 2]).asPlainListOrEmpty();
        expect(numbers, [1, 2]);
      });

      test('null returns empty', () {
        expect(nullPick().asPlainListOrEmpty(), isEmpty);
        expect(nullPick().asPlainListOrEmpty<String>(), isA<List<String>>());
      });

      test('wrong type returns empty', () {
        expect(pick('Bubblegum').asPlainListOrEmpty(), isEmpty);
      });

      test('an item of another type still throws', () {
        expect(
          () => pick(['a', 1]).asPlainListOrEmpty<String>(),
          throwsA(
            pickException(
              containing: ['expected an item of type String at [1]'],
            ),
          ),
        );
      });
    });

    group('asPlainListOrNull', () {
      test('pick value', () {
        expect(pick(['a', 1, null]).asPlainListOrNull(), ['a', 1, null]);
        final List<int>? numbers = pick([1, 2]).asPlainListOrNull();
        expect(numbers, [1, 2]);
      });

      test('null returns null', () {
        expect(nullPick().asPlainListOrNull(), isNull);
      });

      test('wrong type returns null', () {
        expect(pick('Bubblegum').asPlainListOrNull(), isNull);
      });

      test('an item of another type still throws', () {
        expect(
          () => pick(['a', 1]).asPlainListOrNull<String>(),
          throwsA(
            pickException(
              containing: ['expected an item of type String at [1]'],
            ),
          ),
        );
      });
    });
  });

  group('pick().asMapList*', () {
    group('typed entry validation', () {
      final converters = <String, List<Map<int, String>>? Function(Pick)>{
        'OrThrow': (it) => it.asMapListOrThrow<int, String>(),
        'OrEmpty': (it) => it.asMapListOrEmpty<int, String>(),
        'OrNull': (it) => it.asMapListOrNull<int, String>(),
      };
      for (final entry in converters.entries) {
        group(entry.key, () {
          test('rejects an invalid key during extraction', () {
            final data = <Map<Object?, Object?>>[
              {1: 'valid'},
              {'invalid': 'value'},
            ];
            expect(data[1].keys.single, isNot(isA<int>()));
            expect(data[1].values.single, isA<String>());

            expect(() => entry.value(pick(data)), throwsA(isA<TypeError>()));
          });

          test('rejects an invalid value during extraction', () {
            final data = <Map<Object?, Object?>>[
              {1: 'valid'},
              {2: 42},
            ];
            expect(data[1].keys.single, isA<int>());
            expect(data[1].values.single, isNot(isA<String>()));

            expect(() => entry.value(pick(data)), throwsA(isA<TypeError>()));
          });
        });
      }

      final nullableConverters =
          <String, List<Map<int, String?>>? Function(Pick)>{
        'OrThrow': (it) => it.asMapListOrThrow<int, String?>(),
        'OrEmpty': (it) => it.asMapListOrEmpty<int, String?>(),
        'OrNull': (it) => it.asMapListOrNull<int, String?>(),
      };
      for (final entry in nullableConverters.entries) {
        test('${entry.key} retains allowed null values', () {
          final data = <Map<Object?, Object?>>[
            {1: null, 2: 'valid'},
          ];
          expect(data.single.containsKey(1), isTrue);
          expect(data.single[1], isNull);

          expect(entry.value(pick(data)), [
            <int, String?>{1: null, 2: 'valid'},
          ]);
        });
      }
    });

    group('asMapListOrThrow', () {
      test('returns the maps of the list', () {
        final data = [
          {'name': 'John Snow'},
          {1: 'one', 2: 'two'},
        ];
        expect(pick(data).asMapListOrThrow(), data);
      });

      test('typed keys and values', () {
        final dynamic data = [
          {1: 'gold', 2: 'silver'},
          {1: 'bronze'},
        ];
        final List<Map<int, String>> maps =
            pick(data).asMapListOrThrow<int, String>();
        expect(maps, [
          {1: 'gold', 2: 'silver'},
          {1: 'bronze'},
        ]);
      });

      test('ignores null items', () {
        final data = [
          {'a': 1},
          null,
          {'b': 2},
        ];
        expect(pick(data).asMapListOrThrow(), [
          {'a': 1},
          {'b': 2},
        ]);
      });

      test('null throws', () {
        expect(
          () => nullPick().asMapListOrThrow<String, int>(),
          throwsA(
            pickException(
              containing: [
                'expected a non-null value at unknownKey, but it is absent',
                'Use asMapListOrEmpty()/asMapListOrNull() when the value may be null/absent at some point (List<Map<String, int>>?).',
              ],
            ),
          ),
        );
      });

      test('wrong type throws', () {
        expect(
          () => pick('Bubblegum').asMapListOrThrow(),
          throwsA(pickException(containing: ['expected a List at <root>'])),
        );
      });

      test('item that is not a Map throws', () {
        final data = {
          'shoes': [
            {'id': 1},
            'Bubblegum',
          ],
        };
        expect(
          () => pick(data, 'shoes').asMapListOrThrow(),
          throwsA(
            pickException(
              containing: [
                'expected a Map at shoes[1]',
                'Bubblegum',
                '(a String)',
              ],
            ),
          ),
        );
      });
    });

    group('asMapListOrEmpty', () {
      test('pick value', () {
        expect(
          pick([
            {'a': 1},
          ]).asMapListOrEmpty(),
          [
            {'a': 1},
          ],
        );
      });

      test('null returns empty', () {
        expect(nullPick().asMapListOrEmpty(), isEmpty);
      });

      test('wrong type returns empty', () {
        expect(pick(Object()).asMapListOrEmpty(), isEmpty);
      });

      test('item that is not a Map throws', () {
        expect(
          () => pick([1]).asMapListOrEmpty(),
          throwsA(pickException(containing: ['expected a Map at [0]'])),
        );
      });
    });

    group('asMapListOrNull', () {
      test('pick value', () {
        expect(
          pick([
            {'a': 1},
          ]).asMapListOrNull(),
          [
            {'a': 1},
          ],
        );
      });

      test('null returns null', () {
        expect(nullPick().asMapListOrNull(), isNull);
      });

      test('wrong type returns null', () {
        expect(pick(Object()).asMapListOrNull(), isNull);
      });

      test('item that is not a Map throws', () {
        expect(
          () => pick([1]).asMapListOrNull(),
          throwsA(pickException(containing: ['expected a Map at [0]'])),
        );
      });
    });
  });

  group('pick().asJsonObjectList*', () {
    group('asJsonObjectListOrThrow', () {
      test('can be mapped with a fromJson function', () {
        // no constructor tear-off, the package supports Dart 2.12
        final dynamic data = {
          'users': [
            {'name': 'John Snow'},
            {'name': 'Daenerys Targaryen'},
          ],
        };
        final users = pick(data, 'users')
            .asJsonObjectListOrThrow()
            .map((json) => _User.fromJson(json))
            .toList();
        expect(users.map((it) => it.name), ['John Snow', 'Daenerys Targaryen']);
      });

      test('ignores entries with non-String keys', () {
        final data = [
          {'a': 1, 2: 'two'},
          {3: 'three'},
        ];
        expect(pick(data).asJsonObjectListOrThrow(), [
          {'a': 1},
          <String, Object?>{},
        ]);
      });

      test('ignores null items', () {
        final data = [
          {'a': 1},
          null,
          {'b': 2},
        ];
        expect(pick(data).asJsonObjectListOrThrow(), [
          {'a': 1},
          {'b': 2},
        ]);
      });

      test('null throws', () {
        expect(
          () => nullPick().asJsonObjectListOrThrow(),
          throwsA(
            pickException(
              containing: [
                'expected a non-null value at unknownKey, but it is absent',
                'Use asJsonObjectListOrEmpty()/asJsonObjectListOrNull() when the value may be null/absent at some point (List<Map<String, Object?>>?).',
              ],
            ),
          ),
        );
      });

      test('wrong type throws', () {
        expect(
          () => pick('Bubblegum').asJsonObjectListOrThrow(),
          throwsA(pickException(containing: ['expected a List at <root>'])),
        );
      });

      test('item that is not a Map throws', () {
        final data = {
          'shoes': [
            {'id': 1},
            'Bubblegum',
          ],
        };
        expect(
          () => pick(data, 'shoes').asJsonObjectListOrThrow(),
          throwsA(
            pickException(
              containing: [
                'expected a Map at shoes[1]',
                'Bubblegum',
                '(a String)',
              ],
            ),
          ),
        );
      });
    });

    group('asJsonObjectListOrEmpty', () {
      test('pick value', () {
        expect(
          pick([
            {'a': 1, 2: 'two'},
          ]).asJsonObjectListOrEmpty(),
          [
            {'a': 1},
          ],
        );
      });

      test('null returns empty', () {
        expect(nullPick().asJsonObjectListOrEmpty(), isEmpty);
      });

      test('wrong type returns empty', () {
        expect(pick(Object()).asJsonObjectListOrEmpty(), isEmpty);
      });

      test('item that is not a Map throws', () {
        expect(
          () => pick([1]).asJsonObjectListOrEmpty(),
          throwsA(pickException(containing: ['expected a Map at [0]'])),
        );
      });
    });

    group('asJsonObjectListOrNull', () {
      test('pick value', () {
        expect(
          pick([
            {'a': 1, 2: 'two'},
          ]).asJsonObjectListOrNull(),
          [
            {'a': 1},
          ],
        );
      });

      test('null returns null', () {
        expect(nullPick().asJsonObjectListOrNull(), isNull);
      });

      test('wrong type returns null', () {
        expect(pick(Object()).asJsonObjectListOrNull(), isNull);
      });

      test('item that is not a Map throws', () {
        expect(
          () => pick([1]).asJsonObjectListOrNull(),
          throwsA(pickException(containing: ['expected a Map at [0]'])),
        );
      });
    });
  });
}

class _User {
  _User.fromJson(Map<String, dynamic> json) : name = json['name'] as String;

  final String name;
}
