import 'package:deep_pick/src/pick.dart';

extension DoublePick on RequiredPick {
  double asDouble() {
    final value = this.value;
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
    throw PickException('value $value of type ${value.runtimeType} '
        'at location ${location()} can not be parsed as double');
  }
}

extension NullableDoublePick on Pick {
  @Deprecated('Use .asDoubleOrThrow()')
  double Function() get asDouble => asDoubleOrThrow;

  double asDoubleOrThrow() {
    withContext(requiredPickErrorHintKey,
        'Use asDoubleOrNull() when the value may be null/absent at some point (double?).');
    return required().asDouble();
  }

  double? asDoubleOrNull() {
    if (value == null) return null;
    try {
      return required().asDouble();
    } catch (_) {
      return null;
    }
  }
}
