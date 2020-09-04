// ignore_for_file: deprecated_member_use_from_same_package
import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

void main() {
  group('Pick', () {
    test('pick from null returns null Pick with full location', () {
      final p = pick(null, 'some', 'path');
      expect(p.path, ['some', 'path']);
      expect(p.value, null);
    });

    test('toString() prints value and path', () {
      // ignore: deprecated_member_use_from_same_package
      expect(
          Pick('a', path: ['b', 0]).toString(), 'Pick(value=a, path=[b, 0])');
    });

    test(
        'picking from sets by index is illegal '
        'because to order is not guaranteed', () {
      final data = {
        'set': {'a', 'b', 'c'},
      };
      expect(
          () => pick(data, 'set', 0),
          throwsA(isA<PickException>().having(
              (e) => e.toString(),
              'toString',
              allOf(
                  contains('[set]'), contains('Set'), contains('index (0)')))));
    });

    test('call()', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];

      final picked = pick(data, 0);
      expect(picked.value, {'name': 'John Snow'});

      // pick further
      expect(picked.call('name').required().asString(), 'John Snow');
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
  });

  group('parsing', () {
    test('asStringOrNull()', () {
      expect(picked('adam').asStringOrNull(), 'adam');
      expect(picked(1).asStringOrNull(), '1');
      expect(
          picked(DateTime(2000)).asStringOrNull(), '2000-01-01 00:00:00.000');
      expect(nullPick().asStringOrNull(), isNull);
    });

    test('asMapOrNull()', () {
      expect(picked({'ab': 'cd'}).asMapOrNull(), {'ab': 'cd'});
      expect(picked(1).asMapOrNull(), isNull);
      expect(nullPick().asMapOrNull(), isNull);
    });

    test('asMapOrNull() reports errors correctly', () {
      final dynamic data = {
        'a': {'some': 'value'}
      };

      try {
        final parsed = picked(data).asMapOrNull<String, bool>();
        fail('casted map without verifying the types. '
            'Expected Map<String, bool> but was ${parsed.runtimeType}');
        // ignore: avoid_catching_errors
      } on TypeError catch (e) {
        expect(
          e,
          const TypeMatcher<TypeError>().having(
            (e) => e.toString(),
            'message',
            stringContainsInOrder(
                ['<String, String>', 'is not a subtype of type', 'bool']),
          ),
        );
        // ignore: avoid_catching_errors, deprecated_member_use
      } on CastError catch (e) {
        // backwards compatibility for Dart 2.7
        // CastError was replaced with TypeError in Dart 2.8
        expect(
          e,
          // ignore: deprecated_member_use
          const TypeMatcher<CastError>().having(
            (e) => e.toString(),
            'message',
            stringContainsInOrder(
                ['<String, String>', 'is not a subtype of type', 'bool']),
          ),
        );
      }
    });

    test('asMapOrEmpty()', () {
      expect(picked({'ab': 'cd'}).asMapOrEmpty(), {'ab': 'cd'});
      expect(picked('a').asMapOrEmpty(), {});
      expect(nullPick().asMapOrEmpty(), {});
    });

    test('asMapOrEmpty() reports errors correctly', () {
      final dynamic data = {
        'a': {'some': 'value'}
      };

      try {
        final parsed = picked(data).asMapOrEmpty<String, bool>();
        fail('casted map without verifying the types. '
            'Expected Map<String, bool> but was ${parsed.runtimeType}');
        // ignore: avoid_catching_errors
      } on TypeError catch (e) {
        expect(
          e,
          const TypeMatcher<TypeError>().having(
            (e) => e.toString(),
            'message',
            stringContainsInOrder(
                ['<String, String>', 'is not a subtype of type', 'bool']),
          ),
        );
        // ignore: avoid_catching_errors, deprecated_member_use
      } on CastError catch (e) {
        // backwards compatibility for Dart 2.7
        // CastError was replaced with TypeError in Dart 2.8
        expect(
          e,
          // ignore: deprecated_member_use
          const TypeMatcher<CastError>().having(
            (e) => e.toString(),
            'message',
            stringContainsInOrder(
                ['<String, String>', 'is not a subtype of type', 'bool']),
          ),
        );
      }
    });

    test('asListOrNull()', () {
      expect(picked([1, 2, 3]).asListOrNull<int>(), [1, 2, 3]);
      expect(picked('john').asListOrNull<int>(), isNull);
      expect(nullPick().asListOrNull<int>(), isNull);
    });

    test('asListOrEmpty()', () {
      expect(picked([1, 2, 3]).asListOrEmpty<int>(), [1, 2, 3]);
      expect(picked('a').asListOrEmpty<int>(), []);
      expect(nullPick().asListOrEmpty<int>(), []);
    });

    test('asBoolOrNull()', () {
      expect(picked(true).asBoolOrNull(), isTrue);
      expect(picked('a').asBoolOrNull(), isNull);
      expect(nullPick().asBoolOrNull(), isNull);
    });

    test('asBoolOrTrue()', () {
      expect(picked(true).asBoolOrTrue(), isTrue);
      expect(picked(false).asBoolOrTrue(), isFalse);
      expect(picked('a').asBoolOrTrue(), isTrue);
      expect(nullPick().asBoolOrTrue(), isTrue);
    });

    test('asBoolOrFalse()', () {
      expect(picked(true).asBoolOrFalse(), isTrue);
      expect(picked(false).asBoolOrFalse(), isFalse);
      expect(picked('a').asBoolOrFalse(), isFalse);
      expect(nullPick().asBoolOrFalse(), isFalse);
    });

    test('asIntOrNull()', () {
      expect(picked(1).asIntOrNull(), 1);
      expect(picked('a').asIntOrNull(), isNull);
      expect(nullPick().asIntOrNull(), isNull);
    });

    test('asDoubleOrNull()', () {
      expect(picked(1).asDoubleOrNull(), 1.0);
      expect(picked(2.0).asDoubleOrNull(), 2.0);
      expect(picked('3.0').asDoubleOrNull(), 3.0);
      expect(picked('a').asDoubleOrNull(), isNull);
      expect(nullPick().asDoubleOrNull(), isNull);
    });

    test('asDateTimeOrNull()', () {
      expect(picked('2012-02-27 13:27:00,123456z').asDateTimeOrNull(),
          DateTime.utc(2012, 2, 27, 13, 27, 0, 123, 456));
      expect(picked(DateTime.utc(2020)).asDateTimeOrNull(), DateTime.utc(2020));
      expect(picked('1').asDateTimeOrNull(), isNull);
      expect(picked('Bubblegum').asDateTimeOrNull(), isNull);
      expect(nullPick().asDateTimeOrNull(), isNull);
    });

    test('letOrNull()', () {
      expect(
          picked({'name': 'John Snow'})
              .letOrNull((pick) => Person.fromJson(pick.asMap())),
          Person(name: 'John Snow'));
      expect(nullPick().letOrNull((pick) => Person.fromJson(pick.asMap())),
          isNull);
      expect(
          () => picked('a').letOrNull((pick) => Person.fromJson(pick.asMap())),
          throwsA(isA<PickException>().having(
            (e) => e.message,
            'message',
            contains(
                "value a of type String at location `0` can't be casted to Map<dynamic, dynamic>"),
          )));
      expect(
          () => picked({'asdf': 'John Snow'})
              .letOrNull((pick) => Person.fromJson(pick.asMap())),
          throwsA(isA<PickException>().having((e) => e.message, 'message',
              contains('required value at location `name` is null'))));
    });

    test('asListOrEmpty(Pick -> T)', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];
      expect(picked(data).asListOrEmpty((it) => Person.fromJson(it.asMap())), [
        Person(name: 'John Snow'),
        Person(name: 'Daenerys Targaryen'),
      ]);
      expect(picked([]).asList((pick) => Person.fromJson(pick.asMap())), []);
      expect(nullPick().asListOrEmpty((pick) => Person.fromJson(pick.asMap())),
          []);
    });

    test('asListOrEmpty(Pick -> T) reports item parsing errors', () {
      final data = [
        {'name': 'John Snow'},
        {'asdf': 'Daenerys Targaryen'}, // <-- wrong key
      ];
      expect(
          () => picked(data)
              .asListOrEmpty((pick) => Person.fromJson(pick.asMap())),
          throwsA(isA<PickException>().having((e) => e.message, 'message',
              contains('required value at location `name` is null'))));
    });

    test('asListOrNull(Pick -> T)', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];
      expect(
          picked(data).asListOrNull((pick) => Person.fromJson(pick.asMap())), [
        Person(name: 'John Snow'),
        Person(name: 'Daenerys Targaryen'),
      ]);
      expect(
          picked([]).asListOrNull((pick) => Person.fromJson(pick.asMap())), []);
      expect(nullPick().asListOrNull((pick) => Person.fromJson(pick.asMap())),
          null);
    });

    test('asListOrNull(Pick -> T) reports item parsing errors', () {
      final data = [
        {'name': 'John Snow'},
        {'asdf': 'Daenerys Targaryen'}, // <-- wrong key
      ];
      expect(
          () => picked(data)
              .asListOrNull((pick) => Person.fromJson(pick.asMap())),
          throwsA(isA<PickException>().having((e) => e.message, 'message',
              contains('required value at location `name` is null'))));
    });
  });

  group('invalid pick', () {
    test('out of range in list returns null pick', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];
      expect(pick(data, 10).value, isNull);
    });

    test('unknown property in map returns null', () {
      final data = {'name': 'John Snow'};
      expect(pick(data, 'birthday').value, isNull);
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

    test('add and read from context with syntax sugar', () {
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

Pick picked(dynamic value) {
  return pick([value], 0);
}

Pick nullPick() {
  return pick(<String, dynamic>{}, 'unknownKey');
}

Matcher pickException({List<String> containing}) {
  return const TypeMatcher<PickException>()
      .having((e) => e.message, 'message', stringContainsInOrder(containing));
}

class Person {
  Person({
    // ignore: always_require_non_null_named_parameters
    this.name,
  }) : assert(name != null);

  factory Person.fromJson(Map<String, dynamic> data) {
    return Person(
      name: pick(data, 'name').required().asString(),
    );
  }

  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}
