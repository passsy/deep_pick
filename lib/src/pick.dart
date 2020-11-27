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
    {List<dynamic> parentPath = const [], Map<String, dynamic>? context}) {
  final fullPath = [...parentPath, ...selectors];
  // no data, nothing to pick
  // if (json == null) return Pick(null, fullPath: fullPath, context: context);

  final path = <dynamic>[];
  dynamic data = json;
  for (final selector in selectors) {
    path.add(selector);
    if (data is List) {
      if (selector is int) {
        try {
          data = data[selector];
          if (data == null) {
            return Pick(null, fullPath: fullPath, context: context);
          }
          // found a value, continue drill down
          continue;
          // ignore: avoid_catching_errors
        } on RangeError catch (_) {
          // out of range, value not found at index selector
          return Pick.absent(path.length - 1,
              fullPath: fullPath, context: context);
        }
      }
    }
    if (data is Map) {
      if (!data.containsKey(selector)) {
        return Pick.absent(path.length - 1,
            fullPath: fullPath, context: context);
      }
      final picked = data[selector];
      if (picked == null) {
        // no value mapped to selector
        return Pick(null, fullPath: fullPath, context: context);
      }
      data = picked;
      continue;
    }
    if (data is Set && selector is int) {
      throw PickException(
          'Value at location ${path.sublist(0, path.length - 1)} is a Set, which is a unordered data structure. '
          "It's not possible to pick a value by using a index ($selector)");
    }
    // can't drill down any more to find the exact location.
    return Pick.absent(path.length - 1, fullPath: fullPath, context: context);
  }
  return Pick(data, fullPath: fullPath, context: context);
}

/// A picked object holding the [value] and giving access to useful parsing functions
class Pick with PickLocation, PickContext<Pick> {
  Pick(
    this.value, {
    this.fullPath = const [],
    Map<String, dynamic>? context,
  }) : _context = context != null ? Map.of(context) : {};

  Pick.absent(
    int missingValueAtIndex, {
    this.fullPath = const [],
    Map<String, dynamic>? context,
  })  : _missingValueAtIndex = missingValueAtIndex,
        _context = context != null ? Map.of(context) : {};

  /// The picked value, might be `null`
  Object? value;

  /// Allows the distinction between the actual [value] `null` and the value not
  /// being available
  ///
  /// Usually it doesn't matter, but for rare cases it does this method can be
  /// used to check if a [Map] contains `null` for a key or the key being absent
  ///
  /// Not available could mean:
  /// - Accessing a key which doesn't exists in a
  /// - Reading the value from [List] when the index is greater than the length
  /// - Trying to access a key in a [Map] but the found data structure is a [List]
  ///
  /// ```
  /// pick({"a": null}, "a").isAbsent(); // false
  /// pick({"a": null}, "b").isAbsent(); // true
  ///
  /// pick([null], 0).isAbsent(); // false
  /// pick([], 2).isAbsent(); // true
  ///
  /// pick([], "a").isAbsent(); // true
  /// ```
  bool isAbsent() => missingValueAtIndex != null;

  @override
  List<dynamic> fullPath;

  @override
  List get path =>
      fullPath.take(_missingValueAtIndex ?? fullPath.length).toList();

  /// When the picked value is unavailable ([Pick..absent]) the index in
  /// [fullPath] which couldn't be found
  int? get missingValueAtIndex => _missingValueAtIndex;
  int? _missingValueAtIndex;

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

    return _drillDown(value, selectors, parentPath: fullPath, context: context);
  }

  @override
  Map<String, dynamic> get context => _context;
  final Map<String, dynamic> _context;

  /// Converts the picked values to a non-nullable type [RequiredPick].
  ///
  /// Crashes when the the value is `null`.
  RequiredPick required() {
    final value = this.value;
    if (value == null) {
      final more = fromContext(requiredPickErrorHintKey).value as String?;
      final moreSegment = more == null ? '' : ' $more';
      throw PickException('required value at location ${location()} '
          'is ${isAbsent() ? 'absent' : 'null'}.$moreSegment');
    }
    return RequiredPick(value, path: fullPath, context: _context);
  }

  @override
  @Deprecated('Use asStringOrNull() to pick a String value')
  String toString() => 'Pick(value=$value, path=$fullPath)';

  @override
  Pick get _builder => this;
}

class RequiredPick with PickLocation, PickContext<RequiredPick> {
  RequiredPick(this.value,
      {List<dynamic> path = const [], Map<String, dynamic>? context})
      : _context = context != null ? Map.of(context) : {},
        fullPath = path;

  /// The picked value, never `null`
  Object value;

  @override
  List<dynamic> fullPath;

  @override
  List get path => fullPath;

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

    return _drillDown(value, selectors, parentPath: fullPath, context: context);
  }

  @override
  Map<String, dynamic> get context => _context;
  final Map<String, dynamic> _context;

  @override
  @Deprecated('Use asStringOrNull() to pick a String value')
  String toString() => 'RequiredPick(value=$value, path=$fullPath)';

  @override
  RequiredPick get _builder => this;

  /// Converts the picked value to a nullable type [Pick]
  Pick nullable() => Pick(value, fullPath: fullPath, context: context);
}

/// Used internally with [PickContext.withContext] to add additional information
/// to the error message
const requiredPickErrorHintKey = '_required_pick_error_hint';

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
  ///
  /// Add context at the top
  /// ```
  /// pick(json)
  ///   .withContext('apiVersion', response.getApiVersion())
  ///   .let((pick) => Response.fromPick(pick));
  /// ```
  ///
  /// Read it where required
  /// ```
  /// factory Item.fromPick(RequiredPick pick) {
  ///     final Version apiVersion = pick.fromContext('apiVersion').asVersion();
  ///     if (apiVersion >= Version(0, 2, 0)) {
  ///       return Item(
  ///         color: pick("detail", "color").required().asString(),
  ///       );
  ///     } else {
  ///       return Item(
  ///         color: pick("meta-data", "variant", 0, "color").required().asString(),
  ///       );
  ///     }
  ///   }
  /// ```
  T withContext(String key, dynamic value) {
    context[key] = value;
    return _builder;
  }

  // Has been removed in 0.5.0
  @Deprecated('Use withContext')
  T Function(String key, dynamic value) get addContext => withContext;

  /// Pick values from the context using the [Pick] API
  ///
  /// ```
  /// pick.fromContext('apiVersion').asIntOrNull();
  /// ```
  Pick fromContext(
    String key, [
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
    return pick(
      context,
      key,
      arg0,
      arg1,
      arg2,
      arg3,
      arg4,
      arg5,
      arg6,
      arg7,
      arg8,
    );
  }
}

mixin PickLocation {
  /// The full path to [value] inside of the object
  ///
  /// I.e. ['shoes', 0, 'name']
  List<dynamic> get fullPath;

  /// The path segments containing non-null values
  ///
  /// I.e. ['shoes'] for an empty shoes list
  List<dynamic> get path;

  String location() {
    final access = <String>[];
    final path = this.path;
    final fullPath = this.fullPath;
    final isSet = path.length == fullPath.length;
    var foundNullPart = false;
    for (var i = 0; i < fullPath.length; i++) {
      final full = fullPath[i];
      final part = path.length > i ? path[i] : null;
      final nullPart = () {
        if (foundNullPart) return '';
        if (isSet && i + 1 == fullPath.length) {
          foundNullPart = true;
          return ' (null)';
        }
        if (part == null) {
          foundNullPart = true;
          return ' (absent)';
        }
        return '';
      }();

      if (full is int) {
        access.add('$full$nullPart');
      } else {
        access.add('"$full"$nullPart');
      }
    }

    final firstMissing = fullPath.isEmpty
        ? '<root>'
        : fullPath[path.isEmpty ? 0 : path.length - 1];
    final formattedMissing =
        firstMissing is int ? 'list index $firstMissing' : '"$firstMissing"';

    final params = access.isNotEmpty ? ', ${access.join(', ')}' : '';
    final root = access.isEmpty ? '<root>' : 'json';
    return '$formattedMissing in pick($root$params)';
  }
}
