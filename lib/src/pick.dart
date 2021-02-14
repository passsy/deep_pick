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
  final selectors = [arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9]
      // null is a sign for unused 'varargs'
      .where((it) => it != null)
      .toList(growable: false);
  return _drillDown(json, selectors);
}

Pick _drillDown(dynamic json, List<dynamic> selectors,
    {List<dynamic> parentPath = const [], Map<String, dynamic>/*?*/ context}) {
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
      if (!(data as Map).containsKey(selector)) {
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
class Pick {
  /// Pick constructor when being able to drill down [path] all the way to reach
  /// the value.
  /// [value] may still be `null` but the structure was correct, therefore
  /// [isAbsent] will always return `false`.
  Pick(
    this.value, {
    this.path = const [],
    Map<String, dynamic>/*?*/ context,
  }) : context = context != null ? Map.of(context) : {};

  /// Pick of an absent value. While drilling down [path] the structure of the
  /// data did not match the [path] and the value wasn't found.
  ///
  /// [value] will always return `null` and [isAbsent] always `true`.
  Pick.absent(
    int missingValueAtIndex, {
    this.path = const [],
    Map<String, dynamic>/*?*/ context,
  })  : value = null,
        _missingValueAtIndex = missingValueAtIndex,
        context = context != null ? Map.of(context) : {};

  /// The picked value, might be `null`
  final Object/*?*/ value;

  /// Allows the distinction between the actual [value] `null` and the value not
  /// being available
  ///
  /// Usually, it doesn't matter, but for rare cases, it does this method can be
  /// used to check if a [Map] contains `null` for a key or the key being absent
  ///
  /// Not available could mean:
  /// - Accessing a key which doesn't exist in a [Map]
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

  /// Attaches additional information which can be used during parsing.
  /// i.e the HTTP request/response including headers
  final Map<String, dynamic> context;

  /// When the picked value is unavailable ([Pick..absent]) the index in
  /// [path] which couldn't be found
  int/*?*/ get missingValueAtIndex => _missingValueAtIndex;
  int/*?*/ _missingValueAtIndex;

  /// The full path to [value] inside of the object
  ///
  /// I.e. ['shoes', 0, 'name']
  final List<dynamic> path;

  /// The path segments containing non-null values parsing could follow along
  ///
  /// I.e. ['shoes'] for an empty shoes list
  List<dynamic> get followablePath =>
      path.take(_missingValueAtIndex ?? path.length).toList();

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
        [arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9]
            // null is a sign for unused 'varargs'
            .where((it) => it != null)
            .toList(growable: false);

    return _drillDown(value, selectors, parentPath: path, context: context);
  }

  /// Enter a "required" context which requires the picked value to be non-null
  /// or a [PickException] is thrown.
  ///
  /// Crashes when the the value is `null`.
  RequiredPick required() {
    final value = this.value;
    if (value == null) {
      final more = fromContext(requiredPickErrorHintKey).value as String/*?*/;
      final moreSegment = more == null ? '' : ' $more';
      throw PickException(
          'Expected a non-null value but location $debugParsingExit '
          'is ${isAbsent ? 'absent' : 'null'}.$moreSegment');
    }
    return RequiredPick(value, path: path, context: context);
  }

  @override
  @Deprecated('Use asStringOrNull() to pick a String value')
  String toString() => 'Pick(value=$value, path=$path)';

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
  Pick withContext(String key, dynamic value) {
    context[key] = value;
    return this;
  }

  // Has been removed in 0.5.0
  @Deprecated('Use withContext')
  Pick Function(String key, dynamic value) get addContext => withContext;

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
        context, key, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8);
  }

  /// Returns a human readable String of the requested [path] and the actual
  /// parsed value following the path along ([followablePath]).
  ///
  /// Examples:
  /// picked value "b" using pick(json, "a"(b))
  /// picked value "null" using pick(json, "a" (null))
  /// picked value "Instance of \'Object\'" using pick(<root>)
  /// "unknownKey" in pick(json, "unknownKey" (absent))
  String get debugParsingExit {
    final access = <String>[];

    // The full path to [value] inside of the object
    // I.e. ['shoes', 0, 'name']
    final fullPath = path;

    // The path segments containing non-null values parsing could follow along
    // I.e. ['shoes'] for an empty shoes list
    final followable = followablePath;

    final foundValue = followable.length == fullPath.length;
    var foundNullPart = false;
    for (var i = 0; i < fullPath.length; i++) {
      final full = fullPath[i];
      final part = followable.length > i ? followable[i] : null;
      final nullPart = () {
        if (foundNullPart) return '';
        if (foundValue && i + 1 == fullPath.length) {
          if (value == null) {
            foundNullPart = true;
            return ' (null)';
          } else {
            return '($value)';
          }
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

    var valueOrExit = '';
    if (foundValue) {
      valueOrExit = 'picked value "$value" using';
    } else {
      final firstMissing = fullPath.isEmpty
          ? '<root>'
          : fullPath[followable.isEmpty ? 0 : followable.length];
      final formattedMissing =
          firstMissing is int ? 'list index $firstMissing' : '"$firstMissing"';
      valueOrExit = '$formattedMissing in';
    }

    final params = access.isNotEmpty ? ', ${access.join(', ')}' : '';
    final root = access.isEmpty ? '<root>' : 'json';
    return '$valueOrExit pick($root$params)';
  }
}

/// A picked object holding the [value] (never null) and giving access to useful parsing functions
class RequiredPick extends Pick {
  RequiredPick(
    // using dynamic here to match the return type of jsonDecode
    dynamic value, {
    List<dynamic> path = const [],
    Map<String, dynamic> context,
  })  : value = value as Object,
        super(value, path: path, context: context);

  @override
  // ignore: overridden_fields
  covariant Object value;

  @override
  @Deprecated('Use asStringOrNull() to pick a String value')
  String toString() => 'RequiredPick(value=$value, path=$path)';

  Pick nullable() => Pick(value, path: path, context: context);

  // Has been removed in 0.5.0
  @Deprecated('Use withContext')
  @override
  RequiredPick Function(String key, dynamic value) get addContext =>
      withContext;

  @override
  RequiredPick withContext(String key, Object/*?*/ value) {
    super.withContext(key, value);
    return this;
  }
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
