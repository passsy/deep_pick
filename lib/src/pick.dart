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
  return _drillDown(json, selectors);
}

Pick _drillDown(dynamic json, List<dynamic> selectors,
    {List<dynamic> parentPath = const [], Map<String, dynamic> context}) {
  assert(selectors != null);
  assert(parentPath != null);
  final newPath = [...parentPath, ...selectors];
  // no data, nothing to pick
  if (json == null) return Pick(null, path: newPath, context: context);

  assert(json != null);
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
          return Pick(null, path: newPath, context: context);
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
        return Pick(null, path: newPath, context: context);
      }
    }
    if (data is Set && selector is int) {
      throw PickException(
          'Value at location ${path.sublist(0, path.length - 1)} is a Set, which is a unordered data structure. '
          "It's not possible to pick a value by using a index ($selector)");
    }
    // can't drill down any more to find the exact location.
    return Pick(null, path: newPath, context: context);
  }
  return Pick(data, path: newPath, context: context);
}

/// A picked object holding the [value] and giving access to useful parsing functions
class Pick with PickLocation, PickContext<Pick> {
  Pick(this.value, {this.path = const [], Map<String, dynamic> context})
      : _context = context != null ? Map.of(context) : {},
        assert(path != null);

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
  ]) {
    final selectors =
        <dynamic>[arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9]
            // null is a sign for unused 'varargs'
            .where((dynamic it) => it != null)
            .toList(growable: false);

    return _drillDown(value, selectors, parentPath: path, context: context);
  }

  @override
  Map<String, dynamic> get context => _context;
  final Map<String, dynamic> _context;

  /// Converts the picked values to a non-nullable type [RequiredPick].
  ///
  /// Crashes when the the value is `null`.
  RequiredPick required() {
    if (value == null) {
      throw PickException('required value at location ${location()} is null');
    }
    return RequiredPick(value, path: path, context: _context);
  }

  @override
  @Deprecated('Use asStringOrNull() to pick a String value')
  String toString() => 'Pick(value=$value, path=$path)';

  @override
  Pick get _builder => this;
}

class RequiredPick with PickLocation, PickContext<RequiredPick> {
  RequiredPick(this.value, {this.path = const [], Map<String, dynamic> context})
      : _context = context != null ? Map.of(context) : {},
        assert(path != null) {
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
  ]) {
    final selectors =
        <dynamic>[arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9]
            // null is a sign for unused 'varargs'
            .where((dynamic it) => it != null)
            .toList(growable: false);

    return _drillDown(value, selectors, parentPath: path, context: context);
  }

  @override
  Map<String, dynamic> get context => _context ?? const {};
  final Map<String, dynamic> _context;

  @override
  @Deprecated('Use asStringOrNull() to pick a String value')
  String toString() => 'RequiredPick(value=$value, path=$path)';

  @override
  RequiredPick get _builder => this;
}

class PickException implements Exception {
  PickException(this.message);

  final String message;

  @override
  String toString() {
    return 'PickException($message)';
  }
}

/// Context API allows storing additional information in a [Map]
mixin PickContext<T> {
  /// Attaches additional information which can be used during parsing.
  /// i.e the HTTP request/response including headers
  Map<String, dynamic> get context;

  /// Reference to mixer class
  T get _builder;

  /// Attaches additional information which can be used during parsing.
  /// i.e the HTTP request/response including headers
  ///
  /// Use this method to chain methods. It's pure syntax sugar.
  /// The alternative cascade operator often requires additional parenthesis
  T addContext(String key, dynamic value) {
    context[key] = value;
    return _builder;
  }

  /// Pick values from the context using the [Pick] API
  ///
  /// `pick.fromContext('apiVersion').asIntOrNull();`
  Pick fromContext(String key) {
    return pick(context);
  }
}

mixin PickLocation {
  /// The path to [value] inside of the object
  ///
  /// I.e. ['shoes', 0, 'name']
  List<dynamic> get path;

  String location() => path.map((it) => '`$it`').join(',');
}
