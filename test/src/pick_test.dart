// ignore_for_file: unreachable_from_main, deprecated_member_use_from_same_package

import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

void main() {
  group('pick', () {
    test('pick a value with one arg', () {
      final data = {'name': 'John Snow'};
      final p = pick(data, 'name');
      expect(p.value, 'John Snow');
      expect(p.path, ['name']);
    });

    test('pick a value with two args', () {
      final data = {
        'name': {'first': 'John', 'last': 'Snow'},
      };
      final p = pick(data, 'name', 'first');
      expect(p.value, 'John');
      expect(p.path, ['name', 'first']);
    });

    test('ignores null args', () {
      final data = {
        'name': {'first': 'John', 'last': 'Snow'},
      };
      // Probably nobody is using it that way. It's a byproduct of faking varargs.
      // But it is the public API and shouldn't break
      final p = pick(data, null, 'name', null, 'first');
      expect(p.value, 'John');
      expect(p.path, ['name', 'first']);
    });
  });

  group('pickDeep', () {
    test('pickDeep a value with one arg', () {
      final data = {'name': 'John Snow'};
      final p = pickDeep(data, ['name']);
      expect(p.value, 'John Snow');
      expect(p.path, ['name']);
    });

    test('pickDeep a value with two args', () {
      final data = {
        'name': {'first': 'John', 'last': 'Snow'},
      };
      final p = pickDeep(data, ['name', 'first']);
      expect(p.value, 'John');
      expect(p.path, ['name', 'first']);
    });
  });

  group('pickFromJson', () {
    test('pick a value with one arg', () {
      const json = '{"name": "John Snow"}';
      final p = pickFromJson(json, 'name');
      expect(p.value, 'John Snow');
      expect(p.path, ['name']);
    });

    test('pick a value with two args', () {
      const json = '{"name": {"first": "John", "last": "Snow"}}';
      final p = pickFromJson(json, 'name', 'first');
      expect(p.value, 'John');
      expect(p.path, ['name', 'first']);
    });

    test('parse empty string', () {
      expect(
        () => pickFromJson('', 'name'),
        throwsA(
          isA<FormatException>()
              .having((it) => it.message, 'message', 'Unexpected end of input'),
        ),
      );
    });

    test('has to start with object {} or list []', () {
      pickFromJson('{}');
      pickFromJson('[]');
      expect(
        () => pickFromJson('someValue'),
        throwsA(
          isA<FormatException>()
              .having((it) => it.message, 'message', 'Unexpected character'),
        ),
      );
    });

    test('ignores null args', () {
      const json = '{"name": {"first": "John", "last": "Snow"}}';
      // Probably nobody is using it that way. It's a byproduct of faking varargs.
      // But it is the public API and shouldn't break
      final p = pickFromJson(json, null, 'name', null, 'first');
      expect(p.value, 'John');
      expect(p.path, ['name', 'first']);
    });
  });

  group('Pick', () {
    test('null pick carries full location', () {
      final p = pick(null, 'some', 'path');
      expect(p.path, ['some', 'path']);
      expect(p.value, null);
    });

    test('required pick from null show good error message', () {
      expect(
        () => pick(null).required(),
        throwsA(
          isA<PickException>().having(
            (e) => e.message,
            'message',
            contains(
              'expected a non-null value at <root>, but it is null',
            ),
          ),
        ),
      );
    });

    group('location', () {
      test('root with value', () {
        expect(
          pick('a').debugParsingExit,
          'picked value "a" using pick(<root>)',
        );
      });
      test('root with null', () {
        expect(
          pick(null).debugParsingExit,
          'picked value "null" using pick(<root>)',
        );
      });

      test('absent in map', () {
        expect(
          pick({'a': 1}, 'b').debugParsingExit,
          '"b" in pick(json, "b" (absent))',
        );
      });
      test('null in map', () {
        expect(
          pick({'a': null}, 'a').debugParsingExit,
          'picked value "null" using pick(json, "a" (null))',
        );
      });
      test('value in map', () {
        expect(
          pick({'a': 'b'}, 'a').debugParsingExit,
          'picked value "b" using pick(json, "a"(b))',
        );
      });

      test('long path', () {
        expect(
          pick({'a': 'b'}, 'a', 'b', 'c', 'd').debugParsingExit,
          '"b" in pick(json, "a", "b" (absent), "c", "d")',
        );
      });
    });

    group('required', () {
      test('pick null but require - show good error message', () {
        expect(
          () => pick([null], 0).required(),
          throwsA(
            isA<PickException>().having(
              (e) => e.message,
              'message',
              contains(
                'expected a non-null value at [0], but it is null',
              ),
            ),
          ),
        );
      });

      test('required pick from null with args show good error message', () {
        expect(
          () => pick(null, 'some', 'path').required(),
          throwsA(
            isA<PickException>().having(
              (e) => e.message,
              'message',
              contains(
                'expected a non-null value at some.path, but it is absent',
              ),
            ),
          ),
        );
      });

      test('not matching required pick show good error message', () {
        expect(
          () => pick('a', 'some', 'path').required(),
          throwsA(
            isA<PickException>().having(
              (e) => e.message,
              'message',
              contains(
                'expected a non-null value at some.path, but it is absent',
              ),
            ),
          ),
        );
      });
    });

    test('toString() prints value and path', () {
      expect(
        Pick('a', path: ['b', 0]).toString(),
        'Pick(value=a, path=[b, 0])',
      );
    });

    test(
        'picking from sets by index is illegal '
        'because to order is not guaranteed', () {
      final data = {
        'set': {'a', 'b', 'c'},
      };
      expect(
        () => pick(data, 'set', 0),
        throwsA(
          isA<PickException>().having(
            (e) => e.toString(),
            'toString',
            allOf(
              contains('cannot pick by index at set[0], it is a Set'),
              contains('a Set is unordered'),
            ),
          ),
        ),
      );
    });

    test('call()', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];

      final first = pick(data, 0);
      expect(first.value, {'name': 'John Snow'});

      // pick further
      expect(first.call('name').asStringOrThrow(), 'John Snow');
    });

    test('pick deeper than data structure returns null pick', () {
      final p = pick([], 'a', 'b');
      expect(p.path, ['a', 'b']);
      expect(p.value, isNull);
    });

    test('call() carries over the location for good stacktraces', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];

      final level1Pick = pick(data, 0);
      expect(level1Pick.path, [0]);

      final level2Pick = level1Pick.call('name');
      expect(level2Pick.path, [0, 'name']);
    });

    group('isAbsent', () {
      test('is not absent because value', () {
        final p = pick('a');
        expect(p.value, isNotNull);
        expect(p.isAbsent, isFalse);
        expect(p.missingValueAtIndex, null);
      });

      test('is not absent but null', () {
        final p = pick(null);
        expect(p.value, isNull);
        expect(p.isAbsent, isFalse);
        expect(p.missingValueAtIndex, null);
      });

      test('is not absent but null further down', () {
        final p = pick({'a': null}, 'a');
        expect(p.value, isNull);
        expect(p.isAbsent, isFalse);
        expect(p.missingValueAtIndex, null);
      });

      test('is not absent, not null', () {
        final p = pick({'a', 1}, 'b');
        expect(p.value, isNull);
        expect(p.isAbsent, isTrue);
        expect(p.missingValueAtIndex, 0);
      });

      test('is not absent, not null, further down', () {
        final json = {
          'a': {'b': 1},
        };
        final p = pick(json, 'a', 'x' /*absent*/);
        expect(p.value, isNull);
        expect(p.isAbsent, isTrue);
        expect(p.missingValueAtIndex, 1);
      });
    });
  });

  group('isAbsent', () {
    test('out of range in list returns null pick', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];
      expect(pick(data, 10).value, isNull);
      expect(pick(data, 10).isAbsent, true);
    });

    test('unknown property in map returns null', () {
      final data = {'name': 'John Snow'};
      expect(pick(data, 'birthday').value, isNull);
      expect(pick(data, 'birthday').isAbsent, true);
    });

    test('documentation example Map', () {
      final pa = pick({'a': null}, 'a');
      expect(pa.value, isNull);
      expect(pa.isAbsent, false);

      final pb = pick({'a': null}, 'b');
      expect(pb.value, isNull);
      expect(pb.isAbsent, true);
    });

    test('documentation example List', () {
      final p0 = pick([null], 0);
      expect(p0.value, isNull);
      expect(p0.isAbsent, false);

      final p2 = pick([], 2);
      expect(p2.value, isNull);
      expect(p2.isAbsent, true);
    });

    test('Map key for list', () {
      final p = pick([], 'a');
      expect(p.value, isNull);
      expect(p.isAbsent, true);
    });
  });

  // The absent marker has to sit on the path segment where drilling down
  // actually stopped. missingValueAtIndex is an index into path and
  // followablePath derives from it, so all three have to agree.
  group('absent location survives chained picks', () {
    final json = {
      'a': {'b': 1},
      'list': [
        {'name': 'John'},
      ],
    };

    test('missing key one level below a chained pick', () {
      final chained = pick(json, 'a')('x');
      final direct = pick(json, 'a', 'x');

      // both describe the very same location and must not disagree
      expect(chained.path, direct.path);
      expect(chained.missingValueAtIndex, direct.missingValueAtIndex);
      expect(chained.followablePath, direct.followablePath);
      expect(chained.debugParsingExit, direct.debugParsingExit);

      expect(chained.missingValueAtIndex, 1);
      expect(chained.followablePath, ['a']);
      expect(
        chained.debugParsingExit,
        '"x" in pick(json, "a", "x" (absent))',
      );
    });

    test('missing key two levels below a chained pick', () {
      final chained = pick(json, 'a')('b')('c');

      expect(chained.path, ['a', 'b', 'c']);
      expect(chained.missingValueAtIndex, 2);
      expect(chained.followablePath, ['a', 'b']);
      expect(
        chained.debugParsingExit,
        '"c" in pick(json, "a", "b", "c" (absent))',
      );
    });

    test('index out of range below a chained pick', () {
      final chained = pick(json, 'list')(5);

      expect(chained.missingValueAtIndex, 1);
      expect(chained.followablePath, ['list']);
      expect(
        chained.debugParsingExit,
        'list index 5 in pick(json, "list", 5 (absent))',
      );
    });

    test('pickDeep continued via call()', () {
      final chained = pickDeep(json, ['a'])('b', 'c');

      expect(chained.missingValueAtIndex, 2);
      expect(chained.followablePath, ['a', 'b']);
    });

    test('required() reports the segment that could not be followed', () {
      expect(
        () => pick(json, 'a')('x').required(),
        throwsA(pickException(containing: [
          'expected a non-null value at a.x, but it is absent'
        ])),
      );
    });

    test('missing key inside a asListOrThrow element', () {
      // the list exists, only "nope" inside the element is missing
      expect(
        () {
          pick(json, 'list')
              .asListOrThrow((it) => it('nope').required().asString());
        },
        throwsA(pickException(containing: [
          'expected a non-null value at list[0].nope, but it is absent'
        ])),
      );
    });

    test('picking by index from a Set reports the full location', () {
      final data = {
        'deep': {
          'set': {'a', 'b', 'c'},
        },
      };
      expect(
        () => pick(data, 'deep')('set', 0),
        throwsA(pickException(
            containing: ['cannot pick by index at deep.set[0], it is a Set'])),
      );
    });
  });

  group('a null on the way down stops the path there', () {
    test('null value with further selectors is absent at the null', () {
      final p = pick({'a': null}, 'a', 'b');

      expect(p.value, isNull);
      expect(p.isAbsent, isTrue);
      expect(p.missingValueAtIndex, 1);
      expect(p.followablePath, ['a']);
      expect(p.debugParsingExit, '"b" in pick(json, "a", "b" (absent))');
    });

    test('null list element with further selectors is absent at the null', () {
      final p = pick([null], 0, 'x');

      expect(p.isAbsent, isTrue);
      expect(p.missingValueAtIndex, 1);
      expect(p.followablePath, [0]);
      expect(p.debugParsingExit, '"x" in pick(json, 0, "x" (absent))');
    });

    test('null as the last segment stays a non-absent null', () {
      // documented behaviour, must not change
      expect(pick({'a': null}, 'a').isAbsent, isFalse);
      expect(pick([null], 0).isAbsent, isFalse);
      expect(
        pick({'a': null}, 'a').debugParsingExit,
        'picked value "null" using pick(json, "a" (null))',
      );
    });
  });

  group('continuing an already absent pick', () {
    final cases = <String, List<Object?>>{
      'missing map key': [
        {'a': <String, Object?>{}},
        'a',
        'missing',
        'child'
      ],
      'missing list index': [
        {'a': <Object?>[]},
        'a',
        2,
        'child'
      ],
      'null intermediate value': [
        {'a': null},
        'a',
        'missing',
        'child'
      ],
    };
    for (final entry in cases.entries) {
      test(entry.key, () {
        final input = entry.value;
        final direct = pick(input[0], input[1], input[2], input[3]);
        final chained = pick(input[0], input[1])(input[2])(input[3]);
        expect(chained.path, direct.path);
        expect(chained.missingValueAtIndex, direct.missingValueAtIndex);
        expect(chained.followablePath, direct.followablePath);
        expect(_requiredError(chained), _requiredError(direct));
        expect(chained.debugParsingExit, direct.debugParsingExit);
      });
    }

    test('empty call preserves the original absent state', () {
      final missing = pick(<String, Object?>{}, 'missing');
      final continued = missing();
      expect(continued.isAbsent, isTrue);
      expect(continued.path, missing.path);
      expect(continued.missingValueAtIndex, missing.missingValueAtIndex);
      expect(_requiredError(continued), _requiredError(missing));
    });

    test('the original missing node and redaction survive continuation', () {
      final root = pick({'secret': 'PRIVATE'}).redactValues();
      final missing = root('missing');
      final continued = missing('child');
      expect(
        () => continued.required(),
        throwsA(isA<PickException>()
            .having((e) => e.message, 'message', contains('missing.child'))
            .having((e) => e.message, 'message', contains('no such key'))
            // the root map is still the value the error shows
            .having((e) => e.message, 'message', contains('secret'))
            .having((e) => e.message, 'message', isNot(contains('PRIVATE')))),
      );
    });
  });

  group('every spelling of a path reports the same', () {
    final datas = <Object?>[
      {
        'a': {
          'b': {'c': 1, 'n': null},
          'l': [
            1,
            null,
            {'x': 2},
          ],
        },
        'n': null,
        's': 'str',
      },
      [
        null,
        [1, 2],
        {'k': null},
      ],
      null,
      'scalar',
    ];
    final paths = <List<Object>>[
      ['a', 'b', 'c'],
      ['a', 'b', 'c', 'd'],
      ['a', 'b', 'n'],
      ['a', 'b', 'n', 'x', 'y'],
      ['a', 'l', 1],
      ['a', 'l', 1, 'x'],
      ['a', 'l', 2, 'x'],
      ['a', 'l', 5, 'x'],
      ['a', 'l', 'x'],
      ['n'],
      ['n', 'x', 'y'],
      ['s', 'x'],
      ['s', 0],
      ['zz', 'y', 'z'],
      [0],
      [0, 'x'],
      [1, 5],
      [2, 'k', 'z'],
      [9, 9],
      [],
    ];

    // everything a caller can observe about where a pick ended
    String describe(Pick pick) {
      final error = () {
        try {
          pick.required();
          return 'no error';
        } on PickException catch (e) {
          return e.message;
        }
      }();
      return 'isAbsent=${pick.isAbsent} '
          'missingValueAtIndex=${pick.missingValueAtIndex} '
          'followablePath=${pick.followablePath} path=${pick.path} '
          'value=${pick.value}\n'
          '$error';
    }

    Pick continued(Pick pick, List<Object> selectors) {
      Object? at(int i) => i < selectors.length ? selectors[i] : null;
      return pick(at(0), at(1), at(2), at(3), at(4));
    }

    for (var d = 0; d < datas.length; d++) {
      for (final path in paths) {
        test('data $d, path $path', () {
          final data = datas[d];
          final direct = describe(pickDeep(data, path));
          // every way to split the path over up to three calls, followed by
          // an empty call
          for (var i = 0; i <= path.length; i++) {
            for (var j = i; j <= path.length; j++) {
              final first = pickDeep(data, path.sublist(0, i));
              final second = continued(first, path.sublist(i, j));
              final third = continued(second, path.sublist(j));
              expect(
                describe(third()),
                direct,
                reason: 'split at $i and $j',
              );
            }
          }
        });
      }
    }

    test('a list element callback reports like a direct pick', () {
      final data = {
        'list': [
          {'name': 'John'},
        ],
      };
      final direct = pick(data, 'list', 0, 'nope');
      Pick? inCallback;
      pick(data, 'list').asListOrThrow((it) {
        inCallback = it('nope');
        return 0;
      });
      expect(describe(inCallback!), describe(direct));
    });
  });

  group('context API', () {
    test('add and read from context', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];
      final root = pick(data);
      root.context['lang'] = 'de';
      expect(root.context, {'lang': 'de'});
    });

    test('read from deep nested context', () {
      final root = pick([]).withContext('user', {'id': '1234'});
      expect(root.fromContext('user', 'id').asStringOrNull(), '1234');
    });

    test('copy into required()', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];
      final root = pick(data);
      root.context['lang'] = 'de';
      expect(root.context, {'lang': 'de'});

      final requiredPick = root.required();
      expect(requiredPick.context, {'lang': 'de'});

      root.context['hello'] = 'world';
      expect(root.context, {'lang': 'de', 'hello': 'world'});
      expect(requiredPick.context, {'lang': 'de'});
    });

    test('copy into asList()', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];
      final root = pick(data);
      root.context['lang'] = 'de';
      expect(root.context, {'lang': 'de'});

      final contexts = root.asListOrNull((pick) => pick.context);
      expect(contexts, [
        {'lang': 'de'},
        {'lang': 'de'},
      ]);
    });

    test('copy into call() pick', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];
      final root = pick(data);
      root.context['lang'] = 'de';
      expect(root.context, {'lang': 'de'});

      final afterCall = root.call(1, 'name');
      expect(afterCall.context, {'lang': 'de'});

      root.context['hello'] = 'world';
      expect(root.context, {'lang': 'de', 'hello': 'world'});
      expect(afterCall.context, {'lang': 'de'});
    });

    group('index', () {
      test('index is available in lists', () {
        final picked0 = pick(['a', 'b', 'c'], 0);
        expect(picked0.index, 0);
        expect(picked0.value, 'a');

        final picked1 = pick(['a', 'b', 'c'], 1);
        expect(picked1.index, 1);
        expect(picked1.value, 'b');

        final picked2 = pick(['a', 'b', 'c'], 2);
        expect(picked2.index, 2);
        expect(picked2.value, 'c');
      });
      test('index increments for null values', () {
        final picked = pick(['a', null, 'c'], 1);
        expect(picked.index, 1);
        expect(picked.value, null);
      });
      test('no index for maps', () {
        expect(pick({'a': 'apple', 'b': 'beer'}, 'a').index, isNull);
      });
    });
  });
}

Pick nullPick() {
  return pick(<String, dynamic>{}, 'unknownKey');
}

Matcher pickException({required List<String> containing}) {
  return const TypeMatcher<PickException>()
      .having((e) => e.message, 'message', stringContainsInOrder(containing));
}

class Person {
  final String name;

  Person({required this.name});

  factory Person.fromPick(RequiredPick pick) {
    return Person(
      name: pick('name').required().asStringOrThrow(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

/// The message [pick] fails with when it is required, `null` when it holds a
/// value. For an absent pick it shows the data at the place the path broke.
String? _requiredError(Pick pick) {
  try {
    pick.required();
    return null;
  } on PickException catch (e) {
    return e.message;
  }
}
