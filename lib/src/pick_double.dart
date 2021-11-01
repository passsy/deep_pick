import 'package:deep_pick/src/pick.dart';

extension NullableDoublePick on Pick {
  /// Returns the picked [value] as [double]
  ///
  /// {@template Pick.asDouble}
  /// Parses the picked value as [double]. Also tries to parse [String] as [double]
  /// via [double.tryParse]
  /// {@endtemplate}
  double _parse() {
    final value = required().value;
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      var parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
      // remove all spaces
      final prepared = value.replaceAll(' ', '');

      if (prepared.contains(',') && !prepared.contains('.')) {
        // Germans use , instead of . as decimal separator
        // 12,56 -> 12.56
        parsed = double.tryParse(prepared.replaceAll(',', '.'));
        if (parsed != null) {
          return parsed;
        }
      }

      // handle digit group separators
      final firstDot = prepared.indexOf('.');
      final firstComma = prepared.indexOf(',');

      if (firstDot <= firstComma) {
        // the germans again
        // 10.000,00
        parsed =
            double.tryParse(prepared.replaceAll('.', '').replaceAll(',', '.'));
        if (parsed != null) {
          return parsed;
        }
      } else {
        // 10,000.00
        parsed = double.tryParse(prepared.replaceAll(',', ''));
        if (parsed != null) {
          return parsed;
        }
      }
    }
    throw PickException(
      'Type ${value.runtimeType} of $debugParsingExit can not be parsed as double',
    );
  }

  /// Returns the picked [value] as [double] or throws
  ///
  /// {@macro Pick.asDouble}
  double asDoubleOrThrow() {
    withContext(
      requiredPickErrorHintKey,
      'Use asDoubleOrNull() when the value may be null/absent at some point (double?).',
    );
    return _parse();
  }

  /// Returns the picked [value] as [double?] or returns `null` when the picked
  /// value is absent
  ///
  /// {@macro Pick.asDouble}
  double? asDoubleOrNull() {
    if (value == null) return null;
    try {
      return _parse();
    } catch (_) {
      return null;
    }
  }
}
