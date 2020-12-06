import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

import 'pick_test.dart';

void main() {
  group('pick().asList*', () {
    group('asListOrThrow', () {
      test('pipe through List', () {
        expect(pick([1, 2, 3]).asListOrThrow(), [1, 2, 3]);
      });

      test('null throws', () {
        expect(
          () => nullPick().asListOrThrow<String>(),
          throwsA(pickException(containing: [
            'required value at location `unknownKey` is absent. Use asListOrEmpty()/asListOrNull() when the value may be null/absent at some point (List<String>?).'
          ])),
        );
      });

      test('map empty list to empty list', () {
        expect(
          pick([])
              .asListOrThrow((pick) => Person.fromJson(pick.asMapOrThrow())),
          [],
        );
      });

      test('map to List<Person>', () {
        expect(
          pick([
            {'name': 'John Snow'},
            {'name': 'Daenerys Targaryen'},
          ]).asListOrThrow((pick) => Person.fromJson(pick.asMapOrThrow())),
          [
            Person(name: 'John Snow'),
            Person(name: 'Daenerys Targaryen'),
          ],
        );
      });

      test('map to List<Person?>', () {
        expect(
          pick([
            {'name': 'John Snow'},
            {'name': 'Daenerys Targaryen'},
            null, // <-- valid value
          ]).asListOrThrow((pick) =>
              pick.letOrNull((pick) => Person.fromJson(pick.asMap()))),
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
          ]).asListOrThrow((pick) => Person.fromJson(pick.asMapOrThrow())),
          throwsA(pickException(
              containing: ['required value at location `name` is absent'])),
        );
      });

      test('wrong type throws', () {
        expect(
          () => pick('Bubblegum').asListOrThrow(),
          throwsA(pickException(
              containing: ['Bubblegum', 'String', 'List<dynamic>'])),
        );
        expect(
          () => pick(Object()).asListOrThrow(),
          throwsA(pickException(containing: [
            "value Instance of 'Object' of type Object at location `<root>` can not be casted to List<dynamic>"
          ])),
        );
      });
    });

    test('deprecated asList forwards to asListOrThrow', () {
      // ignore: deprecated_member_use_from_same_package
      expect(pick([1, 2, 3]).asList(), [1, 2, 3]);
      expect(
        // ignore: deprecated_member_use_from_same_package
        () => pick(Object()).asList(),
        throwsA(pickException(containing: [
          "value Instance of 'Object' of type Object at location `<root>` can not be casted to List<dynamic>"
        ])),
      );
    });

    group('asListOrEmpty', () {
      test('pick value', () {
        expect(pick([1, 2, 3]).asListOrEmpty(), [1, 2, 3]);
      });

      test('null returns null', () {
        expect(nullPick().asListOrEmpty<int>(), []);
      });

      test('wrong type returns empty', () {
        expect(pick(Object()).asListOrEmpty<int>(), []);
      });

      test('map empty list to empty list', () {
        expect(
          pick([])
              .asListOrEmpty((pick) => Person.fromJson(pick.asMapOrThrow())),
          [],
        );
      });

      test('map null list to empty list', () {
        expect(
          nullPick()
              .asListOrEmpty((pick) => Person.fromJson(pick.asMapOrThrow())),
          [],
        );
      });

      test('map to List<Person>', () {
        expect(
          pick([
            {'name': 'John Snow'},
            {'name': 'Daenerys Targaryen'},
          ]).asListOrEmpty((pick) => Person.fromJson(pick.asMapOrThrow())),
          [
            Person(name: 'John Snow'),
            Person(name: 'Daenerys Targaryen'),
          ],
        );
      });

      test('map to List<Person?>', () {
        expect(
          pick([
            {'name': 'John Snow'},
            {'name': 'Daenerys Targaryen'},
            null, // <-- valid value
          ]).asListOrEmpty((pick) =>
              pick.letOrNull((pick) => Person.fromJson(pick.asMap()))),
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
          ]).asListOrEmpty((pick) => Person.fromJson(pick.asMapOrThrow())),
          throwsA(pickException(
              containing: ['required value at location `name` is absent'])),
        );
      });
    });

    group('asListOrNull', () {
      test('pick value', () {
        expect(pick([1, 2, 3]).asListOrNull(), [1, 2, 3]);
      });

      test('null returns null', () {
        expect(nullPick().asListOrNull(), isNull);
      });

      test('wrong type returns empty', () {
        expect(pick(Object()).asListOrNull(), isNull);
      });

      test('map empty list to empty list', () {
        expect(
          pick([]).asListOrNull((pick) => Person.fromJson(pick.asMapOrThrow())),
          [],
        );
      });

      test('map null list to null', () {
        expect(
          nullPick()
              .asListOrNull((pick) => Person.fromJson(pick.asMapOrThrow())),
          null,
        );
      });

      test('map to List<Person>', () {
        expect(
          pick([
            {'name': 'John Snow'},
            {'name': 'Daenerys Targaryen'},
          ]).asListOrNull((pick) => Person.fromJson(pick.asMapOrThrow())),
          [
            Person(name: 'John Snow'),
            Person(name: 'Daenerys Targaryen'),
          ],
        );
      });

      test('map to List<Person?>', () {
        expect(
          pick([
            {'name': 'John Snow'},
            {'name': 'Daenerys Targaryen'},
            null, // <-- valid value
          ]).asListOrNull((pick) =>
              pick.letOrNull((pick) => Person.fromJson(pick.asMap()))),
          [
            Person(name: 'John Snow'),
            Person(name: 'Daenerys Targaryen'),
            null,
          ],
        );
      });

      test('map reports item parsing errors', () {
        final data = [
          {'name': 'John Snow'},
          {'asdf': 'Daenerys Targaryen'}, // <-- missing name key
        ];
        expect(
            () => pick(data)
                .asListOrNull((pick) => Person.fromJson(pick.asMapOrThrow())),
            throwsA(isA<PickException>().having((e) => e.message, 'message',
                contains('required value at location `name` is absent'))));
      });
    });
  });
}
