/// Picks the value of [json] at location arg0, arg1 ... arg9
///
/// args may be
/// - a [String] to pick values from a [Map]
/// - or [int] when you want to pick a value at index from a [List]
Pick pick(
  /*Map?|List?*/ dynamic json, [
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
  final selectors =
      <dynamic>[arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9]
          // null is a sign for unused 'varargs'
          .where((dynamic it) => it != null)
          .toList(growable: false);

  // no data, nothing to pick
  if (json == null) return Pick(null, selectors);

  final path = <dynamic>[];
  dynamic data = json;
  for (final selector in selectors) {
    path.add(selector);
    if (data is List) {
      if (selector is int) {
        try {
          data = data[selector];
          continue;
        } catch (_) {
          // out of range, value not found at index selector
          return Pick(null, selectors);
        }
      }
    }
    if (data is Map) {
      final picked = data[selector];
      if (picked != null) {
        data = picked;
        continue;
      } else {
        // no value mapped to selector
        return Pick(null, selectors);
      }
    }
    if (data is Set && selector is int) {
      throw PickException(
          'Value at location ${path.sublist(0, path.length - 1)} is a Set, which is a unordered data structure. '
          "It's not possible to pick a value by using a index ($selector)");
    }
    // can't drill down any more to find the exact location.
    return Pick(null, selectors);
  }
  return Pick(data, selectors);
}

/// A picked object holding the [value] and giving access to useful parsing functions
class Pick with PickLocation {
  Pick(this.value, [this.path = const []]);

  /// The picked value, might be `null`
  Object /*?*/ value;

  @override
  List<dynamic> path;

  // Pick even further
  Pick call([
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
  ]) =>
      pick(value, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9);

  /// Converts the picked values to a non-nullable type [RequiredPick].
  ///
  /// Crashes when the the value is `null`.
  RequiredPick required() {
    if (value == null) {
      throw PickException('required value at location ${location()} is null');
    }
    return RequiredPick(value, path);
  }

  @override
  @Deprecated('Use asStringOrNull() to pick a String value')
  String toString() => 'Pick(value=$value, path=$path)';
}

class RequiredPick with PickLocation {
  RequiredPick(this.value, [this.path = const []]) {
    if (value == null) {
      throw StateError("value can't be null");
    }
  }

  /// The picked value, never `null`
  Object value;

  @override
  List<dynamic> path;

  // Pick even further
  Pick call([
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
  ]) =>
      pick(value, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9);

  @override
  @Deprecated('Use asStringOrNull() to pick a String value')
  String toString() => 'RequiredPick(value=$value, path=$path)';
}

class PickException implements Exception {
  PickException(this.message);

  final String message;

  @override
  String toString() {
    return 'PickException($message)';
  }
}

mixin PickLocation {
  /// The path to [value] inside of the object
  ///
  /// I.e. ['shoes', 0, 'name']
  List<dynamic> get path;

  String location() => path.map((it) => '`$it`').join(',');
}
