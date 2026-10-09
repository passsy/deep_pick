import 'dart:convert';

import 'package:deep_pick/deep_pick.dart';
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
        () =>
            pick({'meta': 'yes'}, 'meta').asListOrThrow((it) => it.asString()),
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
        () => pick(json)
            .redactValues()('shoes')
            .asListOrThrow((it) => it('name').required().asString()),
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
        () => pick({
          's': {'a', 'b'},
        }, 's', 0),
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
      final e = grabException(() => pick({
            'line\nbreak': 'x' * 100,
            'other': 'y' * 100,
          }, 'missing')
              .required());
      expect(e.message, contains(r'"line\nbreak":'));
      expect(e.message, isNot(contains('"line\nbreak":')));
    });
    test('newlines are escaped in both query and data values', () {
      final e = grabException(
          () => pick({'line\nbreak': 'value\nline'}, 'missing').required());
      expect(e.message, contains(r'"line\nbreak": "value\nline"'));
      expect(e.message.split('\n').length, 5);
    });
  });

  group('date parsing preserves structured errors and redaction', () {
    for (final format in <PickDateFormat?>[null, PickDateFormat.ISO_8601]) {
      test('unknown timezone with format $format', () {
        final e = grabException(() =>
            pick({'date': '2021-11-01T11:53:15 CUSTOMERSECRET'})
                .redactValues()('date')
                .asDateTimeOrThrow(format: format));
        expect(e.message, isNot(contains('CUSTOMERSECRET')));
        expect(e.reason, PickErrorReason.unparsable);
        expect(e.expected, 'a DateTime');
        expect(e.path, ['date']);
      });
    }
  });
}
