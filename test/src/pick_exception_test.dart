import 'dart:convert';

import 'package:deep_pick/deep_pick.dart';
import 'package:deep_pick/src/pick.dart' show requiredPickErrorHintKey;
import 'package:test/test.dart';

/// Captures the [PickException] thrown by [body]
PickException grabException(void Function() body) {
  try {
    body();
  } on PickException catch (e) {
    return e;
  }
  fail('body did not throw a PickException');
}

class UnprintableValue {
  @override
  String toString() => throw StateError('unrelated value cannot be printed');
}

void main() {
  final json = {
    'shoes': [
      {'id': 42, 'size': 'M'},
    ],
    'owner': null,
  };

  group('error message rendering', () {
    for (final expanded in [false, true]) {
      test('opaque sibling keys preserve parsing errors (expanded=$expanded)',
          () {
        final source = <Object, Object>{
          if (expanded)
            for (var i = 0; i < 5; i++) 'key$i': 'visible' * 10,
          UnprintableValue(): 'PRIVATE_VALUE',
        };
        expect(source.containsKey('missing'), isFalse);
        final original = pick(source, 'missing');
        expect(original.isAbsent, isTrue);
        expect(original.path, ['missing']);
        final e = grabException(original.required);
        expect(e.message.split('\n').first,
            'expected a non-null value at missing, but it is absent');
        expect(e.message, contains('"<UnprintableValue>"'));
        if (expanded) {
          expect(e.message, contains('  at      <root> = {\n'));
          expect(e.message,
              contains('            "<UnprintableValue>": "PRIVATE_VALUE",'));
        } else {
          expect(
              e.message, contains('{"<UnprintableValue>": "PRIVATE_VALUE"}'));
        }
      });
    }

    test('primitive map keys retain their escaped text', () {
      final e = grabException(() {
        pick(<Object?, Object>{null: 1, 2: 3, true: 4, 'line\nkey': 5},
                'missing')
            .required();
      });
      expect(e.message,
          contains(r'{"null": 1, "2": 3, "true": 4, "line\nkey": 5}'));
    });

    test('a missing-field error does not invoke an unrelated value toString',
        () {
      final source = <String, Object>{'unrelated': UnprintableValue()};
      expect(source.containsKey('missing'), isFalse);
      final result = pick(source, 'missing');
      expect(result.isAbsent, isTrue);
      expect(result.path, ['missing']);
      expect(
        () => result.required(),
        throwsA(isA<PickException>().having(
          (error) => error.message,
          'message',
          contains('but it is absent'),
        )),
      );
    });
    test('missing key shows query, marker and data at the last node', () {
      final e = grabException(() => pick(json, 'shoes', 0, 'name').required());
      expect(
        e.message,
        'expected a non-null value at shoes[0].name, but it is absent\n'
        '\n'
        '  query   shoes[0].name\n'
        '                   ~~~~ no such key\n'
        '  at      shoes[0] = {"id": 42, "size": "M"}',
      );
    });

    test('index out of range names the length', () {
      final e = grabException(() => pick(json, 'shoes', 7).required());
      expect(
        e.message,
        'expected a non-null value at shoes[7], but it is absent\n'
        '\n'
        '  query   shoes[7]\n'
        '               ~~~ index out of range, the List has 1 item\n'
        '  at      shoes = [{…2 keys}]',
      );
    });

    test('null on the way down is reported at the null', () {
      final e = grabException(() => pick(json, 'owner', 'name').required());
      expect(
        e.message,
        'expected a non-null value at owner.name, but it is absent\n'
        '\n'
        '  query   owner.name\n'
        '                ~~~~ null has no key "name"\n'
        '  at      owner = null',
      );
    });

    group('a path that runs into the wrong container says what it found', () {
      final cases = <String, Pick Function()>{
        'a String has no key "x"': () => pick({'a': 'str'}, 'a', 'x'),
        'a String has no index 0': () => pick({'a': 'str'}, 'a', 0),
        'a List has no key "k"': () => pick({
              'a': [1]
            }, 'a', 'k'),
        'an int has no index 2': () => pick({'a': 42}, 'a', 2),
      };
      for (final entry in cases.entries) {
        test(entry.key, () {
          final e = grabException(entry.value().required);
          expect(e.message, contains('but it is absent'));
          final marker = e.message.split('\n')[3];
          expect(marker.trimLeft(), startsWith('~'));
          expect(marker, endsWith(' ${entry.key}'));
        });
      }
    });

    test('wrong type shows the found value and type', () {
      final e = grabException(
        () {
          pick({'meta': 'yes'}, 'meta').asListOrThrow((it) => it.asString());
        },
      );
      expect(
        e.message,
        'expected a List at meta\n'
        '\n'
        '  query   meta\n'
        '  found   "yes"  (a String)',
      );
    });

    test('extension hints get their own row', () {
      final e = grabException(
        () => pick({'price': 12.5}, 'price').asIntOrThrow(),
      );
      expect(
        e.message,
        'expected an int at price\n'
        '\n'
        '  query   price\n'
        '  found   12.5  (a double)\n'
        '  hint    set roundDouble: true or truncateDouble: true to parse a '
        'double as int',
      );
    });

    test('large values wrap into an indented block', () {
      final e = grabException(() {
        pick({
          'address': {
            'line1': 'Musterstr. 1',
            'city': 'Berlin',
            'zip': '10115',
            'country': 'DE',
            'lat': 52.52,
            'lng': 13.405,
            'verified': true,
          },
        }, 'address', 'street')
            .required();
      });
      expect(
        e.message,
        'expected a non-null value at address.street, but it is absent\n'
        '\n'
        '  query   address.street\n'
        '                  ~~~~~~ no such key\n'
        '  at      address = {\n'
        '            "line1": "Musterstr. 1",\n'
        '            "city": "Berlin",\n'
        '            "zip": "10115",\n'
        '            "country": "DE",\n'
        '            "lat": 52.52,\n'
        '            "lng": 13.405,\n'
        '            …1 more\n'
        '          }',
      );
    });

    test('nested objects collapse to their shape', () {
      // the error is at the current level, children are only interesting
      // as shape
      final e = grabException(() {
        pick({
          'user': {
            'name': 'Tom',
            'address': {'city': 'Berlin', 'zip': '10115'},
            'tags': ['a', 'b', 'c'],
            'friends': <String>[],
          },
        }, 'user', 'email')
            .required();
      });
      expect(
        e.message,
        'expected a non-null value at user.email, but it is absent\n'
        '\n'
        '  query   user.email\n'
        '               ~~~~~ no such key\n'
        '  at      user = {"name": "Tom", "address": {…2 keys}, '
        '"tags": […3 items], "friends": []}',
      );
    });

    test('keys that are no valid identifiers render in brackets', () {
      final e =
          grabException(() => pick({}, 'user profile', 'name').required());
      expect(
        e.message,
        contains('  query   ["user profile"].name'),
      );
    });

    test('the marker of a key in brackets is as wide as the key', () {
      final e = grabException(() {
        pick({
          'user profile': {'id': 1}
        }, 'user profile', 'name')
            .required();
      });
      expect(
        e.message,
        'expected a non-null value at ["user profile"].name, but it is absent\n'
        '\n'
        '  query   ["user profile"].name\n'
        '                           ~~~~ no such key\n'
        '  at      ["user profile"] = {"id": 1}',
      );
    });

    group('the marker sits under the segment that was not found', () {
      // The part of the query row the marker row points at
      String markedText(PickException e) {
        final rows = e.message.split('\n');
        final query = rows.singleWhere((row) => row.startsWith('  query'));
        final marker = rows[rows.indexOf(query) + 1];
        final start = marker.indexOf('~');
        final end = marker.lastIndexOf('~') + 1;
        expect(marker.substring(0, start).trim(), isEmpty);
        expect(marker.substring(start, end), '~' * (end - start));
        return query.substring(start, end);
      }

      final cases = <String, Pick Function()>{
        'name': () => pick(<String, Object>{}, 'name', 'x'),
        'x': () => pick({'name': <String, Object>{}}, 'name', 'x'),
        '["user profile"]': () =>
            pick({'a': <String, Object>{}}, 'a', 'user profile'),
        '[5]': () => pick({
              'user profile': [1]
            }, 'user profile', 5),
        r'["tab\tkey"]': () =>
            pick({'a': <String, Object>{}}, 'a', 'tab\tkey', 'x'),
        'd': () => pick({
              'a': {
                'b': [
                  {'c': 1}
                ]
              }
            }, 'a', 'b', 0, 'd', 'e'),
        '[1]': () => pick({
              'a': [
                [1, 2]
              ]
            }, 'a', 1, 0),
      };
      for (final entry in cases.entries) {
        test('marks ${entry.key}', () {
          final e = grabException(entry.value().required);
          expect(markedText(e), entry.key);
        });
      }
    });

    test('a Set inside a container is summarized', () {
      final e = grabException(() {
        pick({
          'tags': {'a', 'b'}
        }, 'missing')
            .required();
      });
      expect(
        e.message.split('\n').last,
        '  at      <root> = {"tags": Set with 2 items}',
      );
    });

    test('root errors have no query row', () {
      final e = grabException(() => pick(null).required());
      expect(
        e.message,
        'expected a non-null value at <root>, but it is null\n'
        '\n'
        '  found   null',
      );
    });

    test('toString prefixes the message', () {
      final e = grabException(() => pick(null).required());
      expect(e.toString(), 'PickException: ${e.message}');
    });
  });

  group('the headline says what is wrong', () {
    String headline(void Function() body) {
      return grabException(body).message.split('\n').first;
    }

    test('a value that is absent', () {
      expect(
        headline(() => pick(json, 'shoes', 0, 'name').required()),
        'expected a non-null value at shoes[0].name, but it is absent',
      );
    });

    test('a null value at the end of the path', () {
      expect(
        headline(() => pick({'a': null}, 'a').required()),
        'expected a non-null value at a, but it is null',
      );
    });

    test('a value of the wrong type', () {
      expect(
        headline(() => pick({'count': true}, 'count').asIntOrThrow()),
        'expected an int at count',
      );
    });

    test('a value of the right type that cannot be parsed', () {
      expect(
        headline(() => pick({'count': 'twelve'}, 'count').asIntOrThrow()),
        'could not parse an int at count',
      );
    });

    test('an index into a Set', () {
      final e = grabException(() {
        pick({
          's': {'a', 'b'},
        }, 's', 0);
      });
      expect(
        e.message,
        'cannot pick by index at s[0], it is a Set\n'
        '\n'
        '  query   s[0]\n'
        '           ~~~ a Set is unordered\n'
        '  at      s = Set with 2 items',
      );
    });

    test('the plain constructor keeps the message as it is', () {
      final e = PickException('custom');
      expect(e.message, 'custom');
      expect(e.toString(), 'PickException: custom');
    });
  });

  group('error messages escape control characters', () {
    for (final key in ['line\nbreak', 'tab\tkey', 'quote"key', r'back\slash']) {
      test('special key ${key.codeUnits}', () {
        final e =
            grabException(() => pick({key: 1}, key, 'missing').required());
        final query = e.message
            .split('\n')
            .singleWhere((line) => line.startsWith('  query'));
        expect(query, isNot(contains('\t')));
        expect(query, '  query   [${jsonEncode(key)}].missing');
        expect(e.message.split('\n').length, 5);
      });
    }
    test('expanded map diagnostics escape keys too', () {
      final e = grabException(() {
        pick({
          'line\nbreak': 'x' * 100,
          'other': 'y' * 100,
        }, 'missing')
            .required();
      });
      expect(e.message, contains(r'"line\nbreak":'));
      expect(e.message, isNot(contains('"line\nbreak":')));
    });
    test('newlines are escaped in both query and data values', () {
      final e = grabException(
          () => pick({'line\nbreak': 'value\nline'}, 'missing').required());
      expect(e.message, contains(r'"line\nbreak": "value\nline"'));
      expect(e.message.split('\n').length, 5);
    });
    test('controls above U+001F are escaped in values, keys and the query', () {
      // LINE SEPARATOR, NEXT LINE, C1 CSI, DEL, RIGHT-TO-LEFT OVERRIDE
      const raw = 'x\u2028y\u0085z\u009b31m\u007f\u202e';
      const escaped = r'x\u2028y\u0085z\u009b31m\u007f\u202e';
      final value = grabException(() => pick({'a': raw}, 'a').asIntOrThrow());
      expect(value.message, contains('  found   "$escaped"'));
      final key =
          grabException(() => pick({raw: 1}, raw, 'missing').required());
      expect(key.message, contains('  query   ["$escaped"].missing'));
      final sibling = grabException(() => pick({raw: 1}, 'missing').required());
      expect(sibling.message, contains('  at      <root> = {"$escaped": 1}'));
    });
    test('truncation never splits a surrogate pair', () {
      final value = 'a' * 48 + '😀' * 30;
      final e = grabException(() {
        pick({
          'k': {'v': value}
        }, 'k', 'x')
            .required();
      });
      // the opening quote and 48 characters are kept, the emoji that would
      // have been cut in half is dropped as a whole
      expect(e.message, contains('  at      k = {"v": "${'a' * 48}…}'));
    });
  });

  group('date parsing says what it could not parse', () {
    for (final format in <PickDateFormat?>[null, PickDateFormat.ISO_8601]) {
      test('unknown timezone with format $format', () {
        final e = grabException(() {
          pick({'date': '2021-11-01T11:53:15 CUSTOMERSECRET'}, 'date')
              .asDateTimeOrThrow(format: format);
        });
        expect(
            e.message.split('\n').first, 'could not parse a DateTime at date');
      });
    }
  });
  group('diagnostic edge cases', () {
    test('expanded list shows six items, overflow and closing indentation', () {
      final values = List.generate(7, (i) => '${'x' * 30}$i');
      final e = PickException.fromPick(pick(values), 'expected a Map');
      final rows = e.message.split('\n');
      // the bracket tells the type of a wrapped value
      expect(rows[2], '  found   [');
      expect(rows.sublist(3, 9),
          values.take(6).map((v) => '            ${jsonEncode(v)},').toList());
      expect(rows[9], '            …1 more');
      expect(rows[10], '          ]');
      expect(rows, hasLength(11));
      expect(e.message, isNot(contains(values.last)));
    });

    test('a long map key is truncated like a value', () {
      final longKey = 'k' * 100000;
      final data = {
        'node': {longKey: 1}
      };
      final e = grabException(() => pick(data, 'node', 'missing').required());
      expect(
        e.message.split('\n').last,
        '  at      node = {"${'k' * 49}…: 1}',
      );
    });

    test('long scalar output is bounded and marked as truncated', () {
      final e =
          PickException.fromPick(pick('x' * 200), 'could not parse an int');
      expect(
        e.message.split('\n').last,
        '  found   "${'x' * 99}…  (a String)',
      );
    });

    test('a pick created with Pick.absent claims nothing about the data', () {
      // Pick.absent is told where the path broke, it has no parent to look
      // the data up in
      final absent = Pick.absent(1, path: ['shoes', 'name']);
      expect(
        grabException(absent.required).message,
        'expected a non-null value at shoes.name, but it is absent\n'
        '\n'
        '  query   shoes.name\n'
        '                ~~~~ not found',
      );
    });

    test('a pick built by hand shows the data when picked from', () {
      final shoes = {'id': 1};
      final absent = Pick(shoes, path: ['shoes'])('name');
      final e = grabException(absent.required);
      expect(
        e.message,
        'expected a non-null value at shoes.name, but it is absent\n'
        '\n'
        '  query   shoes.name\n'
        '                ~~~~ no such key\n'
        '  at      shoes = {"id": 1}',
      );
    });

    test('an absent pick has no value', () {
      final absent = pick({
        'shoes': {'id': 1}
      }, 'shoes', 'name');
      expect(absent.isAbsent, isTrue);
      expect(absent.value, isNull);
      expect(absent.asMapOrNull<String, int>(), isNull);
      expect(absent('id').value, isNull);
    });

    test('data that changed after picking still gives a PickException', () {
      final json = <String, Object?>{
        'a': {
          'b': {'x': 1}
        }
      };
      final absent = pick(json, 'a', 'b', 'c');
      json.remove('a');
      final e = grabException(absent.required);
      expect(e.message.split('\n').first,
          'expected a non-null value at a.b.c, but it is absent');
    });

    test('an absent index outside of the path has no marker', () {
      final e = grabException(() => Pick.absent(5, path: ['a']).required());
      expect(
        e.message,
        'expected a non-null value at a, but it is absent\n'
        '\n'
        '  query   a',
      );
      final root = grabException(() => Pick.absent(0).required());
      expect(root.message,
          'expected a non-null value at <root>, but it is absent');
    });

    test('absent and null are read from the pick', () {
      final onNull = PickException.fromPick(
          pick({'a': null}, 'a'), 'expected a Timestamp');
      expect(
        onNull.message,
        'expected a Timestamp at a, but it is null\n'
        '\n'
        '  query   a\n'
        '  found   null',
      );

      final onAbsent = PickException.fromPick(
          pick({'a': null}, 'b'), 'expected a Timestamp');
      expect(
        onAbsent.message,
        'expected a Timestamp at b, but it is absent\n'
        '\n'
        '  query   b\n'
        '          ~ no such key\n'
        '  at      <root> = {"a": null}',
      );

      final onValue =
          PickException.fromPick(pick({'a': 1}, 'a'), 'expected a Timestamp');
      expect(
        onValue.message,
        'expected a Timestamp at a\n'
        '\n'
        '  query   a\n'
        '  found   1  (an int)',
      );
    });

    test('detail gets its own row and keeps the marker text of a broken path',
        () {
      final e = PickException.fromPick(
        pick({'a': 1}, 'b'),
        'expected a non-null value',
        detail: 'custom detail',
      );
      expect(
        e.message,
        'expected a non-null value at b, but it is absent\n'
        '\n'
        '  query   b\n'
        '          ~ no such key\n'
        '  at      <root> = {"a": 1}\n'
        '  detail  custom detail',
      );
    });

    test('custom detail and both hint sources are rendered in order', () {
      final e = PickException.fromPick(
        pick(null).withContext(requiredPickErrorHintKey, 'context hint'),
        'expected a custom value',
        detail: 'custom detail',
        hint: 'factory hint',
      );
      expect(
          e.message,
          'expected a custom value at <root>, but it is null\n\n'
          '  found   null\n'
          '  detail  custom detail\n'
          '  hint    factory hint\n'
          '  hint    context hint');
    });

    test('the OrNull hint is only shown when the value is missing', () {
      // asIntOrNull() is advice for a missing value, "abc" is not missing
      final unparsable =
          grabException(() => pick({'id': 'abc'}, 'id').asIntOrThrow());
      expect(unparsable.message, isNot(contains('hint')));

      final missing =
          grabException(() => pick({'id': 'abc'}, 'nope').asIntOrThrow());
      expect(
        missing.message.split('\n').last,
        '  hint    Use asIntOrNull() when the value may be null/absent at '
        'some point (int?).',
      );
    });

    test('a custom parser error does not advise letOrNull()', () {
      Never parse(RequiredPick pick) {
        throw PickException.fromPick(pick, 'could not parse a Timestamp');
      }

      final e = grabException(() => pick({'ts': 'x'}, 'ts').letOrThrow(parse));
      // letOrNull() runs the same block for a non-null value and throws too
      expect(
        () => pick({'ts': 'x'}, 'ts').letOrNull(parse),
        throwsA(isA<PickException>()),
      );
      expect(
        e.message,
        'could not parse a Timestamp at ts\n'
        '\n'
        '  query   ts\n'
        '  found   "x"  (a String)',
      );
    });

    test('a pick further down does not inherit the hint of its parent', () {
      final data = [
        {'name': 'John Snow'},
        {'no name': 'Daenerys'},
      ];
      String name(RequiredPick pick) => pick('name').required().asString();

      final inList = grabException(() => pick(data).asListOrThrow(name));
      // asListOrEmpty() runs the same callback and throws the same error
      expect(
        () => pick(data).asListOrEmpty(name),
        throwsA(isA<PickException>()),
      );
      expect(
        inList.message,
        'expected a non-null value at [1].name, but it is absent\n'
        '\n'
        '  query   [1].name\n'
        '              ~~~~ no such key\n'
        '  at      [1] = {"no name": "Daenerys"}',
      );

      final inLet = grabException(() => pick(data, 1).letOrThrow(name));
      expect(inLet.message, isNot(contains('letOrNull')));
    });

    test('exception snapshots the message before input mutation', () {
      final path = <Object>['value'];
      final data = <String, Object>{'visible': 'before'};
      final e =
          PickException.fromPick(Pick(data, path: path), 'expected an int');
      final message = e.message;
      path[0] = 'changed';
      data['visible'] = 'after';
      expect(e.message, message);
      expect(e.message, contains('  query   value'));
      expect(e.message, contains('before'));
      expect(e.message, isNot(contains('after')));
    });

    test('bool wrong-type errors name the expected type', () {
      final e = grabException(
          () => pick({'flag': <Object>[]}, 'flag').asBoolOrThrow());
      expect(e.message.split('\n').first, 'expected a bool at flag');
    });

    for (final format in [
      PickDateFormat.RFC_1123,
      PickDateFormat.RFC_850,
      PickDateFormat.ANSI_C_asctime
    ]) {
      test('explicit $format failure names the format', () {
        final e = grabException(() {
          pick({'date': 'CUSTOMERSECRET'}, 'date')
              .asDateTimeOrThrow(format: format);
        });
        expect(
            e.message.split('\n').first, 'could not parse a DateTime at date');
        expect(e.message, contains('does not match $format'));
        expect(e.message, contains('  found   "CUSTOMERSECRET"'));
      });
    }
  });
}
