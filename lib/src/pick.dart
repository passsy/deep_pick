/// Picks the value of [json] at location arg0, arg1 ... arg9
///
/// args may be
/// - a [String] to pick values from a [Map]
/// - or [int] when you want to pick a value at index from a [List]
Pick pick(
  dynamic json, [
  dynamic arg0,
  dynamic arg1,
  dynamic arg2,
  dynamic arg3,
  dynamic arg4,
  dynamic arg5,
  dynamic arg6,
  dynamic arg7,
  dynamic arg8,
  dynamic arg9,
]) {
  if (json == null) return Pick._(null, const []);
  final selectors = <dynamic>[arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9]
      .where((dynamic it) => it != null)
      .toList(growable: false);
  final List<dynamic> path = [];
  dynamic data = json;
  for (final selector in selectors) {
    path.add(selector);
    if (data is List) {
      if (selector is int) {
        data = data[selector];
        continue;
      } else {
        throw PickException("'$selector' is not a valid index for List, expected int.");
      }
    }
    if (data is Map) {
      data = data[selector];
      continue;
    }
    // can't drill down any more to find the exact location.
    return Pick._(null, path);
  }
  return Pick._(data, path);
}

class Pick {
  /// private constructor, no need to expose it
  Pick._(this.value, [this.path = const []]);

  /// The picked value
  dynamic value;
  List<dynamic> path;

  String asString() {
    _verifyNonNull("String");
    if (value is String) {
      return value as String;
    } else {
      if (value is List || value is Map) {
        throw PickException("value at location ${_location()} is of type ${value.runtimeType}. "
            "Drill further down to a value which is not a List or Map. "
            "value: $value");
      }
      return value.toString();
    }
  }

  String /*?*/ asStringOrNull() {
    if (value == null) return null;
    if (value is String) {
      return value as String;
    } else {
      return value.toString();
    }
  }

  Map<String, dynamic> asMap() {
    _verifyNonNull("Map<String, dynamic>");
    if (value is Map<String, dynamic>) {
      return value as Map<String, dynamic>;
    } else {
      throw PickException(
          "value $value of type ${value.runtimeType} at location ${_location()} can't be casted to Map<String, dynamic>");
    }
  }

  Map<String, dynamic> asMapOrEmpty() {
    if (value == null) return const <String, dynamic>{};
    if (value is Map<String, dynamic>) {
      return value as Map<String, dynamic>;
    } else {
      return const <String, dynamic>{};
    }
  }

  Map<String, dynamic> /*?*/ asMapOrNull() {
    if (value == null) return null;
    if (value is Map<String, dynamic>) {
      return value as Map<String, dynamic>;
    } else {
      return null;
    }
  }

  List<T> asList<T>() {
    _verifyNonNull("List<$T>");
    if (value is List) {
      return (value as List<dynamic>).cast<T>();
    } else {
      throw PickException(
          "value $value of type ${value.runtimeType} at location ${_location()} can't be casted to List<dynamic>");
    }
  }

  List<T> asListOrEmpty<T>() {
    if (value == null) return <T>[];
    if (value is List<dynamic>) {
      return (value as List<dynamic>).cast<T>();
    } else {
      return <T>[];
    }
  }

  List<T> /*?*/ asListOrNull<T>() {
    if (value == null) return null;
    if (value is List<dynamic>) {
      return (value as List<dynamic>).cast<T>();
    } else {
      return null;
    }
  }

  bool asBool() {
    _verifyNonNull("bool");
    if (value is bool) {
      return value as bool;
    } else {
      throw PickException(
          "value $value of type ${value.runtimeType} at location ${_location()} can't be casted to bool");
    }
  }

  bool /*?*/ asBoolOrNull() {
    if (value == null) return null;
    if (value is bool) {
      return value as bool;
    } else {
      return null;
    }
  }

  bool asBoolOrTrue() {
    if (value == null) return true;
    if (value is bool) {
      return value as bool;
    } else {
      return true;
    }
  }

  bool asBoolOrFalse() {
    if (value == null) return false;
    if (value is bool) {
      return value as bool;
    } else {
      return false;
    }
  }

  int asInt() {
    _verifyNonNull("int");
    if (value is int) {
      return value as int;
    } else if (value is num) {
      return (value as num).toInt();
    } else if (value is String) {
      final parsed = int.tryParse(value as String);
      if (parsed != null) {
        return parsed;
      }
    }
    throw PickException(
        "value $value of type ${value.runtimeType} at location ${_location()} can't be casted to int");
  }

  int /*?*/ asIntOrNull() {
    if (value == null) return null;
    if (value is int) {
      return value as int;
    } else if (value is num) {
      return (value as num).toInt();
    } else if (value is String) {
      final parsed = int.tryParse(value as String);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  double asDouble() {
    _verifyNonNull("double");
    if (value is double) {
      return value as double;
    } else if (value is num) {
      return (value as num).toDouble();
    } else if (value is String) {
      final parsed = double.tryParse(value as String);
      if (parsed != null) {
        return parsed;
      }
    }
    throw PickException(
        "value $value of type ${value.runtimeType} at location ${_location()} can't be casted to double");
  }

  double asDoubleOrNull() {
    if (value == null) return null;
    if (value is double) {
      return value as double;
    } else if (value is num) {
      return (value as num).toDouble();
    } else if (value is String) {
      final parsed = double.tryParse(value as String);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  /// Examples of parsable date formats:
  ///
  /// - `"2012-02-27 13:27:00"`
  /// - `"2012-02-27 13:27:00.123456z"`
  /// - `"2012-02-27 13:27:00,123456z"`
  /// - `"20120227 13:27:00"`
  /// - `"20120227T132700"`
  /// - `"20120227"`
  /// - `"+20120227"`
  /// - `"2012-02-27T14Z"`
  /// - `"2012-02-27T14+00:00"`
  /// - `"-123450101 00:00:00 Z"`: in the year -12345.
  /// - `"2002-02-27T14:00:00-0500"`: Same as `"2002-02-27T19:00:00Z"`
  DateTime asDateTime() {
    _verifyNonNull("DateTime");
    if (value is String) {
      final dateTime = DateTime.tryParse(value as String);
      if (dateTime != null) {
        return dateTime;
      }
    }
    throw PickException(
        "value $value of type ${value.runtimeType} at location ${_location()} can't be parsed as DateTime");
  }

  /// Examples of parsable date formats:
  ///
  /// - `"2012-02-27 13:27:00"`
  /// - `"2012-02-27 13:27:00.123456z"`
  /// - `"2012-02-27 13:27:00,123456z"`
  /// - `"20120227 13:27:00"`
  /// - `"20120227T132700"`
  /// - `"20120227"`
  /// - `"+20120227"`
  /// - `"2012-02-27T14Z"`
  /// - `"2012-02-27T14+00:00"`
  /// - `"-123450101 00:00:00 Z"`: in the year -12345.
  /// - `"2002-02-27T14:00:00-0500"`: Same as `"2002-02-27T19:00:00Z"`
  DateTime asDateTimeOrNull() {
    if (value == null) return null;
    if (value is String) {
      final dateTime = DateTime.tryParse(value as String);
      if (dateTime != null) {
        return dateTime;
      }
    }
    return null;
  }

  void _verifyNonNull(String expectedType) {
    if (value == null) {
      throw PickException("value at location ${_location()} is null and not an instance of $expectedType");
    }
  }

  String _location() {
    return path.map((it) => "`$it`").join(",");
  }
}

class PickException implements Exception {
  PickException(this.message);

  final String message;

  @override
  String toString() {
    return 'PickException{message: $message}';
  }
}
