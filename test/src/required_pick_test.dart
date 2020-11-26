// ignore_for_file: deprecated_member_use_from_same_package
import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

import 'pick_test.dart';

void main() {
  group('RequiredPick', () {
    test('toString() works as expected', () {
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
      expect(pick('adam').asString(), 'adam');
      expect(pick(1).asString(), '1');
      expect(pick(2.0).asString(), '2.0');
      expect(
          () => nullPick().asString(),
          throwsA(pickException(
              containing: ['unknownKey', 'null', 'String', 'asStringOrNull'])));
    });

    test("asString() doesn't transform Maps and Lists with toString", () {
      expect(
          () => pick(['a', 'b']).asString(),
          throwsA(pickException(
              containing: ['List<String>', 'not a List or Map', '[a, b]'])));
      expect(
          () => pick({'a': 'b'}).asString(),
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
      expect(level1Pick.path, [0]);

      final level2Pick = level1Pick.call('name');
      expect(level2Pick.path, [0, 'name']);
    });

    test('asMap()', () {
      expect(pick({'ab': 'cd'}).asMap(), {'ab': 'cd'});
      expect(
          () => pick('Bubblegum').asMap(),
          throwsA(pickException(
              containing: ['Bubblegum', 'String', 'Map<dynamic, dynamic>'])));
      expect(
          () => nullPick().asMap(),
          throwsA(pickException(
              containing: ['unknownKey', 'null', 'Map<dynamic, dynamic>'])));
    });

    test('asMap() throws for cast error', () {
      final dynamic data = {
        'a': {'some': 'value'}
      };

      try {
        final parsed = pick(data).asMap<String, bool>();
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

    test('asList()', () {
      expect(pick(['a', 'b', 'c']).asList(), ['a', 'b', 'c']);
      expect(pick([1, 2, 3]).asList<int>(), [1, 2, 3]);
      expect(
          () => pick('Bubblegum').asList(),
          throwsA(pickException(
              containing: ['Bubblegum', 'String', 'List<dynamic>'])));
      expect(
          () => nullPick().asList(),
          throwsA(pickException(
              containing: ['unknownKey', 'null', 'List<dynamic>'])));
      expect(
          () => nullPick().asList<String>(),
          throwsA(pickException(
              containing: ['unknownKey', 'null', 'List<String>'])));
    });

    test('asBool()', () {
      expect(pick(true).asBool(), isTrue);
      expect(pick('true').asBool(), isTrue);
      expect(pick('false').asBool(), isFalse);
      expect(() => pick('Bubblegum').asBool(),
          throwsA(pickException(containing: ['Bubblegum', 'String', 'bool'])));
      expect(() => nullPick().asBool(),
          throwsA(pickException(containing: ['unknownKey', 'null', 'bool'])));
    });

    test('asInt()', () {
      expect(pick(1).asInt(), 1);
      expect(pick('1').asInt(), 1);
      expect(() => pick('Bubblegum').asInt(),
          throwsA(pickException(containing: ['Bubblegum', 'String', 'int'])));
      expect(() => nullPick().asInt(),
          throwsA(pickException(containing: ['unknownKey', 'null', 'int'])));
    });

    test('asDouble()', () {
      expect(pick(1).asDouble(), 1.0);
      expect(pick(2.0).asDouble(), 2.0);
      expect(pick('3.0').asDouble(), 3.0);
      expect(
          () => pick('Bubblegum').asDouble(),
          throwsA(
              pickException(containing: ['Bubblegum', 'String', 'double'])));
      expect(() => nullPick().asDouble(),
          throwsA(pickException(containing: ['unknownKey', 'null', 'double'])));
    });

    test('asDateTime()', () {
      expect(pick('2012-02-27 13:27:00,123456z').asDateTime(),
          DateTime.utc(2012, 2, 27, 13, 27, 0, 123, 456));
      expect(
          () => pick('Bubblegum').asDateTime(),
          throwsA(
              pickException(containing: ['Bubblegum', 'String', 'DateTime'])));
      expect(
          () => nullPick().asDateTime(),
          throwsA(
              pickException(containing: ['unknownKey', 'null', 'DateTime'])));
    });

    test('let()', () {
      expect(
          pick({'name': 'John Snow'})
              .required()
              .let((pick) => Person.fromJson(pick.asMap())),
          Person(name: 'John Snow'));
      expect(
          pick({'name': 'John Snow'})
              .required()
              .let((pick) => Person.fromJson(pick.asMap())),
          Person(name: 'John Snow'));
      expect(
          () => nullPick()
              .required()
              .let((pick) => Person.fromJson(pick.asMap())),
          throwsA(pickException(containing: ['unknownKey', 'null'])));
    });

    test('asList(Pick -> T)', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];
      expect(pick(data).asList((pick) => Person.fromJson(pick.asMap())), [
        Person(name: 'John Snow'),
        Person(name: 'Daenerys Targaryen'),
      ]);
      expect(pick([]).asList((pick) => Person.fromJson(pick.asMap())), []);
      expect(() => nullPick().asList((pick) => Person.fromJson(pick.asMap())),
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
