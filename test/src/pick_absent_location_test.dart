import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

/// The `(absent)` marker in [Pick.debugParsingExit] has to sit on the path
/// segment where drilling down actually stopped, not somewhere before it.
///
/// [Pick.missingValueAtIndex] is documented as an index into [Pick.path], and
/// [Pick.followablePath] derives from it, so all three have to agree on the
/// same segment.
void main() {
  group('absent location survives chained picks', () {
    final json = {
      'a': {'b': 1},
      'list': [
        {'name': 'John'},
      ],
    };

    test('missing key one level below a chained pick', () {
      final chained = pick(json, 'a')('x');
      final direct = pick(json, 'a', 'x');

      // both describe the very same location and must not disagree
      expect(chained.path, direct.path);
      expect(chained.missingValueAtIndex, direct.missingValueAtIndex);
      expect(chained.followablePath, direct.followablePath);
      expect(chained.debugParsingExit, direct.debugParsingExit);

      expect(chained.missingValueAtIndex, 1);
      expect(chained.followablePath, ['a']);
      expect(
        chained.debugParsingExit,
        '"x" in pick(json, "a", "x" (absent))',
      );
    });

    test('missing key two levels below a chained pick', () {
      final chained = pick(json, 'a')('b')('c');

      expect(chained.path, ['a', 'b', 'c']);
      expect(chained.missingValueAtIndex, 2);
      expect(chained.followablePath, ['a', 'b']);
      expect(
        chained.debugParsingExit,
        '"c" in pick(json, "a", "b", "c" (absent))',
      );
    });

    test('index out of range below a chained pick', () {
      final chained = pick(json, 'list')(5);

      expect(chained.missingValueAtIndex, 1);
      expect(chained.followablePath, ['list']);
      expect(
        chained.debugParsingExit,
        'list index 5 in pick(json, "list", 5 (absent))',
      );
    });

    test('pickDeep continued via call()', () {
      final chained = pickDeep(json, ['a'])('b', 'c');

      expect(chained.missingValueAtIndex, 2);
      expect(chained.followablePath, ['a', 'b']);
    });

    test('required() reports the segment that could not be followed', () {
      expect(
        () => pick(json, 'a')('x').required(),
        throwsA(
          isA<PickException>().having(
            (e) => e.message,
            'message',
            contains('"x" in pick(json, "a", "x" (absent))'),
          ),
        ),
      );
    });

    test('missing key inside a asListOrThrow element', () {
      // the list exists, only "nope" inside the element is missing
      expect(
        () => pick(json, 'list')
            .asListOrThrow((it) => it('nope').required().asString()),
        throwsA(
          isA<PickException>().having(
            (e) => e.message,
            'message',
            contains('"nope" in pick(json, "list", 0, "nope" (absent))'),
          ),
        ),
      );
    });

    test('picking by index from a Set reports the full location', () {
      final data = {
        'deep': {
          'set': {'a', 'b', 'c'},
        },
      };
      expect(
        () => pick(data, 'deep')('set', 0),
        throwsA(
          isA<PickException>().having(
            (e) => e.message,
            'message',
            contains('location [deep, set]'),
          ),
        ),
      );
    });
  });
}
