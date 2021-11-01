import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

import 'pick_test.dart';

void main() {
  group('pick().let*', () {
    test('.required().let()', () {
      expect(
        pick({'name': 'John Snow'})
            .required()
            .let((pick) => Person.fromPick(pick)),
        Person(name: 'John Snow'),
      );
      expect(
        pick({'name': 'John Snow'})
            .required()
            .let((pick) => Person.fromPick(pick)),
        Person(name: 'John Snow'),
      );
      expect(
        () => nullPick().required().let((pick) => Person.fromPick(pick)),
        throwsA(pickException(containing: ['unknownKey', 'absent'])),
      );
    });

    test('letOrThrow()', () {
      expect(
        pick({'name': 'John Snow'}).letOrThrow((pick) => Person.fromPick(pick)),
        Person(name: 'John Snow'),
      );
      expect(
        pick({'name': 'John Snow'}).letOrThrow((pick) => Person.fromPick(pick)),
        Person(name: 'John Snow'),
      );
      expect(
        () => nullPick().letOrThrow((pick) => Person.fromPick(pick)),
        throwsA(pickException(containing: ['unknownKey', 'absent'])),
      );
    });

    test('letOrNull()', () {
      expect(
        pick({'name': 'John Snow'}).letOrNull((pick) => Person.fromPick(pick)),
        Person(name: 'John Snow'),
      );
      expect(nullPick().letOrNull((pick) => Person.fromPick(pick)), isNull);
      expect(
        () => pick('a').letOrNull((pick) => Person.fromPick(pick)),
        throwsA(
          pickException(
            containing: [
              'Expected a non-null value but location "name" in pick(json, "name" (absent)) is absent.'
            ],
          ),
        ),
      );
      expect(
        () => pick({'asdf': 'John Snow'})
            .letOrNull((pick) => Person.fromPick(pick)),
        throwsA(
          pickException(
            containing: [
              'Expected a non-null value but location "name" in pick(json, "name" (absent)) is absent.'
            ],
          ),
        ),
      );
    });

    test('letOrThrow()', () {
      expect(
        pick({'name': 'John Snow'}).letOrThrow((pick) => Person.fromPick(pick)),
        Person(name: 'John Snow'),
      );
      expect(
        () => nullPick().letOrThrow((pick) => Person.fromPick(pick)),
        throwsA(
          pickException(
            containing: [
              'Expected a non-null value but location "unknownKey" in pick(json, "unknownKey" (absent)) is absent. Use letOrNull() when the value may be null/absent at some point.'
            ],
          ),
        ),
      );
      expect(
        () => pick({'asdf': 'John Snow'})
            .letOrThrow((pick) => Person.fromPick(pick)),
        throwsA(
          pickException(
            containing: [
              'Expected a non-null value but location "name" in pick(json, "name" (absent)) is absent. Use letOrNull() when the value may be null/absent at some point'
            ],
          ),
        ),
      );
    });
  });
}
