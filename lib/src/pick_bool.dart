import 'package:deep_pick/src/pick.dart';

extension BoolPick on Pick {
  /// Returns the picked [value] as [bool]
  ///
  /// {@template Pick.asBool}
  /// Only the exact Strings "true" and "false" are valid boolean
  /// representations. Other concepts of booleans such as `1` and `0`,
  /// or "YES" and "NO" are not supported.
  ///
  /// Use `.let()` to parse those custom representations
  /// ```dart
  /// pick(1).letOrNull((pick) {
  ///    if (pick.value == 1) {
  ///      return true;
  ///    }
  ///    if (pick.value == 0) {
  ///      return false;
  ///    }
  ///    return null;
  ///  });
  /// ```
  /// {@endtemplate}
  bool _parse() {
    final value = required().value;
    if (value is bool) {
      return value;
    }
    if (value is String) {
      if (value == 'true') return true;
      if (value == 'false') return false;
    }
    throw PickException(
      'Type ${value.runtimeType} of $debugParsingExit can not be casted to bool',
    );
  }

  /// Returns the picked [value] as [bool] or throws a [PickException]
  ///
  /// {@macro Pick.asBool}
  bool asBoolOrThrow() {
    withContext(
      requiredPickErrorHintKey,
      'Use asBoolOrNull() when the value may be null/absent at some point (bool?).',
    );
    return _parse();
  }

  /// Returns the picked [value] as [bool] or `null` if it can't be interpreted
  /// as [bool].
  ///
  /// {@macro Pick.asBool}
  bool? asBoolOrNull() {
    if (value == null) return null;
    try {
      return _parse();
    } catch (_) {
      return null;
    }
  }

  /// Returns the picked [value] as [bool] or defaults to `true` when the
  /// [value] is `null` or can't be interpreted as [bool].
  ///
  /// {@macro Pick.asBool}
  bool asBoolOrTrue() {
    if (value == null) return true;
    try {
      return _parse();
    } catch (_) {
      return true;
    }
  }

  /// Returns the picked [value] as [bool] or defaults to `false` when the
  /// [value] is `null` or can't be interpreted as [bool].
  ///
  /// {@macro Pick.asBool}
  bool asBoolOrFalse() {
    if (value == null) return false;
    try {
      return _parse();
    } catch (_) {
      return false;
    }
  }
}
