import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

import 'pick_test.dart';

void main() {
  group('pick().asList*', () {
    group('asListOrThrow', () {
      test('pipe through List', () {
        expect(pick([1, 2, 3]).asListOrThrow((it) => it.asIntOrThrow()),
            [1, 2, 3]);
      });

      test('null throws', () {
        expect(
          () => nullPick().asListOrThrow((it) => it.asStringOrThrow()),
          throwsA(pickException(containing: [
            'required value at location "unknownKey" in pick(json, "unknownKey" (absent)) is absent. Use asListOrEmpty()/asListOrNull() when the value may be null/absent at some point (List<String>?).'
          ])),
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
          throwsA(pickException(containing: [
            'required value at location list index 1 in pick(json, 1 (absent), "name") is absent. Use asListOrEmpty()/asListOrNull() when the value may be null/absent at some point (List<Person>?).'
          ])),
        );
      });

      test('wrong type throws', () {
        expect(
          () => pick('Bubblegum').asListOrThrow((it) => it.asStringOrThrow()),
          throwsA(pickException(
              containing: ['Bubblegum', 'String', 'List<dynamic>'])),
        );
        expect(
          () => pick(Object()).asListOrThrow((it) => it.asStringOrThrow()),
          throwsA(pickException(containing: [
            'value Instance of \'Object\' of type Object at location "<root>" in pick(<root>) can not be casted to List<dynamic>'
          ])),
        );
      });
    });

    test('deprecated asList forwards to asListOrThrow', () {
      // ignore: deprecated_member_use_from_same_package
      expect(pick([1, 2, 3]).asList<int>(), [1, 2, 3]);
      expect(
        // ignore: deprecated_member_use_from_same_package
        () => pick(Object()).asList(),
        throwsA(pickException(containing: [
          'value Instance of \'Object\' of type Object at location "<root>" in pick(<root>) can not be casted to List<dynamic>'
        ])),
      );
    });

    group('asListOrEmpty', () {
      test('pick value', () {
        expect(pick([1, 2, 3]).asListOrEmpty((it) => it.asIntOrThrow()),
            [1, 2, 3]);
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
          throwsA(pickException(containing: [
            'required value at location list index 1 in pick(json, 1 (absent), "name") is absent.'
          ])),
        );
      });
    });

    group('asListOrNull', () {
      test('pick value', () {
        expect(
            pick([1, 2, 3]).asListOrNull((it) => it.asIntOrThrow()), [1, 2, 3]);
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

      test('map reports item parsing errors', () {
        final data = [
          {'name': 'John Snow'},
          {'asdf': 'Daenerys Targaryen'}, // <-- missing name key
        ];
        expect(
          () => pick(data).asListOrNull((pick) => Person.fromPick(pick)),
          throwsA(pickException(containing: [
            'required value at location list index 1 in pick(json, 1 (absent), "name") is absent.'
          ])),
        );
      });
    });
  });
}
