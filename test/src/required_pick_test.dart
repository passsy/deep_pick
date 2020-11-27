import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

import 'pick_test.dart';

void main() {
  group('RequiredPick', () {
    test('toString() works as expected', () {
      // ignore: deprecated_member_use_from_same_package
      expect(RequiredPick('a', path: ['b', 0]).toString(),
          'RequiredPick(value=a, path=[b, 0])');
    });

    test('pick further', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];

      final first = pick(data, 0).required();
      expect(first.value, {'name': 'John Snow'});

      // pick further
      expect(first('name').required().asString(), 'John Snow');
    });
  });

  group('parsing .required()', () {
    test('asString()', () {
      expect(pick('adam').asStringOrThrow(), 'adam');
      expect(pick(1).asStringOrThrow(), '1');
      expect(pick(2.0).asStringOrThrow(), '2.0');
      expect(
          () => nullPick().asStringOrThrow(),
          throwsA(pickException(
              containing: ['unknownKey', 'absent', 'asStringOrNull'])));
    });

    test("asString() doesn't transform Maps and Lists with toString", () {
      expect(
          () => pick(['a', 'b']).asStringOrThrow(),
          throwsA(pickException(
              containing: ['List<String>', 'not a List or Map', '[a, b]'])));
      expect(
          () => pick({'a': 'b'}).asStringOrThrow(),
          throwsA(pickException(containing: [
            'Map<String, String>',
            'not a List or Map',
            '{a: b}'
          ])));
    });

    test('call()', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];

      final first = pick(data, 0).required();
      expect(first.value, {'name': 'John Snow'});

      // pick further
      expect(first.call('name').required().asString(), 'John Snow');
    });

    test('call() carries over the location for good stacktraces', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];

      final level1Pick = pick(data, 0).required();
      expect(level1Pick.fullPath, [0]);

      final level2Pick = level1Pick.call('name');
      expect(level2Pick.fullPath, [0, 'name']);
    });

    test('asMap()', () {
      expect(pick({'ab': 'cd'}).asMapOrThrow(), {'ab': 'cd'});
      expect(
          () => pick('Bubblegum').asMapOrThrow(),
          throwsA(pickException(
              containing: ['Bubblegum', 'String', 'Map<dynamic, dynamic>'])));
      expect(
          () => nullPick().asMapOrThrow(),
          throwsA(pickException(
              containing: ['unknownKey', 'null', 'Map<dynamic, dynamic>'])));
    });

    test('asMapOrThrow() throws for cast error', () {
      final dynamic data = {
        'a': {'some': 'value'}
      };

      try {
        final parsed = pick(data).asMapOrThrow<String, bool>();
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

    test('asMapOrThrow() throws when null', () {
      expect(
        () => nullPick().asMapOrThrow<String, bool>(),
        throwsA(const TypeMatcher<PickException>().having(
            (e) => e.toString(),
            'message',
            stringContainsInOrder([
              'pick(json, "unknownKey" (absent))',
              'null',
              'Map<String, bool>'
            ]))),
      );
    });

    test('asList()', () {
      // ignore: deprecated_member_use_from_same_package
      expect(pick(['a', 'b', 'c']).asList((it) => it.asStringOrThrow()),
          ['a', 'b', 'c']);
      // ignore: deprecated_member_use_from_same_package
      expect(pick([1, 2, 3]).asList((it) => it.asIntOrThrow()), [1, 2, 3]);
      expect(
          // ignore: deprecated_member_use_from_same_package
          () => pick('Bubblegum').asList((it) => it.asStringOrThrow()),
          throwsA(pickException(
              containing: ['Bubblegum', 'String', 'List<dynamic>'])));
      expect(
          // ignore: deprecated_member_use_from_same_package
          () => nullPick().asList((it) => it.asStringOrThrow()),
          throwsA(pickException(
              containing: ['unknownKey', 'null', 'List<String>'])));
      expect(
          // ignore: deprecated_member_use_from_same_package
          () => nullPick().asList((it) => it.asStringOrThrow()),
          throwsA(pickException(
              containing: ['unknownKey', 'null', 'List<String>'])));
    });

    test('asList()', () {
      expect(pick(['a', 'b', 'c']).asListOrThrow((it) => it.asString()),
          ['a', 'b', 'c']);
      expect(pick([1, 2, 3]).asListOrThrow((it) => it.asInt()), [1, 2, 3]);
      expect(
          () => pick('Bubblegum').asListOrThrow((it) => it.asString()),
          throwsA(pickException(
              containing: ['Bubblegum', 'String', 'List<dynamic>'])));
      expect(
          () => nullPick().asListOrThrow((it) => it.asString()),
          throwsA(pickException(
              containing: ['unknownKey', 'null', 'List<String>'])));
      expect(
          () => nullPick().asListOrThrow((it) => it.asString()),
          throwsA(pickException(
              containing: ['unknownKey', 'null', 'List<String>'])));
    });

    test('asBoolOrThrow()', () {
      expect(pick(true).asBoolOrThrow(), isTrue);
      expect(pick('true').asBoolOrThrow(), isTrue);
      expect(pick('false').asBoolOrThrow(), isFalse);
      expect(() => pick('Bubblegum').asBoolOrThrow(),
          throwsA(pickException(containing: ['Bubblegum', 'String', 'bool'])));
      expect(() => nullPick().asBoolOrThrow(),
          throwsA(pickException(containing: ['unknownKey', 'null', 'bool'])));
    });

    test('asInt()', () {
      expect(pick(1).asIntOrThrow(), 1);
      expect(pick('1').asIntOrThrow(), 1);
      expect(() => pick('Bubblegum').asIntOrThrow(),
          throwsA(pickException(containing: ['Bubblegum', 'String', 'int'])));
      expect(() => nullPick().asIntOrThrow(),
          throwsA(pickException(containing: ['unknownKey', 'null', 'int'])));
    });

    test('asDouble()', () {
      expect(pick(1).asDoubleOrThrow(), 1.0);
      expect(pick(2.0).asDoubleOrThrow(), 2.0);
      expect(pick('3.0').asDoubleOrThrow(), 3.0);
      expect(
          () => pick('Bubblegum').asDoubleOrThrow(),
          throwsA(
              pickException(containing: ['Bubblegum', 'String', 'double'])));
      expect(() => nullPick().asDoubleOrThrow(),
          throwsA(pickException(containing: ['unknownKey', 'null', 'double'])));
    });

    test('asDateTime()', () {
      expect(pick('2012-02-27 13:27:00,123456z').asDateTimeOrThrow(),
          DateTime.utc(2012, 2, 27, 13, 27, 0, 123, 456));
      expect(
          () => pick('Bubblegum').asDateTimeOrThrow(),
          throwsA(
              pickException(containing: ['Bubblegum', 'String', 'DateTime'])));
      expect(
          () => nullPick().asDateTimeOrThrow(),
          throwsA(
              pickException(containing: ['unknownKey', 'null', 'DateTime'])));
    });

    test('let()', () {
      expect(
          pick({'name': 'John Snow'})
              .required()
              .let((pick) => Person.fromJson(pick)),
          Person(name: 'John Snow'));
      expect(
          pick({'name': 'John Snow'})
              .required()
              .let((pick) => Person.fromJson(pick)),
          Person(name: 'John Snow'));
      expect(() => nullPick().required().let((pick) => Person.fromJson(pick)),
          throwsA(pickException(containing: ['unknownKey', 'absent'])));
    });

    test('asList(Pick -> T)', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];
      // ignore: deprecated_member_use_from_same_package
      expect(pick(data).asList((pick) => Person.fromJson(pick.required())), [
        Person(name: 'John Snow'),
        Person(name: 'Daenerys Targaryen'),
      ]);
      // ignore: deprecated_member_use_from_same_package
      expect(pick([]).asList((pick) => Person.fromJson(pick.required())), []);
      expect(
          // ignore: deprecated_member_use_from_same_package
          () => nullPick().asList((pick) => Person.fromJson(pick.required())),
          throwsA(pickException(containing: ['unknownKey', 'null', 'List'])));
    });

    test('asListOrThrow(Pick -> T)', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];
      expect(pick(data).asListOrThrow((pick) => Person.fromJson(pick)), [
        Person(name: 'John Snow'),
        Person(name: 'Daenerys Targaryen'),
      ]);
      expect(pick([]).asListOrThrow((pick) => Person.fromJson(pick)), []);
      expect(() => nullPick().asListOrThrow((pick) => Person.fromJson(pick)),
          throwsA(pickException(containing: ['unknownKey', 'null', 'List'])));
    });
  });

  group('context API', () {
    test('add and read from context', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];
      final root = pick(data).required();
      root.context['lang'] = 'de';
      expect(root.context, {'lang': 'de'});
    });

    test('add and read from context with syntax sugar', () {
      // ignore: deprecated_member_use_from_same_package
      final root = pick([]).required().addContext('lang', 'de');
      expect(root.fromContext('lang').asStringOrNull(), 'de');
    });

    test('read from deep nested context', () {
      final root = pick([]).required().withContext('user', {'id': '1234'});
      expect(root.fromContext('user', 'id').asStringOrNull(), '1234');
    });

    test('copy into asList()', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];
      final root = pick(data).required();
      root.context['lang'] = 'de';
      expect(root.context, {'lang': 'de'});

      final contexts = root.asList((pick) => pick.context);
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
      final root = pick(data).required();
      root.context['lang'] = 'de';
      expect(root.context, {'lang': 'de'});

      final afterCall = root.call(1, 'name').required();
      expect(afterCall.context, {'lang': 'de'});

      root.context['hello'] = 'world';
      expect(root.context, {'lang': 'de', 'hello': 'world'});
      expect(afterCall.context, {'lang': 'de'});
    });
  });
}
