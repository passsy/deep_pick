import 'dart:collection';
import 'dart:convert';

part 'pick_exception.dart';

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
  // null is a sign for unused 'varargs'
  final selectors = <Object>[
    if (arg0 != null) arg0,
    if (arg1 != null) arg1,
    if (arg2 != null) arg2,
    if (arg3 != null) arg3,
    if (arg4 != null) arg4,
    if (arg5 != null) arg5,
    if (arg6 != null) arg6,
    if (arg7 != null) arg7,
    if (arg8 != null) arg8,
    if (arg9 != null) arg9,
  ];
  return _pickFromRoot(json, selectors);
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
  // the list belongs to the caller, the pick gets its own
  return _pickFromRoot(json, [...selector]);
}

/// Picks from the root [json] along [selectors]
Pick _pickFromRoot(
  /*Map|List|null*/ dynamic json,
  List< /*String|int*/ Object> selectors,
) {
  if (selectors.isEmpty) {
    // nothing to traverse, the root is the picked value
    return Pick(json);
  }
  return _drillDown(json, selectors, parent: null, context: {});
}

/// The pick of the root [json], as the parent of an absent top-level pick
///
/// It is never handed out, nobody can write to its context. It gets by
/// without a map of its own.
Pick _rootOf(/*Map|List|null*/ dynamic json) {
  return Pick._from(null, json, path: const [], context: const {});
}

/// A path that was built by this library and frozen without a copy, because
/// nobody else holds the list behind it
class _FrozenPath extends UnmodifiableListView<Object> {
  _FrozenPath(this._source) : super(_source);

  final List<Object> _source;
}

/// A new list of [path] followed by [selectors]
List<Object> _extended(List<Object> path, List<Object> selectors) {
  // copying from the list behind a frozen path is a lot faster than iterating
  // the view in front of it
  final source = path is _FrozenPath ? path._source : path;
  return [...source, ...selectors];
}

/// [path] as a list nobody can change, neither through the pick nor through
/// the list the caller passed in
List<Object> _snapshotOf(List<Object> path) {
  if (path is _FrozenPath) {
    // already the path of a pick, i.e. when a pick is required()
    return path;
  }
  if (path.isEmpty) {
    return const [];
  }
  // the list belongs to the caller, it is copied and frozen
  return _FrozenPath(List.of(path));
}

/// The pick of the non-null [item] the [list] holds at [index], with its
/// own copy of [context]
///
/// For the list parsers of this package, it is not exported.
RequiredPick pickListItem(
  Pick list,
  int index,
  Object item, {
  required Map<String, dynamic> context,
}) {
  return RequiredPick._from(item,
      path: _extended(list._path, [index]), context: Map.of(context));
}

/// The pick of a `null` the [list] holds at [index], with its own copy of
/// [context]
///
/// For the list parsers of this package, it is not exported.
Pick pickNullListItem(
  Pick list,
  int index, {
  required Map<String, dynamic> context,
}) {
  return Pick._from(null, null,
      path: _extended(list._path, [index]), context: Map.of(context));
}

/// Traverses [start] along [selectors]
///
/// [parent] is the pick [start] is the value of. A top-level pick has none,
/// only an absent pick keeps its parent and the root is created for it then.
///
/// The returned pick keeps [context] as its own, it is not copied. The same
/// goes for [selectors], which become the path of a pick from the root. The
/// caller hands over a map and a list nobody else holds.
///
/// This runs for every pick. A value that is found costs one lookup per
/// selector, everything about a path that breaks is worked out only then.
Pick _drillDown(
  /*Map|List|null*/ dynamic start,
  List< /*String|int*/ Object> selectors, {
  required Pick? parent,
  required Map<String, dynamic> context,
}) {
  final parentPath = parent == null ? const <Object>[] : parent._path;
  final fullPath =
      parentPath.isEmpty ? selectors : _extended(parentPath, selectors);
  final lastIndex = selectors.length - 1;
  /*Map|List|null*/ dynamic data = start;
  for (var i = 0; i < selectors.length; i++) {
    final selector = selectors[i];
    final dynamic child;
    if (data is Map) {
      child = data[selector];
      if (child == null && !data.containsKey(selector)) {
        return Pick._from(parent ?? _rootOf(start), null,
            path: fullPath,
            context: context,
            missingIndex: parentPath.length + i);
      }
    } else if (data is List &&
        selector is int &&
        selector >= 0 &&
        selector < data.length) {
      child = data[selector];
    } else {
      // can't drill down any more to find the exact location.
      final unreachable = Pick._from(parent ?? _rootOf(start), null,
          path: fullPath,
          context: context,
          missingIndex: parentPath.length + i);
      if (data is Set && selector is int) {
        throw PickException(
          _renderErrorMessage(
            unreachable,
            headline: 'cannot pick by index at '
                '${_describeLocation(fullPath)}, it is a Set',
          ),
        );
      }
      return unreachable;
    }
    // a `null` at the last segment is the result, anywhere else a dead end
    if (child == null && i != lastIndex) {
      // null can't be drilled into, the next segment is unreachable
      return Pick._from(parent ?? _rootOf(start), null,
          path: fullPath,
          context: context,
          missingIndex: parentPath.length + i + 1);
    }
    data = child;
  }
  return Pick._from(parent, data, path: fullPath, context: context);
}

/// A picked object holding the [value] (may be null) and giving access to useful parsing functions
class Pick {
  /// Pick constructor when being able to drill down [path] all the way to reach
  /// the value.
  /// [value] may still be `null` but the structure was correct, therefore
  /// [isAbsent] will always return `false`.
  Pick(
    this.value, {
    List<Object> path = const [],
    Map<String, dynamic>? context,
  })  : _path = _snapshotOf(path),
        _missingIndex = null,
        _parent = null,
        context = context != null ? Map.of(context) : {};

  /// Pick of an absent value. While drilling down [path] the structure of the
  /// data did not match the [path] and the value wasn't found.
  ///
  /// [value] will always return `null` and [isAbsent] always `true`.
  ///
  /// The pick holds no data, its error messages only show where the path
  /// broke. Pick from a value to get one whose errors show the data:
  /// ```dart
  /// Pick({'id': 1}, path: ['shoes'])('name'); // absent, {'id': 1} has no name
  /// ```
  Pick.absent(
    int missingValueAtIndex, {
    List<Object> path = const [],
    Map<String, Object?>? context,
  })  : _path = _snapshotOf(path),
        _missingIndex = missingValueAtIndex,
        value = null,
        _parent = null,
        context = context != null ? Map.of(context) : {};

  /// A pick that was picked from [parent], absent when it comes with a
  /// [missingIndex]. Only absent picks retain [parent] for diagnostics.
  ///
  /// Keeps [context] and [path] as its own without copying them, the caller
  /// hands over a map and a list nobody else holds.
  Pick._from(
    Pick? parent,
    this.value, {
    required List<Object> path,
    required this.context,
    int? missingIndex,
  })  : _path = _FrozenPath(path),
        _missingIndex = missingIndex,
        _parent = missingIndex == null ? null : parent;

  /// A copy at a different [path] or with a different [context]
  ///
  /// What was picked stays, be it the [value] or the location it is absent
  /// at.
  Pick _copyWith({List<Object>? path, Map<String, dynamic>? context}) {
    // a copy at the same path shares the list behind this frozen path, a
    // second view is not stacked on top of it
    final ownPath = _path;
    final sharedPath = ownPath is _FrozenPath ? ownPath._source : ownPath;
    return Pick._from(
      _parent,
      value,
      path: path ?? sharedPath,
      // the copy gets a context of its own
      context: context ?? Map.of(this.context),
      missingIndex: _missingIndex,
    );
  }

  /// The picked value, might be `null`
  final Object? value;

  /// The source of an absent pick, `null` for a successful pick or a pick
  /// built with a public constructor
  ///
  /// The error message of an absent pick looks up in it what the data held
  /// where the path broke.
  final Pick? _parent;

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
  /// - Drilling further down after hitting `null`, because `null` has no
  ///   children
  ///
  /// ```dart
  /// pick({"a": null}, "a").isAbsent; // false
  /// pick({"a": null}, "b").isAbsent; // true
  /// pick({"a": null}, "a", "b").isAbsent; // true, "b" is unreachable
  ///
  /// pick([null], 0).isAbsent; // false
  /// pick([], 2).isAbsent; // true
  ///
  /// pick([], "a").isAbsent; // true
  /// ```
  bool get isAbsent => _missingIndex != null;

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
    final lastPathSegment = _path.isNotEmpty ? _path.last : null;
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
  @Deprecated(
    "Throw PickException.fromPick(this, 'expected a Foo') instead of "
    'building an error message from missingValueAtIndex. '
    'It adds the location and the found value to the message',
  )
  int? get missingValueAtIndex => _missingIndex;
  final int? _missingIndex;

  /// The full path to [value] inside of the object
  ///
  /// I.e. `['shoes', 0, 'name']`
  ///
  /// An unmodifiable snapshot of the selectors supplied when this pick was
  /// created. Later changes to the caller's list do not change the location.
  @Deprecated(
    "Throw PickException.fromPick(this, 'expected a Foo') instead of "
    'building an error message from path. '
    'It adds the location and the found value to the message',
  )
  List<Object> get path => _path;
  final List<Object> _path;

  /// The path segments containing non-null values parsing could follow along
  ///
  /// I.e. `['shoes']` for an empty shoes list
  @Deprecated(
    "Throw PickException.fromPick(this, 'expected a Foo') instead of "
    'building an error message from followablePath. '
    'It adds the location and the found value to the message',
  )
  List<Object> get followablePath =>
      _path.take(_missingIndex ?? _path.length).toList();

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
    // null is a sign for unused 'varargs'
    final selectors = <Object>[
      if (arg0 != null) arg0,
      if (arg1 != null) arg1,
      if (arg2 != null) arg2,
      if (arg3 != null) arg3,
      if (arg4 != null) arg4,
      if (arg5 != null) arg5,
      if (arg6 != null) arg6,
      if (arg7 != null) arg7,
      if (arg8 != null) arg8,
      if (arg9 != null) arg9,
    ];

    if (isAbsent) {
      // nothing to drill into, a longer path is absent at the same location
      return _copyWith(path: _extended(_path, selectors));
    }
    return _drillDown(value, selectors, parent: this, context: Map.of(context));
  }

  /// Returns a copy that redacts data values in its error messages and those
  /// of subsequently picked descendants.
  ///
  /// The original pick and existing descendants keep their diagnostic settings.
  /// The copy shares the parsed data but has an independent context map.
  ///
  /// [PickException] messages show the value at the location parsing failed,
  /// which is useful during development but may leak personal data into
  /// crash reporters and logs. With redaction enabled the messages keep
  /// [Map] keys and types, but mask all values.
  ///
  /// Keys count as schema and stay visible. That includes the keys of a
  /// [Map] that is keyed by data, like `{"jane@example.com": {...}}`.
  ///
  /// Redaction is about the picked data. Values stored with [withContext]
  /// are not part of it and show up unredacted in errors of [fromContext].
  ///
  /// Add it once at the root to cover the whole parsing tree:
  /// ```dart
  /// pick(response).redactValues().letOrThrow((pick) => User.fromPick(pick));
  /// ```
  ///
  /// Use [enabled] to decide at runtime, i.e. to keep the values in debug
  /// builds:
  /// ```dart
  /// pick(response).redactValues(enabled: kReleaseMode);
  /// ```
  ///
  /// `enabled: false` returns a copy that shows values again, also when a
  /// pick above it redacted them. [redactsValues] tells which one applies.
  Pick redactValues({bool enabled = true}) {
    return _copyWith(context: {...context, _redactValuesContextKey: enabled});
  }

  /// Whether [redactValues] is enabled for this pick, by a call on it or on
  /// a pick above it
  ///
  /// A custom parser that writes its own error message should leave the
  /// picked [value] out of it when this is `true`.
  bool get redactsValues => context[_redactValuesContextKey] == true;

  /// Enter a "required" context which requires the picked value to be non-null
  /// or a [PickException] is thrown.
  ///
  /// Crashes when the the value is `null`.
  RequiredPick required() {
    final value = this.value;
    if (value == null) {
      throw PickException.fromPick(this, 'expected a non-null value');
    }
    return RequiredPick(value, path: _path, context: context);
  }

  @override
  @Deprecated('Use asStringOrNull() to pick a String value')
  String toString() => 'Pick(value=$value, path=$_path)';

  /// Attaches additional information which can be used during parsing.
  /// i.e the HTTP request/response including headers
  ///
  /// Use this method to chain methods. It's pure syntax sugar.
  /// The alternative cascade operator often requires additional parenthesis
  ///
  /// Add context at the top
  /// ```dart
  /// pick(json)
  ///   .withContext('apiVersion', response.getApiVersion())
  ///   .let((pick) => Response.fromPick(pick));
  /// ```
  ///
  /// Read it where required
  /// ```dart
  /// factory Item.fromPick(RequiredPick pick) {
  ///     final Version apiVersion = pick.fromContext('apiVersion').asVersion();
  ///     if (apiVersion >= Version(0, 2, 0)) {
  ///       return Item(
  ///         color: pick("detail", "color").required().asStringOrThrow(),
  ///       );
  ///     } else {
  ///       return Item(
  ///         color: pick("meta-data", "variant", 0, "color").required().asStringOrThrow(),
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
  /// ```dart
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
  /// picked value "Instance of \'Object\'" using `pick(<root>)`
  /// "unknownKey" in pick(json, "unknownKey" (absent))
  ///
  /// With [redactValues] the value is replaced by its type.
  @Deprecated(
    "Throw PickException.fromPick(this, 'expected a Foo') instead of "
    'building an error message from debugParsingExit. '
    'It adds the location and the found value to the message',
  )
  String get debugParsingExit {
    final access = <String>[];
    final shownValue = () {
      if (redactsValues) {
        return _renderValueRedacted(value);
      }
      return '$value';
    }();

    // The full path to [value] inside of the object
    // I.e. ['shoes', 0, 'name']
    final fullPath = _path;

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
            return '($shownValue)';
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
      valueOrExit = 'picked value "$shownValue" using';
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

  /// A pick of a non-null [value] at a [path] this library built, keeps
  /// [context] and [path] as its own without copying them
  RequiredPick._from(
    this.value, {
    required List<Object> path,
    required Map<String, dynamic> context,
  }) : super._from(null, value, path: path, context: context);

  @override
  // ignore: overridden_fields
  covariant Object value;

  @override
  @Deprecated('Use asStringOrNull() to pick a String value')
  String toString() => 'RequiredPick(value=$value, path=$_path)';

  Pick nullable() => Pick(value, path: _path, context: context);

  @override
  RequiredPick withContext(String key, Object? value) {
    super.withContext(key, value);
    return this;
  }

  @override
  RequiredPick redactValues({bool enabled = true}) {
    return RequiredPick(
      value,
      path: _path,
      context: {...context, _redactValuesContextKey: enabled},
    );
  }
}

/// Used internally with [Pick.redactValues] to mark a pick chain as carrying
/// sensitive data
const _redactValuesContextKey = '_redact_values';
