/// Picks the value of [json] at location arg0, arg1 ... arg9
///
/// args may be
/// - a [String] to pick values from a [Map]
/// - or [int] when you want to pick a value at index from a [List]
Pick pick(
  /*Map?|List?*/ dynamic json, [
  Object? arg0,
  Object? arg1,
  Object? arg2,
  Object? arg3,
  Object? arg4,
  Object? arg5,
  Object? arg6,
  Object? arg7,
  Object? arg8,
  Object? arg9,
]) {
  final selectors = [arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9]
      // null is a sign for unused 'varargs'
      .where((dynamic it) => it != null)
      .cast<Object>()
      .toList(growable: false);
  return _drillDown(json, selectors);
}

Pick _drillDown(dynamic json, List<Object> selectors,
    {List<Object> parentPath = const [], Map<String, dynamic>? context}) {
  final fullPath = [...parentPath, ...selectors];
  final path = <dynamic>[];
  dynamic data = json;
  for (final selector in selectors) {
    path.add(selector);
    if (data is List) {
      if (selector is int) {
        try {
          data = data[selector];
          if (data == null) {
            return Pick(null, path: fullPath, context: context);
          }
          // found a value, continue drill down
          continue;
          // ignore: avoid_catching_errors
        } on RangeError catch (_) {
          // out of range, value not found at index selector
          return Pick.absent(path.length - 1, path: fullPath, context: context);
        }
      }
    }
    if (data is Map) {
      if (!data.containsKey(selector)) {
        return Pick.absent(path.length - 1, path: fullPath, context: context);
      }
      final dynamic picked = data[selector];
      if (picked == null) {
        // no value mapped to selector
        return Pick(null, path: fullPath, context: context);
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
    return Pick.absent(path.length - 1, path: fullPath, context: context);
  }
  return Pick(data, path: fullPath, context: context);
}

/// A picked object holding the [value] (may be null) and giving access to useful parsing functions
class Pick with PickLocation, PickContext<Pick> {
  /// Pick constructor when being able to drill down [path] all the way to reach
  /// the value.
  /// [value] may still be `null` but the structure was correct, therefore
  /// [isAbsent] will always return `false`.
  Pick(
    this.value, {
    this.path = const [],
    Map<String, dynamic>? context,
  }) : _context = context != null ? Map.of(context) : {};

  /// Pick of an absent value. While drilling down [path] the structure of the
  /// data did not match the [path] and the value wasn't found.
  ///
  /// [value] will always return `null` and [isAbsent] always `true`.
  Pick.absent(
    int missingValueAtIndex, {
    this.path = const [],
    Map<String, Object?>? context,
  })  : value = null,
        _missingValueAtIndex = missingValueAtIndex,
        _context = context != null ? Map.of(context) : {};

  /// The picked value, might be `null`
  final Object? value;

  /// Allows the distinction between the actual [value] `null` and the value not
  /// being available
  ///
  /// Usually, it doesn't matter, but for rare cases, it does this method can be
  /// used to check if a [Map] contains `null` for a key or the key being absent
  ///
  /// Not available could mean:
  /// - Accessing a key which doesn't exist in a
  /// - Reading the value from [List] when the index is greater than the length
  /// - Trying to access a key in a [Map] but the found data structure is a [List]
  ///
  /// ```
  /// pick({"a": null}, "a").isAbsent; // false
  /// pick({"a": null}, "b").isAbsent; // true
  ///
  /// pick([null], 0).isAbsent; // false
  /// pick([], 2).isAbsent; // true
  ///
  /// pick([], "a").isAbsent; // true
  /// ```
  bool get isAbsent => missingValueAtIndex != null;

  @override
  List<Object> path;

  @override
  List<Object> get followablePath =>
      path.take(_missingValueAtIndex ?? path.length).toList();

  /// When the picked value is unavailable ([Pick..absent]) the index in
  /// [path] which couldn't be found
  int? get missingValueAtIndex => _missingValueAtIndex;
  int? _missingValueAtIndex;

  // Pick even further
  Pick call([
    Object? arg0,
    Object? arg1,
    Object? arg2,
    Object? arg3,
    Object? arg4,
    Object? arg5,
    Object? arg6,
    Object? arg7,
    Object? arg8,
    Object? arg9,
  ]) {
    final selectors =
        [arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9]
            // null is a sign for unused 'varargs'
            .where((Object? it) => it != null)
            .cast<Object>()
            .toList(growable: false);

    return _drillDown(value, selectors, parentPath: path, context: context);
  }

  @override
  Map<String, Object?> get context => _context;
  final Map<String, Object?> _context;

  /// Enter a "required" context which requires the picked value to be non-null
  /// and parsable or a [PickException] is thrown.
  ///
  /// Crashes when the the value is `null` or can't be parsed correctly with the asXyz() methods.
  RequiredPick required() {
    final value = this.value;
    if (value == null) {
      final more = fromContext(requiredPickErrorHintKey).value as String?;
      final moreSegment = more == null ? '' : ' $more';
      throw PickException('required value at location ${location()} '
          'is ${isAbsent ? 'absent' : 'null'}.$moreSegment');
    }
    return RequiredPick(value, path: path, context: _context);
  }

  @override
  @Deprecated('Use asStringOrNull() to pick a String value')
  String toString() => 'Pick(value=$value, path=$path)';

  @override
  Pick get _builder => this;
}

/// A picked object holding the [value] (never null) and giving access to useful parsing functions
class RequiredPick with PickLocation, PickContext<RequiredPick> {
  RequiredPick(
    // using dynamic here to match the return type of jsonDecode
    dynamic value, {
    this.path = const [],
    Map<String, Object?>? context,
  })  : value = value as Object,
        _context = context != null ? Map.of(context) : {};

  /// The picked value, never `null`
  final Object value;

  @override
  List<Object> path;

  @override
  List<Object> get followablePath => path;

  // Pick even further
  Pick call([
    Object? arg0,
    Object? arg1,
    Object? arg2,
    Object? arg3,
    Object? arg4,
    Object? arg5,
    Object? arg6,
    Object? arg7,
    Object? arg8,
    Object? arg9,
  ]) {
    final selectors =
        [arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9]
            // null is a sign for unused 'varargs'
            .where((Object? it) => it != null)
            .cast<Object>()
            .toList(growable: false);

    return _drillDown(value, selectors, parentPath: path, context: context);
  }

  @override
  Map<String, Object?> get context => _context;
  final Map<String, Object?> _context;

  @override
  @Deprecated('Use asStringOrNull() to pick a String value')
  String toString() => 'RequiredPick(value=$value, path=$path)';

  @override
  RequiredPick get _builder => this;

  /// Converts the picked value to a nullable type [Pick]
  ///
  /// Inverse of [Pick.required]
  Pick nullable() => Pick(value, path: path, context: context);
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
  List<Object> get path;

  /// The path segments containing non-null values parsing could follow along
  ///
  /// I.e. ['shoes'] for an empty shoes list
  List<Object> get followablePath;

  String location() {
    final access = <String>[];
    final fullPath = path;
    final followable = followablePath;
    final isSet = followable.length == fullPath.length;
    var foundNullPart = false;
    for (var i = 0; i < fullPath.length; i++) {
      final full = fullPath[i];
      final part = followable.length > i ? followable[i] : null;
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
        : fullPath[followable.isEmpty ? 0 : followable.length - 1];
    final formattedMissing =
        firstMissing is int ? 'list index $firstMissing' : '"$firstMissing"';

    final params = access.isNotEmpty ? ', ${access.join(', ')}' : '';
    final root = access.isEmpty ? '<root>' : 'json';
    return '$formattedMissing in pick($root$params)';
  }
}
