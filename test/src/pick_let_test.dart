import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

import 'pick_test.dart';

void main() {
  group('pick().let*', () {
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
          throwsA(pickException(containing: ['unknownKey', 'absent'])));
    });

    test('letOrNull()', () {
      expect(
          pick({'name': 'John Snow'})
              .letOrNull((pick) => Person.fromJson(pick.asMap())),
          Person(name: 'John Snow'));
      expect(nullPick().letOrNull((pick) => Person.fromJson(pick.asMap())),
          isNull);
      expect(
          () => pick('a').letOrNull((pick) => Person.fromJson(pick.asMap())),
          throwsA(isA<PickException>().having(
            (e) => e.message,
            'message',
            contains(
                'value a of type String at location `<root>` can not be casted to Map<dynamic, dynamic>'),
          )));
      expect(
          () => pick({'asdf': 'John Snow'})
              .letOrNull((pick) => Person.fromJson(pick.asMap())),
          throwsA(isA<PickException>().having((e) => e.message, 'message',
              contains('required value at location `name` is absent'))));
    });

    test('letOrThrow()', () {
      expect(
          pick({'name': 'John Snow'})
              .letOrThrow((pick) => Person.fromJson(pick.asMap())),
          Person(name: 'John Snow'));
      expect(
        () => nullPick().letOrThrow((pick) => Person.fromJson(pick.asMap())),
        throwsA(pickException(containing: [
          'required value at location `unknownKey` is absent. Use letOrNull() when the value may be null/absent at some point.'
        ])),
      );
      expect(
        () => pick({'asdf': 'John Snow'})
            .letOrThrow((pick) => Person.fromJson(pick.asMap())),
        throwsA(pickException(
            containing: ['required value at location `name` is absent'])),
      );
    });
  });
}
