import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

import 'pick_test.dart';

void main() {
  test('Can not add to empty object', () {
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

  test('Replate item deep in map', () {
    final map = {
      'asdf': {'qwer': 1}
    };
    pick(map, 'asdf', 'qwer').set(2);
    expect(map['asdf']!['qwer'], 2);
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

// map.set('key', 'value') = 12;
//
// final value = pick(map, 'key', 'asdf').asIntOrThrow();
//
// // {
// //   'key': {
// //     'asdf': 12,
// //   }
// // }
//
// // set key.asdf in map to 12
// map.set('key', 'asdf') = 12;
//
//
// final locationPoint = loc('key', 'asdf');
// // set(map, locationPoint, value: 12);
// // map.set(locationPoint, value: 12);
// // loc.set(map, value: 12);
//
// set(map, loc('key', 'asdf'), value: {'qwer': 24});
// set(map, loc('key', 'asdf'), value: {'qwer': 24});
// set(map, loc('key', 'asdf', 'qwer'), value:  24);
// map.prop('key', 'asdf', 'qwer').set(24);
// map.prop('key', 'asdf', 'qwer').set({
//   'zxcv': 48,
//   'asdf': 96,
// });
//
// map.prop('asdf', 4).set('asdf');
// final Pick p = map.prop('asdf', 4);
//
// final Pick p1 = pick(map, 'asdf');
