import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

import 'pick_test.dart';

void main() {
  group('custom parser from the README', () {
    final timestamp = Timestamp.fromMillisecondsSinceEpoch(5);
    final json = {
      'millis': 1700000000000,
      'timestamp': timestamp,
      'text': 'tomorrow',
      'nothing': null,
    };

    test('asFirestoreTimeStampOrThrow()', () {
      expect(
        pick(json, 'millis').asFirestoreTimeStampOrThrow().millis,
        1700000000000,
      );
      expect(
        pick(json, 'timestamp').asFirestoreTimeStampOrThrow(),
        same(timestamp),
      );
      expect(
        () => pick(json, 'text').asFirestoreTimeStampOrThrow(),
        throwsA(
          pickException(
            containing: ['expected a Timestamp at text', '"tomorrow"'],
          ),
        ),
      );
    });

    test('a missing value advises the OrNull parser', () {
      expect(
        () => pick(json, 'nothing').asFirestoreTimeStampOrThrow(),
        throwsA(
          pickException(
            containing: [
              'expected a non-null value at nothing, but it is null',
              'Use asFirestoreTimeStampOrNull() when the value may be null/absent at some point (Timestamp?).',
            ],
          ),
        ),
      );
      expect(
        () => pick(json, 'unknownKey').asFirestoreTimeStampOrThrow(),
        throwsA(
          pickException(
            containing: [
              'expected a non-null value at unknownKey, but it is absent',
              'Use asFirestoreTimeStampOrNull() when the value may be null/absent at some point (Timestamp?).',
            ],
          ),
        ),
      );
    });

    test('asFirestoreTimeStampOrNull()', () {
      expect(
        pick(json, 'millis').asFirestoreTimeStampOrNull()?.millis,
        1700000000000,
      );
      expect(pick(json, 'text').asFirestoreTimeStampOrNull(), isNull);
      expect(pick(json, 'nothing').asFirestoreTimeStampOrNull(), isNull);
      expect(pick(json, 'unknownKey').asFirestoreTimeStampOrNull(), isNull);
    });
  });
}

/// Stands in for the `Timestamp` of `package:cloud_firestore`
class Timestamp {
  Timestamp.fromMillisecondsSinceEpoch(this.millis);

  final int millis;
}

/// The custom parser of the README, written with the exported API only
extension TimestampPick on Pick {
  Timestamp _parse(Object value) {
    if (value is Timestamp) {
      return value;
    }
    if (value is int) {
      return Timestamp.fromMillisecondsSinceEpoch(value);
    }
    throw PickException.fromPick(this, 'expected a Timestamp');
  }

  Timestamp asFirestoreTimeStampOrThrow() {
    final value = this.value;
    if (value == null) {
      throw PickException.fromPick(
        this,
        'expected a non-null value',
        hint:
            'Use asFirestoreTimeStampOrNull() when the value may be null/absent at some point (Timestamp?).',
      );
    }
    return _parse(value);
  }

  Timestamp? asFirestoreTimeStampOrNull() {
    final value = this.value;
    if (value == null) return null;
    try {
      return _parse(value);
    } catch (_) {
      return null;
    }
  }
}
