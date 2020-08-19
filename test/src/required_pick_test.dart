// ignore_for_file: deprecated_member_use_from_same_package
import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

import 'pick_test.dart';

void main() {
  group('RequiredPick', () {
    test("can't have null value", () {
      expect(() => RequiredPick(null), throwsA(isA<StateError>()));
    });

    test('toString() works as expected', () {
      expect(RequiredPick('a', ['b', 0]).toString(),
          'RequiredPick(value=a, path=[b, 0])');
    });

    test('pick further', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];

      final picked = pick(data, 0).required();
      expect(picked.value, {'name': 'John Snow'});

      // pick further
      expect(picked('name').required().asString(), 'John Snow');
    });
  });

  group('parsing .required()', () {
    test('asString()', () {
      expect(picked('adam').asString(), 'adam');
      expect(picked(1).asString(), '1');
      expect(picked(2.0).asString(), '2.0');
      expect(() => nullPick().asString(),
          throwsA(pickException(containing: ['unknownKey', 'null', 'String'])));
    });

    test("asString() doesn't transform Maps and Lists with toString", () {
      expect(
          () => picked(['a', 'b']).asString(),
          throwsA(pickException(
              containing: ['List<String>', 'not a List or Map', '[a, b]'])));
      expect(
          () => picked({'a': 'b'}).asString(),
          throwsA(pickException(containing: [
            'Map<String, String>',
            'not a List or Map',
            '{a: b}'
          ])));
    });

    test('asMap()', () {
      expect(picked({'ab': 'cd'}).asMap(), {'ab': 'cd'});
      expect(
          () => picked('Bubblegum').asMap(),
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
        final parsed = picked(data).asMap<String, bool>();
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
      expect(picked(['a', 'b', 'c']).asList(), ['a', 'b', 'c']);
      expect(picked([1, 2, 3]).asList<int>(), [1, 2, 3]);
      expect(
          () => picked('Bubblegum').asList(),
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
      expect(picked(true).asBool(), isTrue);
      expect(() => picked('Bubblegum').asBool(),
          throwsA(pickException(containing: ['Bubblegum', 'String', 'bool'])));
      expect(() => nullPick().asBool(),
          throwsA(pickException(containing: ['unknownKey', 'null', 'bool'])));
    });

    test('asInt()', () {
      expect(picked(1).asInt(), 1);
      expect(picked(1.0).asInt(), 1);
      expect(picked('1').asInt(), 1);
      expect(() => picked('Bubblegum').asInt(),
          throwsA(pickException(containing: ['Bubblegum', 'String', 'int'])));
      expect(() => nullPick().asInt(),
          throwsA(pickException(containing: ['unknownKey', 'null', 'int'])));
    });

    test('asDouble()', () {
      expect(picked(1).asDouble(), 1.0);
      expect(picked(2.0).asDouble(), 2.0);
      expect(picked('3.0').asDouble(), 3.0);
      expect(
          () => picked('Bubblegum').asDouble(),
          throwsA(
              pickException(containing: ['Bubblegum', 'String', 'double'])));
      expect(() => nullPick().asDouble(),
          throwsA(pickException(containing: ['unknownKey', 'null', 'double'])));
    });

    test('asDateTime()', () {
      expect(picked('2012-02-27 13:27:00,123456z').asDateTime(),
          DateTime.utc(2012, 2, 27, 13, 27, 0, 123, 456));
      expect(
          () => picked('Bubblegum').asDateTime(),
          throwsA(
              pickException(containing: ['Bubblegum', 'String', 'DateTime'])));
      expect(
          () => nullPick().asDateTime(),
          throwsA(
              pickException(containing: ['unknownKey', 'null', 'DateTime'])));
    });

    test('let()', () {
      expect(
          picked({'name': 'John Snow'})
              .required()
              .let((pick) => Person.fromJson(pick.asMap())),
          Person(name: 'John Snow'));
      expect(
          picked({'name': 'John Snow'})
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
      expect(picked(data).asList((pick) => Person.fromJson(pick.asMap())), [
        Person(name: 'John Snow'),
        Person(name: 'Daenerys Targaryen'),
      ]);
      expect(picked([]).asList((pick) => Person.fromJson(pick.asMap())), []);
      expect(() => nullPick().asList((pick) => Person.fromJson(pick.asMap())),
          throwsA(pickException(containing: ['unknownKey', 'null', 'List'])));
    });
  });
}
