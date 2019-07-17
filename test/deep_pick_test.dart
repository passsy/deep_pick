import 'dart:convert';

import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

void main() {
  group('parse objects', () {
    test('prase json object 3 levels deep', () {
      final json = {
        'level1': {
          'level2': {
            'level3': 'adam',
          }
        }
      };
      final value = parseJsonTo<String>(json, 'level1', 'level2', 'level3');
      expect(value, equals('adam'));
    });

    test('num parsing is defined by implementer', () {
      final numAsString = jsonDecode('''
      {
        "level1": {
           "level2": "1"
        }
      }
      ''');
      expect(parseJsonToString(numAsString, 'level1', 'level2'), equals('1'));
      expect(parseJsonToInt(numAsString, 'level1', 'level2'), equals(1));
      expect(parseJsonToDouble(numAsString, 'level1', 'level2'), equals(1.0));
    });

    test('String parsing is defined by implementer', () {
      final stringAsNum = jsonDecode('''
      {
        "level1": {
           "level2": "1"
        }
      }
      ''');
      expect(parseJsonToString(stringAsNum, 'level1', 'level2'), equals('1'));
      expect(parseJsonToInt(stringAsNum, 'level1', 'level2'), equals(1));
      expect(parseJsonToDouble(stringAsNum, 'level1', 'level2'), equals(1.0));
    });

    test('return null when values is null', () {
      final json = {
        'level1': {'level2': null}
      };
      final value = parseJsonTo<String>(json, 'level1', 'level2');
      expect(value, isNull);
    });

    test("return null when drill down doesn't work", () {
      final json = {'level1': {}};
      final value = parseJsonTo<String>(json, 'level1', 'level2', 'level3');
      expect(value, isNull);
    });
  });

  group('parse lists', () {
    test('top level list', () {
      final json = [
        {
          'level1': {
            'level2': [
              'adam',
              'berta',
              'caesar',
            ]
          }
        },
        {
          'something': 'else',
        }
      ];
      expect(parseJsonTo<String>(json, 0, 'level1', 'level2', 0), equals('adam'));
      expect(parseJsonTo<String>(json, 0, 'level1', 'level2', 1), equals('berta'));
      expect(parseJsonTo<String>(json, 0, 'level1', 'level2', 2), equals('caesar'));
      expect(parseJsonTo<String>(json, 1, 'something'), equals('else'));
    });
  });
}
