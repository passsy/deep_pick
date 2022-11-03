import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

import 'pick_test.dart';

void main() {
  test('Can not add to empty object', () {
    // ignore: prefer_const_declarations
    final Map? map = null;
    expect(
      () => pick(map).set('value'),
      throwsA(
        pickException(
          containing: ['Can not set value on null'],
        ),
      ),
    );
  });

  test('Add item to empty map', () {
    final map = {};
    pick(map, 'asdf').set(12);
    expect(map['asdf'], 12);
  });

  test('Replace item in map', () {
    final map = {'asdf': 1};
    pick(map, 'asdf').set(2);
    expect(map['asdf'], 2);
  });

  test('Replace item deep in map', () {
    final map = {
      'asdf': {'qwer': 1}
    };
    pick(map, 'asdf', 'qwer').set(2);
    expect(map['asdf']!['qwer'], 2);
  });

  test('Replace item deep in list', () {
    final list = [
      [],
      null,
      [
        null,
        [8]
      ]
    ];
    pick(list, 0, 2, 1).set(5);
    expect(list[0]![2]![1], 5);
  });

  test('Add item to empty list', () {
    final list = [];
    pick(list, 0).set(12);
    expect(list[0], 12);
  });

  test('Replace item in list', () {
    final list = [0, 1, 2];
    pick(list, 1).set(7);
    expect(list[1], 7);
  });

  test('Create structures in list', () {
    final list = [];
    pick(list, 0, 'meta').set({'index': 0});
    expect(pick(list, 0, 'meta', 'index').value, 0);
  });

  test('Create structures in map', () {
    final map = {};
    pick(map, 'meta', 0).set({'index': 0});
    expect(pick(map, 'meta', 0, 'index').value, 0);
  });
}
