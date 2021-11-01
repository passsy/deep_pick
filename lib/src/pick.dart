import 'dart:convert';

/// Picks a values from a [json] String at location arg0, arg1...
///
/// args may be
/// - a [String] to pick values from a [Map]
/// - or [int] when you want to pick a value at index from a [List]
///
///
/// It's quite common that pick is used when parsing json from a String, such
/// as a http response body. To easy this process [pickFromJson] parses a json
/// String directly.
///
/// ```dart
/// pickFromJson(rawJson, arg0, arg1)
/// ```
///
/// is a shorthand for
///
/// ```dart
/// final json = jsonDecode(rawJson);
/// pick(json, arg0, arg1);
/// ```
///
/// If objects are deeper than 10, use [pickDeep], which requires a manual call
/// to [jsonDecode].
Pick pickFromJson(
  String json, [
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
  final parsed = jsonDecode(json);
  return pick(
    parsed,
    arg0,
    arg1,
    arg2,
    arg3,
    arg4,
    arg5,
    arg6,
    arg7,
    arg8,
    arg9,
  );
}

/// Picks the value of a [json]-like dart data structure consisting of Maps,
/// Lists and objects at location arg0, arg1 ... arg9
///
/// args may be
/// - a [String] to pick values from a [Map]
/// - or [int] when you want to pick a value at index from a [List]
///
/// If objects are deeper than 10, use [pickDeep]
Pick pick(
  /*Map|List|null*/ dynamic json, [
  /*String|int|null*/ Object? arg0,
  /*String|int|null*/ Object? arg1,
  /*String|int|null*/ Object? arg2,
  /*String|int|null*/ Object? arg3,
  /*String|int|null*/ Object? arg4,
  /*String|int|null*/ Object? arg5,
  /*String|int|null*/ Object? arg6,
  /*String|int|null*/ Object? arg7,
  /*String|int|null*/ Object? arg8,
  /*String|int|null*/ Object? arg9,
]) {
  final selectors = [arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9]
      // null is a sign for unused 'varargs'
      .where((dynamic it) => it != null)
      .cast<Object>()
      .toList(growable: false);
  return _drillDown(json, selectors);
}

/// Picks the value of [json] by traversing the object along the values in
/// [selector] one by one
///
/// Valid values for the items in selector are
/// - a [String] to pick values from a [Map]
/// - or [int] when you want to pick a value at index from a [List]
Pick pickDeep(
  /*Map|List|null*/ dynamic json,
  List< /*String|int*/ Object> selector,
) {
  return _drillDown(json, selector);
}

/// Traverses the object along [selectors]
Pick _drillDown(
  /*Map|List|null*/ dynamic json,
  List< /*String|int*/ Object> selectors, {
  List< /*String|int*/ Object> parentPath = const [],
  Map<String, dynamic>? context,
}) {
  final fullPath = [...parentPath, ...selectors];
  final path = <dynamic>[];
  /*Map|List|null*/ dynamic data = json;
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
        "It's not possible to pick a value by using a index ($selector)",
      );
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
    Map<String, dynamic>? context,
  }) : context = context != null ? Map.of(context) : {};

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
        context = context != null ? Map.of(context) : {};

  /// The picked value, might be `null`
  final Object? value;

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

  /// The index of the object when it is an element in a `List`
  ///
  /// Usage:
  ///
  /// ```dart
  /// pick(["John", "Paul", "George", "Ringo"]).asListOrThrow((pick) {
  ///  final index = pick.index!;
  ///  return Artist(id: index, name: pick.asStringOrThrow());
  /// );
  /// ```
  int? get index {
    final lastPathSegment = path.isNotEmpty ? path.last : null;
    if (lastPathSegment == null) {
      return null;
    }
    if (lastPathSegment is int) {
      // within a List
      return lastPathSegment;
    }
    return null;
  }

  /// When the picked value is unavailable ([Pick.isAbsent]) the index in
  /// [path] which couldn't be found
  int? get missingValueAtIndex => _missingValueAtIndex;
  int? _missingValueAtIndex;

  /// The full path to [value] inside of the object
  ///
  /// I.e. `['shoes', 0, 'name']`
  final List<Object> path;

  /// The path segments containing non-null values parsing could follow along
  ///
  /// I.e. `['shoes']` for an empty shoes list
  List<Object> get followablePath =>
      path.take(_missingValueAtIndex ?? path.length).toList();

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

  /// Enter a "required" context which requires the picked value to be non-null
  /// or a [PickException] is thrown.
  ///
  /// Crashes when the the value is `null`.
  RequiredPick required() {
    final value = this.value;
    if (value == null) {
      final more = fromContext(requiredPickErrorHintKey).value as String?;
      final moreSegment = more == null ? '' : ' $more';
      throw PickException(
        'Expected a non-null value but location $debugParsingExit '
        'is ${isAbsent ? 'absent' : 'null'}.$moreSegment',
      );
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
  Pick withContext(String key, Object? value) {
    context[key] = value;
    return this;
  }

  /// Pick values from the context using the [Pick] API
  ///
  /// ```
  /// pick.fromContext('apiVersion').asIntOrNull();
  /// ```
  Pick fromContext(
    String key, [
    Object? arg0,
    Object? arg1,
    Object? arg2,
    Object? arg3,
    Object? arg4,
    Object? arg5,
    Object? arg6,
    Object? arg7,
    Object? arg8,
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
    List<Object> path = const [],
    Map<String, Object?>? context,
  })  : value = value as Object,
        super(value, path: path, context: context);

  @override
  // ignore: overridden_fields
  covariant Object value;

  @override
  @Deprecated('Use asStringOrNull() to pick a String value')
  String toString() => 'RequiredPick(value=$value, path=$path)';

  Pick nullable() => Pick(value, path: path, context: context);

  @override
  RequiredPick withContext(String key, Object? value) {
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
