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
        'name': {'first': 'John', 'last': 'Snow'}
      };
      final p = pick(data, 'name', 'first');
      expect(p.value, 'John');
      expect(p.path, ['name', 'first']);
    });

    test('ignores null args', () {
      final data = {
        'name': {'first': 'John', 'last': 'Snow'}
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
        'name': {'first': 'John', 'last': 'Snow'}
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
              'Expected a non-null value but location picked value "null" using pick(<root>) is null',
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
                'Expected a non-null value but location picked value "null" using pick(json, 0 (null)) is null',
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
                'Expected a non-null value but location "some" in pick(json, "some" (absent), "path") is absent',
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
                'Expected a non-null value but location "some" in pick(json, "some" (absent), "path") is absent.',
              ),
            ),
          ),
        );
      });
    });

    test('toString() prints value and path', () {
      expect(
        // ignore: deprecated_member_use_from_same_package
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
            allOf(contains('[set]'), contains('Set'), contains('index (0)')),
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
          'a': {'b': 1}
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
        {'lang': 'de'}
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
