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
    for (final redact in [false, true]) {
      for (final expanded in [false, true]) {
        test(
            'opaque sibling keys preserve parsing errors '
            '(redact=$redact, expanded=$expanded)', () {
          final source = <Object, Object>{
            if (expanded)
              for (var i = 0; i < 5; i++) 'key$i': 'visible' * 10,
            UnprintableValue(): 'PRIVATE_VALUE',
          };
          expect(source.containsKey('missing'), isFalse);
          final original = pick(source, 'missing');
          expect(original.isAbsent, isTrue);
          expect(original.path, ['missing']);
          final result = redact ? original.redactValues() : original;
          expect(result.lastReachableValue, same(source));
          final e = grabException(result.required);
          expect(e.reason, PickErrorReason.absent);
          expect(e.path, ['missing']);
          expect(e.expected, 'a non-null value');
          expect(e.message, contains('"<UnprintableValue>"'));
          if (redact) {
            expect(e.message, contains('Map with keys'));
            expect(e.message, isNot(contains('PRIVATE_VALUE')));
          } else if (expanded) {
            expect(e.message, contains('  at      <root> = {\n'));
            expect(e.message,
                contains('            "<UnprintableValue>": "PRIVATE_VALUE",'));
          } else {
            expect(
                e.message, contains('{"<UnprintableValue>": "PRIVATE_VALUE"}'));
          }
        });
      }
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
          (error) => error.reason,
          'reason',
          PickErrorReason.absent,
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

    test('wrong type shows the found value and type', () {
      final e = grabException(
        () {
          pick({'meta': 'yes'}, 'meta').asListOrThrow((it) => it.asString());
        },
      );
      expect(
        e.message,
        'expected a List at meta, found a String\n'
        '\n'
        '  query   meta\n'
        '  found   "yes"  (a String)\n'
        '  hint    Use asListOrEmpty()/asListOrNull() when the value may be '
        'null/absent at some point (List<String>?).',
      );
    });

    test('extension hints get their own row', () {
      final e = grabException(
        () => pick({'price': 12.5}, 'price').asIntOrThrow(),
      );
      expect(
        e.message,
        'expected an int at price, found a double\n'
        '\n'
        '  query   price\n'
        '  found   12.5  (a double)\n'
        '  hint    set roundDouble: true or truncateDouble: true to parse a '
        'double as int\n'
        '  hint    Use asIntOrNull() when the value may be null/absent at '
        'some point (int?).',
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

  group('redactValues', () {
    test('returns an independent view without changing existing picks', () {
      final original =
          pick({'secret': 'PRIVATE_VALUE'}).withContext('custom', 'kept');
      final existingChild = original('secret');
      final redacted = original.redactValues();
      expect(redacted, isNot(same(original)));
      expect(redacted.value, same(original.value));
      expect(redacted.path, original.path);
      expect(redacted.context['custom'], 'kept');
      expect(original.context.containsKey('_redact_values'), isFalse);
      expect(existingChild.context.containsKey('_redact_values'), isFalse);
      expect(redacted('secret').context['_redact_values'], isTrue);
      redacted.withContext('custom', 'changed');
      expect(original.context['custom'], 'kept');
    });

    test('preserves absent state and last reachable value in a copy', () {
      final original =
          pick({'nested': <String, Object>{}}, 'nested', 'missing');
      final redacted = original.redactValues();
      expect(redacted, isNot(same(original)));
      expect(redacted.isAbsent, isTrue);
      expect(redacted.missingValueAtIndex, original.missingValueAtIndex);
      expect(redacted.lastReachableValue, same(original.lastReachableValue));
      expect(redacted.path, original.path);
      expect(
          redacted('child').missingValueAtIndex, original.missingValueAtIndex);
      expect(grabException(redacted.required).message,
          contains('Map with no keys'));
    });

    test('preserves explicit null in a redacted copy', () {
      final original = pick({'value': null}, 'value');
      final redacted = original.redactValues();
      expect(redacted.isAbsent, isFalse);
      expect(redacted.value, isNull);
      expect(redacted.path, ['value']);
      expect(redacted.context['_redact_values'], isTrue);
    });

    test('RequiredPick copy leaves the original context unchanged', () {
      final original = pick({'secret': 'PRIVATE_VALUE'}).required();
      final redacted = original.redactValues();
      expect(redacted, isNot(same(original)));
      expect(redacted.value, same(original.value));
      expect(original.context.containsKey('_redact_values'), isFalse);
      expect(redacted.context['_redact_values'], isTrue);
    });

    test('masks values but keeps Map keys', () {
      final e = grabException(
        () => pick(json).redactValues()('shoes', 0, 'name').required(),
      );
      expect(
        e.message,
        'expected a non-null value at shoes[0].name, but it is absent\n'
        '\n'
        '  query   shoes[0].name\n'
        '                   ~~~~ no such key\n'
        '  at      shoes[0] = Map with keys "id", "size"',
      );
    });

    test('masks scalar values as their type', () {
      final e = grabException(
        () => pick({'count': 'twelve'}).redactValues()('count').asIntOrThrow(),
      );
      expect(
        e.message,
        'could not parse an int at count\n'
        '\n'
        '  query   count\n'
        '  found   <String>\n'
        '  hint    Use asIntOrNull() when the value may be null/absent at '
        'some point (int?).',
      );
    });

    test('propagates from the root into list element picks', () {
      final e = grabException(
        () {
          pick(json)
              .redactValues()('shoes')
              .asListOrThrow((it) => it('name').required().asString());
        },
      );
      expect(e.message, contains('Map with keys "id", "size"'));
      expect(e.message, isNot(contains('42')));
      expect(e.message, isNot(contains('"M"')));
    });

    test('RequiredPick.redactValues() stays chainable', () {
      final RequiredPick redacted = pick(json).required().redactValues();
      final e = grabException(() {
        redacted.let((it) => it('shoes', 0, 'material').required());
      });
      expect(e.message, contains('Map with keys "id", "size"'));
    });
  });

  group('structured fields', () {
    test('known error reasons have stable names and constant identity', () {
      const absent = PickErrorReason.absent;
      expect(absent, same(PickErrorReason.absent));
      expect(absent.name, 'absent');
      expect(absent.toString(), 'PickErrorReason.absent');
      expect(PickErrorReason.nullValue.name, 'nullValue');
      expect(PickErrorReason.wrongType.name, 'wrongType');
      expect(PickErrorReason.unparsable.name, 'unparsable');
      expect(PickErrorReason.setIndexUnsupported.name, 'setIndexUnsupported');
      expect(absent, isNot(PickErrorReason.nullValue));
    });

    test('fromPick fills path, reason and expected', () {
      final e = grabException(
        () => pick(json, 'shoes', 0, 'name').required(),
      );
      expect(e.path, ['shoes', 0, 'name']);
      expect(e.reason, PickErrorReason.absent);
      expect(e.expected, 'a non-null value');
    });

    test('wrong type reports the requested type', () {
      final e = grabException(
        () => pick({'count': true}, 'count').asIntOrThrow(),
      );
      expect(e.path, ['count']);
      expect(e.reason, PickErrorReason.wrongType);
      expect(e.expected, 'an int');
    });

    test('unparsable is distinguished from wrongType', () {
      final e = grabException(
        () => pick({'count': 'twelve'}, 'count').asIntOrThrow(),
      );
      expect(e.reason, PickErrorReason.unparsable);
    });

    test('null value at the end of the path', () {
      final e = grabException(() => pick({'a': null}, 'a').required());
      expect(e.reason, PickErrorReason.nullValue);
    });

    test('set index errors carry the reason', () {
      final e = grabException(
        () {
          pick({
            's': {'a', 'b'},
          }, 's', 0);
        },
      );
      expect(e.reason, PickErrorReason.setIndexUnsupported);
      expect(e.path, ['s', 0]);
    });

    test('plain constructor keeps the fields null', () {
      final e = PickException('custom');
      expect(e.message, 'custom');
      expect(e.path, isNull);
      expect(e.reason, isNull);
      expect(e.expected, isNull);
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
        expect(e.path, [key, 'missing']);
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

  group('date parsing preserves structured errors and redaction', () {
    for (final format in <PickDateFormat?>[null, PickDateFormat.ISO_8601]) {
      test('unknown timezone with format $format', () {
        final e = grabException(() {
          pick({'date': '2021-11-01T11:53:15 CUSTOMERSECRET'})
              .redactValues()('date')
              .asDateTimeOrThrow(format: format);
        });
        expect(e.message, isNot(contains('CUSTOMERSECRET')));
        expect(e.reason, PickErrorReason.unparsable);
        expect(e.expected, 'a DateTime');
        expect(e.path, ['date']);
      });
    }
  });
  group('diagnostic edge cases', () {
    test('expanded list shows six items, overflow and closing indentation', () {
      final values = List.generate(7, (i) => '${'x' * 30}$i');
      final e = PickException.fromPick(
        pick(values),
        reason: PickErrorReason.wrongType,
        expected: 'a Map',
      );
      final rows = e.message.split('\n');
      expect(rows[2], '  found   [  (a List)');
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
      final redacted = grabException(() {
        pick(data).redactValues()('node', 'missing').required();
      });
      expect(
        redacted.message.split('\n').last,
        '  at      node = Map with keys "${'k' * 49}…',
      );
    });

    test('long scalar output is bounded and marked as truncated', () {
      final e = PickException.fromPick(
        pick('x' * 200),
        reason: PickErrorReason.unparsable,
        expected: 'an int',
      );
      expect(e.message.split('\n').last, '  found   "${'x' * 99}…');
    });

    final summaries = <Object?, String>{
      <String, Object>{}: 'Map with no keys',
      <String, Object>{
        for (var i = 0; i < 10; i++) 'key$i': 'secret'
      }: 'Map with keys "key0", "key1", "key2", "key3", "key4", "key5", "key6", "key7", …2 more',
      <String>[]: 'List with 0 items',
      ['secret']: 'List with 1 item',
      ['secret', 'other']: 'List with 2 items',
      <String>{}: 'Set with 0 items',
      {'secret', 'other'}: 'Set with 2 items',
      null: 'null',
    };
    for (final entry in summaries.entries) {
      test('redacted summary ${entry.value}', () {
        final e = PickException.fromPick(
          pick(entry.key).redactValues(),
          reason: PickErrorReason.unparsable,
          expected: 'an int',
        );
        expect(e.message.split('\n').last, '  found   ${entry.value}');
        expect(e.message, isNot(contains('secret')));
      });
    }

    test('an absent pick without a last reachable value claims nothing', () {
      // the only way to build an absent pick before lastReachableValue existed
      final e = grabException(
        () => Pick.absent(1, path: ['shoes', 'name']).required(),
      );
      expect(
        e.message,
        'expected a non-null value at shoes.name, but it is absent\n'
        '\n'
        '  query   shoes.name\n'
        '                ~~~~ not found',
      );
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

    test('absent and null are taken from the pick, not from the caller', () {
      final onNull = PickException.fromPick(
        pick({'a': null}, 'a'),
        reason: PickErrorReason.absent,
      );
      expect(onNull.reason, PickErrorReason.nullValue);
      expect(onNull.message, contains('but it is null'));

      final onAbsent = PickException.fromPick(
        pick({'a': null}, 'b'),
        reason: PickErrorReason.wrongType,
        expected: 'a Timestamp',
      );
      expect(onAbsent.reason, PickErrorReason.absent);
      expect(
        onAbsent.message,
        'expected a Timestamp at b, but it is absent\n'
        '\n'
        '  query   b\n'
        '          ~ no such key\n'
        '  at      <root> = {"a": null}',
      );

      final onValue = PickException.fromPick(
        pick({'a': 1}, 'a'),
        reason: PickErrorReason.absent,
      );
      expect(onValue.message.split('\n').last, '  found   1');
    });

    test('detail gets its own row and keeps the marker text of a broken path',
        () {
      final e = PickException.fromPick(
        pick({'a': 1}, 'b'),
        reason: PickErrorReason.absent,
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
        pick('bad').withContext(requiredPickErrorHintKey, 'context hint'),
        reason: PickErrorReason.unparsable,
        expected: 'a custom value',
        detail: 'custom detail',
        hint: 'factory hint',
      );
      expect(
          e.message,
          'could not parse a custom value at <root>\n\n'
          '  found   "bad"\n'
          '  detail  custom detail\n'
          '  hint    factory hint\n'
          '  hint    context hint');
    });

    test('exception snapshots path and message before input mutation', () {
      final path = <Object>['value'];
      final data = <String, Object>{'visible': 'before'};
      final e = PickException.fromPick(
        Pick(data, path: path),
        reason: PickErrorReason.wrongType,
        expected: 'an int',
      );
      final message = e.message;
      path[0] = 'changed';
      data['visible'] = 'after';
      expect(e.path, ['value']);
      expect(() => e.path!.add('extra'), throwsUnsupportedError);
      expect(e.message, message);
      expect(e.message, contains('before'));
      expect(e.message, isNot(contains('after')));
    });

    test('bool wrong-type errors carry structured fields', () {
      final e = grabException(
          () => pick({'flag': <Object>[]}, 'flag').asBoolOrThrow());
      expect(e.reason, PickErrorReason.wrongType);
      expect(e.expected, 'a bool');
      expect(e.path, ['flag']);
    });

    for (final format in [
      PickDateFormat.RFC_1123,
      PickDateFormat.RFC_850,
      PickDateFormat.ANSI_C_asctime
    ]) {
      test('explicit $format failure keeps structure and redaction', () {
        final e = grabException(() {
          pick({'date': 'CUSTOMERSECRET'})
              .redactValues()('date')
              .asDateTimeOrThrow(format: format);
        });
        expect(e.reason, PickErrorReason.unparsable);
        expect(e.expected, 'a DateTime');
        expect(e.path, ['date']);
        expect(e.message, contains('does not match $format'));
        expect(e.message, contains('  found   <String>'));
        expect(e.message, isNot(contains('CUSTOMERSECRET')));
      });
    }
  });
}
