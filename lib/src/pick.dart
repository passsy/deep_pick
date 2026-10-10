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
  return _pickFromRoot(json, selector);
}

/// Picks from the root [json] along [selectors]
Pick _pickFromRoot(
  /*Map|List|null*/ dynamic json,
  List< /*String|int*/ Object> selectors,
) {
  final root = Pick(json);
  if (selectors.isEmpty) {
    // nothing to traverse, the root is the picked value
    return root;
  }
  return _drillDown(root, selectors);
}

/// Whether [data] holds something at [selector], which may be `null`
bool _hasChild(/*Map|List|null*/ dynamic data, Object selector) {
  if (data is List) {
    return selector is int && selector >= 0 && selector < data.length;
  }
  if (data is Map) {
    return data.containsKey(selector);
  }
  return false;
}

/// The value [data] holds at [selector], ask [_hasChild] first
dynamic _childOf(/*Map|List*/ dynamic data, Object selector) {
  if (data is List) {
    return data[selector as int];
  }
  return (data as Map)[selector];
}

/// Traverses the value of [parent] along [selectors]
Pick _drillDown(
  Pick parent,
  List< /*String|int*/ Object> selectors, {
  Map<String, dynamic>? context,
}) {
  final fullPath = [...parent.path, ...selectors];
  /*Map|List|null*/ dynamic data = parent.value;
  for (var i = 0; i < selectors.length; i++) {
    final selector = selectors[i];
    // index of [selector] inside [fullPath], not inside [selectors]
    final selectorIndex = parent.path.length + i;
    if (data is Set && selector is int) {
      final unpickable = Pick._from(parent, null,
          path: fullPath, context: context, missingValueAtIndex: selectorIndex);
      throw PickException(
        _renderErrorMessage(
          unpickable,
          headline: 'cannot pick by index at ${_describeLocation(fullPath)}, '
              'it is a Set',
        ),
      );
    }
    if (!_hasChild(data, selector)) {
      // can't drill down any more to find the exact location.
      return Pick._from(parent, null,
          path: fullPath, context: context, missingValueAtIndex: selectorIndex);
    }
    final dynamic child = _childOf(data, selector);
    // a `null` at the last segment is the result, anywhere else a dead end
    final isLastSelector = i == selectors.length - 1;
    if (child == null && !isLastSelector) {
      // null can't be drilled into, the next segment is unreachable
      return Pick._from(parent, null,
          path: fullPath,
          context: context,
          missingValueAtIndex: selectorIndex + 1);
    }
    data = child;
  }
  return Pick._from(parent, data, path: fullPath, context: context);
}

/// What the data holds right before the segment [absent] is missing
///
/// Looked up from the pick [absent] was picked from, by following the path
/// once more. `null` for a pick without a parent.
Object? _valueBeforeMissingSegment(Pick absent) {
  final parent = absent._parent;
  if (parent == null) {
    return null;
  }
  final followed =
      absent.path.sublist(parent.path.length, absent.missingValueAtIndex);
  /*Map|List|null*/ dynamic data = parent.value;
  for (final selector in followed) {
    if (!_hasChild(data, selector)) {
      // the data changed since it was picked from
      return data;
    }
    data = _childOf(data, selector);
  }
  return data;
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
  })  : _missingValueAtIndex = null,
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
    this.path = const [],
    Map<String, Object?>? context,
  })  : value = null,
        _missingValueAtIndex = missingValueAtIndex,
        _parent = null,
        context = context != null ? Map.of(context) : {};

  /// A pick that was picked from [parent], absent when it comes with a
  /// [missingValueAtIndex]
  Pick._from(
    Pick? parent,
    this.value, {
    required this.path,
    required Map<String, dynamic>? context,
    int? missingValueAtIndex,
  })  : _parent = parent,
        _missingValueAtIndex = missingValueAtIndex,
        context = context != null ? Map.of(context) : {};

  /// The picked value, might be `null`
  final Object? value;

  /// The pick this one was picked from, `null` for a pick built with a
  /// constructor
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
  final int? _missingValueAtIndex;

  /// The full path to [value] inside of the object
  ///
  /// I.e. `['shoes', 0, 'name']`
  final List<Object> path;

  /// The path segments containing non-null values parsing could follow along
  ///
  /// I.e. `['shoes']` for an empty shoes list
  List<Object> get followablePath =>
      path.take(missingValueAtIndex ?? path.length).toList();

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

    final missingIndex = missingValueAtIndex;
    if (missingIndex != null) {
      // nothing to drill into, a longer path is absent at the same location
      return Pick._from(
        _parent,
        null,
        path: [...path, ...selectors],
        context: context,
        missingValueAtIndex: missingIndex,
      );
    }
    var childContext = context;
    if (selectors.isNotEmpty) {
      // the hint is advice for this pick, a pick further down the path has
      // its own location and parser
      childContext = Map.of(context)..remove(requiredPickErrorHintKey);
    }
    return _drillDown(this, selectors, context: childContext);
  }

  /// Enter a "required" context which requires the picked value to be non-null
  /// or a [PickException] is thrown.
  ///
  /// Crashes when the the value is `null`.
  RequiredPick required() {
    final value = this.value;
    if (value == null) {
      throw PickException.fromPick(this, 'expected a non-null value');
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
  @Deprecated(
    'Throw PickException.fromPick() instead of building an error message '
    'from debugParsingExit',
  )
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

/// Used internally with [Pick.withContext] to add additional information
/// to the error message
const requiredPickErrorHintKey = '_required_pick_error_hint';

class PickException implements Exception {
  /// A [PickException] with a freeform [message]
  PickException(this.message);

  /// Builds the standard deep_pick error message from the state of [pick]
  ///
  /// Use it in custom `.let()` parsers to throw errors consistent with the
  /// built-in `as*OrThrow` methods.
  ///
  /// ```dart
  /// throw PickException.fromPick(
  ///   pick,
  ///   'could not parse a Timestamp',
  ///   detail: 'seconds since epoch must not be negative',
  ///   hint: 'use asTimestampOrNull() to ignore invalid values',
  /// );
  ///
  /// // PickException: could not parse a Timestamp at createdAt
  /// //
  /// //   query   createdAt
  /// //   found   -1  (an int)
  /// //   detail  seconds since epoch must not be negative
  /// //   hint    use asTimestampOrNull() to ignore invalid values
  /// ```
  ///
  /// - [problem] says what is wrong, i.e. `'expected an int'` or
  ///   `'could not parse a Timestamp'`. The location follows it, and for a
  ///   value that is absent or `null` also that fact, which is read from
  ///   [pick].
  /// - [detail] explains why this value was rejected and gets its own row.
  /// - [hint] tells the reader what to do about it and gets its own row.
  ///
  /// [problem], [detail] and [hint] are printed as they are.
  ///
  /// The message is rendered eagerly so the exception does not retain a
  /// reference into the parsed data structure.
  factory PickException.fromPick(
    Pick pick,
    String problem, {
    String? detail,
    String? hint,
  }) {
    final contextHint = pick.context[requiredPickErrorHintKey] as String?;
    final valueIsMissing = pick.value == null;
    final headline = () {
      final located = '$problem at ${_describeLocation(pick.path)}';
      if (pick.isAbsent) {
        return '$located, but it is absent';
      }
      if (valueIsMissing) {
        return '$located, but it is null';
      }
      return located;
    }();
    final message = _renderErrorMessage(
      pick,
      headline: headline,
      detail: detail,
      hints: [
        if (hint != null) hint,
        // the context hint advises an `OrNull` parser, which only helps when
        // the value is missing
        if (contextHint != null && valueIsMissing) contextHint,
      ],
    );
    return PickException(message);
  }

  /// The complete, human readable error message
  final String message;

  @override
  String toString() {
    return 'PickException: $message';
  }
}

const _errorLabelWidth = 8;

String _errorRow(String label, String content) =>
    '  ${label.padRight(_errorLabelWidth)}$content';

/// Where [path] points to, as it is written in an error message
String _describeLocation(List<Object> path) {
  if (path.isEmpty) {
    return '<root>';
  }
  return _RenderedPath.of(path).text;
}

/// The [headline] followed by rows that show where [pick] points to and what
/// the data holds there
String _renderErrorMessage(
  Pick pick, {
  required String headline,
  String? detail,
  List<String> hints = const [],
}) {
  final fullPath = pick.path;
  final rendered = _RenderedPath.of(fullPath);
  final pathBroke = pick.isAbsent;
  final nodeValue = pathBroke ? _valueBeforeMissingSegment(pick) : pick.value;
  final nodeKnown = pick._parent != null;
  final failedAtIndex = () {
    final index = pick.missingValueAtIndex;
    if (index == null || index >= fullPath.length) {
      // an index outside of the path can't be pointed at
      return null;
    }
    return index;
  }();

  final lines = <String>[];

  if (fullPath.isNotEmpty) {
    lines.add(_errorRow('query', rendered.text));
    if (failedAtIndex != null) {
      final markerText = () {
        if (!nodeKnown) {
          return 'not found';
        }
        return _describeAbsentReason(nodeValue, fullPath[failedAtIndex]);
      }();
      final pad = ' ' * (2 + _errorLabelWidth + rendered.starts[failedAtIndex]);
      final marker = '~' * rendered.lengths[failedAtIndex];
      lines.add('$pad$marker $markerText');
    }
  }

  const valueIndent = 2 + _errorLabelWidth;
  final valueBlock = _renderValueBlock(nodeValue, indent: valueIndent);

  // Did the path break somewhere, or was the whole path followable and only
  // the value at the end is the problem?
  if (pathBroke) {
    // the deepest node parsing could reach, and what was actually in it.
    // Nothing is claimed about a pick that has no parent to look it up in.
    if (failedAtIndex != null && nodeKnown) {
      final reached = _RenderedPath.of(fullPath.take(failedAtIndex).toList());
      final reachedText = reached.text.isEmpty ? '<root>' : reached.text;
      lines.add(_errorRow('at', '$reachedText = ${valueBlock.first}'));
      lines.addAll(valueBlock.skip(1));
    }
  } else {
    // the whole path was followable, the value itself is the problem
    final suffix = () {
      if (nodeValue == null) {
        return '';
      }
      return '  (${_describeType(nodeValue)})';
    }();
    lines.add(_errorRow('found', '${valueBlock.first}$suffix'));
    lines.addAll(valueBlock.skip(1));
  }

  if (detail != null) {
    lines.add(_errorRow('detail', detail));
  }

  for (final hint in hints) {
    lines.add(_errorRow('hint', hint));
  }

  if (lines.isEmpty) {
    return headline;
  }
  return [headline, '', ...lines].join('\n');
}

/// Why drilling down stopped at [node] when applying [selector]
String _describeAbsentReason(Object? node, Object selector) {
  if (node is Set && selector is int) {
    return 'a Set is unordered';
  }
  if (node is Map) {
    return 'no such key';
  }
  if (node is List && selector is int) {
    final count = node.length == 1 ? '1 item' : '${node.length} items';
    return 'index out of range, the List has $count';
  }
  final noun =
      selector is int ? 'index $selector' : 'key ${_quote('$selector')}';
  if (node == null) {
    return 'null has no $noun';
  }
  return '${_describeType(node)} has no $noun';
}

/// A user-facing type name, never leaking internal names like
/// `_Map<String, String>`
String _describeType(Object? value) {
  if (value == null) return 'null';
  if (value is String) return 'a String';
  if (value is int) return 'an int';
  if (value is double) return 'a double';
  if (value is bool) return 'a bool';
  if (value is List) return 'a List';
  if (value is Map) return 'a Map';
  if (value is Set) return 'a Set';
  final name = '${value.runtimeType}';
  final article = 'AEIOU'.contains(name[0]) ? 'an' : 'a';
  return '$article $name';
}

/// Renders [value] for an error message, possibly across multiple lines when
/// the single-line form gets too wide to read
///
/// Continuation lines are indented by [indent].
List<String> _renderValueBlock(Object? value, {required int indent}) {
  final rendered = _renderValue(value);
  if (rendered.length <= 72) {
    return [rendered];
  }
  final pad = ' ' * (indent + 2);
  if (value is Map) {
    final lines = <String>['{'];
    var shown = 0;
    for (final entry in value.entries) {
      if (shown == 6) {
        lines.add('$pad…${value.length - shown} more');
        break;
      }
      lines.add(
          '$pad${_renderMapKey(entry.key)}: ${_renderChildValue(entry.value)},');
      shown++;
    }
    lines.add('${' ' * indent}}');
    return lines;
  }
  if (value is List) {
    final lines = <String>['['];
    var shown = 0;
    for (final item in value) {
      if (shown == 6) {
        lines.add('$pad…${value.length - shown} more');
        break;
      }
      lines.add('$pad${_renderChildValue(item)},');
      shown++;
    }
    lines.add('${' ' * indent}]');
    return lines;
  }
  return [_truncate(rendered, 100)];
}

/// Cuts [text] off after [maxLength] characters and marks the cut with `…`
String _truncate(String text, int maxLength) {
  if (text.length <= maxLength) {
    return text;
  }
  // never keep the first half of a surrogate pair without its second half
  final lastKept = text.codeUnitAt(maxLength - 1);
  final splitsSurrogatePair = lastKept >= 0xD800 && lastKept <= 0xDBFF;
  final end = splitsSurrogatePair ? maxLength - 1 : maxLength;
  return '${text.substring(0, end)}…';
}

/// Characters `jsonEncode` keeps as they are although they break or reorder
/// a line: DEL, the C1 controls, line and paragraph separator and the
/// bidirectional controls
final _unescapedControls = RegExp(
  '[\\u007f-\\u009f\\u2028\\u2029\\u200e\\u200f\\u202a-\\u202e\\u2066-\\u2069]',
);

/// Quotes [text] like JSON and escapes every character that could break or
/// reorder a log line
String _quote(String text) {
  return jsonEncode(text).replaceAllMapped(_unescapedControls, (match) {
    final code = match[0]!.codeUnitAt(0);
    return '\\u${code.toRadixString(16).padLeft(4, '0')}';
  });
}

// Opaque keys use their type so diagnostics never invoke user-defined toString.
// Keys come from the data like values do, so they get the same length cap.
String _renderMapKey(Object? key) {
  if (key is String) {
    return _truncate(_quote(key), 50);
  }
  if (key == null || key is num || key is bool) {
    return _quote('$key');
  }
  return _quote('<${key.runtimeType}>');
}

/// Renders [value] showing actual data, unbounded for a long `String`
///
/// Only the current level is rendered in detail. The error happened here, so
/// nested containers are only interesting as shape and collapse to
/// `{…2 keys}` and `[…3 items]`.
String _renderValue(Object? value) {
  if (value == null) {
    return 'null';
  }
  if (value is String) {
    return _quote(value);
  }
  if (value is num || value is bool) {
    return '$value';
  }
  if (value is List) {
    if (value.isEmpty) {
      return '[]';
    }
    final items = value.take(3).map(_renderChildValue);
    final more = value.length > 3 ? ', …${value.length - 3} more' : '';
    return '[${items.join(', ')}$more]';
  }
  if (value is Set) {
    return 'Set with ${value.length} items';
  }
  if (value is Map) {
    if (value.isEmpty) {
      return '{}';
    }
    final entries = value.entries
        .take(5)
        .map((e) => '${_renderMapKey(e.key)}: ${_renderChildValue(e.value)}');
    final more = value.length > 5 ? ', …${value.length - 5} more' : '';
    return '{${entries.join(', ')}$more}';
  }
  return '<${value.runtimeType}>';
}

/// Renders a child of the failure node, one level below the error location
///
/// Nested containers collapse to their shape, scalars stay visible but get a
/// tighter length cap than the node itself.
String _renderChildValue(Object? value) {
  if (value is Map) {
    if (value.isEmpty) {
      return '{}';
    }
    return '{…${value.length} ${value.length == 1 ? 'key' : 'keys'}}';
  }
  if (value is List) {
    if (value.isEmpty) {
      return '[]';
    }
    return '[…${value.length} ${value.length == 1 ? 'item' : 'items'}]';
  }
  if (value is Set) {
    return 'Set with ${value.length} items';
  }
  return _truncate(_renderValue(value), 50);
}

/// A path rendered as `shoes[0].name`, remembering where each segment starts
/// so a marker can be aligned underneath it
class _RenderedPath {
  _RenderedPath(this.text, this.starts, this.lengths);

  final String text;
  final List<int> starts;
  final List<int> lengths;

  static final _plainKey = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

  factory _RenderedPath.of(List<Object> path) {
    final buffer = StringBuffer();
    final starts = <int>[];
    final lengths = <int>[];
    for (var i = 0; i < path.length; i++) {
      final segment = path[i];
      final String token;
      if (segment is int) {
        token = '[$segment]';
      } else if (_plainKey.hasMatch('$segment')) {
        token = i == 0 ? '$segment' : '.$segment';
      } else {
        token = '[${_quote('$segment')}]';
      }
      // the marker skips a leading dot, it belongs to the separator
      final skip = token.startsWith('.') ? 1 : 0;
      starts.add(buffer.length + skip);
      lengths.add(token.length - skip);
      buffer.write(token);
    }
    return _RenderedPath(buffer.toString(), starts, lengths);
  }
}
