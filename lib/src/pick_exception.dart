part of 'pick.dart';

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
  /// [problem], [detail] and [hint] are printed as they are, also with
  /// [Pick.redactValues]. Don't put the picked value into them.
  ///
  /// The message is rendered eagerly so the exception does not retain a
  /// reference into the parsed data structure. Respects
  /// [Pick.redactValues].
  factory PickException.fromPick(
    Pick pick,
    String problem, {
    String? detail,
    String? hint,
  }) {
    final contextHint = pick.context[requiredPickErrorHintKey] as String?;
    final valueIsMissing = pick.value == null;
    final headline = () {
      final located = '$problem at ${_describeLocation(pick._path)}';
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

/// The column a value starts at, after the indentation and the label
const _errorValueIndent = 2 + _errorLabelWidth;

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
  final rows = <String>[];
  final missingIndex = pick._missingIndex;
  if (missingIndex == null) {
    rows.addAll(_rowsForFoundValue(pick));
  } else {
    rows.addAll(_rowsForBrokenPath(pick, missingIndex));
  }
  if (detail != null) {
    rows.add(_errorRow('detail', detail));
  }
  for (final hint in hints) {
    rows.add(_errorRow('hint', hint));
  }

  if (rows.isEmpty) {
    return headline;
  }
  return [headline, '', ...rows].join('\n');
}

/// The rows of a [pick] whose path was followed to the end, the value there
/// is the problem
List<String> _rowsForFoundValue(Pick pick) {
  final value = pick.value;
  final redact = pick.redactsValues;
  final valueBlock =
      _renderValueBlock(value, indent: _errorValueIndent, redact: redact);
  final type = () {
    if (value == null) {
      return '';
    }
    if (redact) {
      // a redacted value is already shown as its type
      return '';
    }
    if (valueBlock.length > 1) {
      // a wrapped value opens with its bracket, which tells the type
      return '';
    }
    return '  (${_describeType(value)})';
  }();
  return [
    if (pick._path.isNotEmpty)
      _errorRow('query', _describeLocation(pick._path)),
    _errorRow('found', '${valueBlock.first}$type'),
    ...valueBlock.skip(1),
  ];
}

/// The rows of a [pick] whose path broke at [missingIndex]: a marker under
/// the segment that was not found, and what the data holds right before it
List<String> _rowsForBrokenPath(Pick pick, int missingIndex) {
  final path = pick._path;
  if (path.isEmpty) {
    return [];
  }
  final rendered = _RenderedPath.of(path);
  final query = _errorRow('query', rendered.text);
  if (missingIndex >= path.length) {
    // an index outside of the path can't be pointed at
    return [query];
  }
  final marker = ' ' * (_errorValueIndent + rendered.starts[missingIndex]) +
      '~' * rendered.lengths[missingIndex];
  if (pick._parent == null) {
    // nothing is claimed about a pick that has no parent to look the data up
    // in
    return [query, '$marker not found'];
  }
  final reachedValue = _valueBeforeMissingSegment(pick);
  final reason = _describeAbsentReason(reachedValue, path[missingIndex]);
  final reached = _describeLocation(path.sublist(0, missingIndex));
  final valueBlock = _renderValueBlock(
    reachedValue,
    indent: _errorValueIndent,
    redact: pick.redactsValues,
  );
  return [
    query,
    '$marker $reason',
    _errorRow('at', '$reached = ${valueBlock.first}'),
    ...valueBlock.skip(1),
  ];
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
List<String> _renderValueBlock(
  Object? value, {
  required int indent,
  required bool redact,
}) {
  if (redact) {
    return [_renderValueRedacted(value)];
  }
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

/// Describes the shape of [value] without revealing any data, see
/// [Pick.redactValues]
///
/// [Map] keys count as schema, not data, and stay visible.
String _renderValueRedacted(Object? value) {
  if (value == null) {
    return 'null';
  }
  if (value is Map) {
    if (value.isEmpty) {
      return 'Map with no keys';
    }
    final keys = value.keys.take(8).map(_renderMapKey).join(', ');
    final more = value.length > 8 ? ', …${value.length - 8} more' : '';
    return 'Map with keys $keys$more';
  }
  if (value is List) {
    final count = value.length == 1 ? '1 item' : '${value.length} items';
    return 'List with $count';
  }
  if (value is Set) {
    return 'Set with ${value.length} items';
  }
  return '<${value.runtimeType}>';
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
      absent._path.sublist(parent._path.length, absent._missingIndex);
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
