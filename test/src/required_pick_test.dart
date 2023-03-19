import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

void main() {
  group('RequiredPick', () {
    test('toString() works as expected', () {
      expect(
        // ignore: deprecated_member_use_from_same_package
        RequiredPick('a', path: ['b', 0]).toString(),
        'RequiredPick(value=a, path=[b, 0])',
      );
    });

    test('value is non nullable', () {
      final nullable = pick('a');
      expect([nullable.value].runtimeType.toString(), 'List<Object?>');

      final nonNull = nullable.required();
      expect([nonNull.value].runtimeType.toString(), 'List<Object>');
    });

    test('nullable() converts RequiredPick back to a Pick', () {
      final aMayBeOptional = pick({'a': 1}, 'a');
      final aIsNowRequired = aMayBeOptional.required();
      final aMayBeOptionalAgain = aIsNowRequired.nullable();
      expect(aMayBeOptionalAgain.asIntOrThrow(), 1);
    });
  });

  group('.call()', () {
    test('.call() pick further', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];

      final first = pick(data, 0).required();
      expect(first.value, {'name': 'John Snow'});

      // pick further
      expect(first.call('name').asStringOrThrow(), 'John Snow');
      expect(first('name').asStringOrThrow(), 'John Snow');
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

    test('read from deep nested context', () {
      final root = pick([]).required().withContext('user', {'id': '1234'});
      expect(root.fromContext('user', 'id').asStringOrNull(), '1234');
    });

    test('copy context into elements when parsing lists', () {
      final data = [
        {'name': 'John Snow'},
        {'name': 'Daenerys Targaryen'},
      ];
      final root = pick(data).required();
      root.context['lang'] = 'de';
      expect(root.context, {'lang': 'de'});

      final contexts = root.asListOrEmpty((pick) => pick.context);
      expect(contexts, [
        {'lang': 'de'},
        {'lang': 'de'}
      ]);
    });

    test('copy context into call()', () {
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
