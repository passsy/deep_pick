import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

void main() {
  group('Pick', () {
    test('null pick carries full location', () {
      final p = pick(null, 'some', 'path');
      expect(p.fullPath, ['some', 'path']);
      expect(p.value, null);
    });

    test('required pick from null show good error message', () {
      expect(
          () => pick(null).required(),
          throwsA(isA<PickException>().having(
            (e) => e.message,
            'message',
            contains(
                'required value at location "<root>" in pick(<root>) is null'),
          )));
    });

    test('pick null but require - show good error message', () {
      expect(
          () => pick([null], 0).required(),
          throwsA(isA<PickException>().having(
            (e) => e.message,
            'message',
            contains(
                'required value at location list index 0 in pick(json, 0 (null)) is null'),
          )));
    });

    test('required pick from null with args show good error message', () {
      expect(
          () => pick(null, 'some', 'path').required(),
          throwsA(isA<PickException>().having(
            (e) => e.message,
            'message',
            contains(
                'required value at location "some" in pick(json, "some" (absent), "path") is absent'),
          )));
    });

    test('not matching required pick show good error message', () {
      expect(
          () => pick('a', 'some', 'path').required(),
          throwsA(isA<PickException>().having(
            (e) => e.message,
            'message',
            contains(
                'required value at location "some" in pick(json, "some" (absent), "path") is absent'),
          )));
    });

    test('toString() prints value and path', () {
      expect(
          // ignore: deprecated_member_use_from_same_package
          Pick('a', fullPath: ['b', 0]).toString(),
          'Pick(value=a, path=[b, 0])');
    });

    test(
        'picking from sets by index is illegal '
        'because to order is not guaranteed', () {
      final data = {
        'set': {'a', 'b', 'c'},
      };
      expect(
        () => pick(data, 'set', 0),
        throwsA(isA<PickException>().having((e) => e.toString(), 'toString',
            allOf(contains('[set]'), contains('Set'), contains('index (0)')))),
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
      expect(p.fullPath, ['a', 'b']);
      expect(p.value, isNull);
    });

    test('call() carries over the location for good stacktraces', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];

      final level1Pick = pick(data, 0);
      expect(level1Pick.fullPath, [0]);

      final level2Pick = level1Pick.call('name');
      expect(level2Pick.fullPath, [0, 'name']);
    });

    group('isAbsent()', () {
      test('is not absent because value', () {
        final p = pick('a');
        expect(p.value, isNotNull);
        expect(p.isAbsent(), isFalse);
        expect(p.missingValueAtIndex, null);
      });

      test('is not absent but null', () {
        final p = pick(null);
        expect(p.value, isNull);
        expect(p.isAbsent(), isFalse);
        expect(p.missingValueAtIndex, null);
      });

      test('is not absent but null further down', () {
        final p = pick({'a': null}, 'a');
        expect(p.value, isNull);
        expect(p.isAbsent(), isFalse);
        expect(p.missingValueAtIndex, null);
      });

      test('is not absent, not null', () {
        final p = pick({'a', 1}, 'b');
        expect(p.value, isNull);
        expect(p.isAbsent(), isTrue);
        expect(p.missingValueAtIndex, 0);
      });

      test('is not absent, not null, further down', () {
        final json = {
          'a': {'b': 1}
        };
        final p = pick(json, 'a', 'x' /*absent*/);
        expect(p.value, isNull);
        expect(p.isAbsent(), isTrue);
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
      expect(pick(data, 10).isAbsent(), true);
    });

    test('unknown property in map returns null', () {
      final data = {'name': 'John Snow'};
      expect(pick(data, 'birthday').value, isNull);
      expect(pick(data, 'birthday').isAbsent(), true);
    });

    test('documentation example Map', () {
      final pa = pick({'a': null}, 'a');
      expect(pa.value, isNull);
      expect(pa.isAbsent(), false);

      final pb = pick({'a': null}, 'b');
      expect(pb.value, isNull);
      expect(pb.isAbsent(), true);
    });

    test('documentation example List', () {
      final p0 = pick([null], 0);
      expect(p0.value, isNull);
      expect(p0.isAbsent(), false);

      final p2 = pick([], 2);
      expect(p2.value, isNull);
      expect(p2.isAbsent(), true);
    });

    test('Map key for list', () {
      final p = pick([], 'a');
      expect(p.value, isNull);
      expect(p.isAbsent(), true);
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

    test('add and read from context with syntax sugar (deprecated)', () {
      // ignore: deprecated_member_use_from_same_package
      final root = pick([]).addContext('lang', 'de');
      expect(root.fromContext('lang').asStringOrNull(), 'de');
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

  factory Person.fromJson(RequiredPick pick) {
    return Person(
      name: pick('name').required().asString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}
