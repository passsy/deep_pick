// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

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

  test('Change type from int to String', () {
    final Map<dynamic, dynamic> map = {'asdf': 1};
    pick(map, 'asdf').set('john');
    expect(pick(map, 'asdf').asStringOrNull(), 'john');
  });

  test('Replace item deep in list', () {
    final list = [
      [],
      null,
      [
        null,
        <dynamic>[8],
      ]
    ];
    pick(list, 2, 1, 0).set('hello');
    expect(list[2]![1]![0], 'hello');
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

  test('Pick object returns old value after modification', () {
    final map = {};
    final pickObject = pick(map, 'asdf');
    pickObject.set(12);
    expect(map['asdf'], 12);
    // the pickObject doesn't know about the modification thus it still returns the old value.
    // That's expected because `pick` extracts the value immediately and doesn't observe the data structure.
    // To create a pointer to a value in a data structure use `pickDeep` instead and save/reuse the selector (List<dynamic>)
    expect(pickObject.value, null);
  });
}
