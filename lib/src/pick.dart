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
  if (json == null) return Pick(null, const []);
  final selectors =
      <dynamic>[arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9]
          // null is a sign for unused "varargs"
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
        throw PickException(
            "'$selector' is not a valid index for List, expected int.");
      }
    }
    if (data is Map) {
      data = data[selector];
      continue;
    }
    // can't drill down any more to find the exact location.
    return Pick(null, path);
  }
  return Pick(data, path);
}

class Pick {
  Pick(this.value, [this.path = const []]);

  /// The picked value, might be `null`
  dynamic value;

  /// The path to [value] inside of the object
  ///
  /// I.e. ['shoes', 0, 'name']
  List<dynamic> path;

  R let<R>(R Function(NonNullPick pick) block) {
    if (value == null) {
      throw PickException(
          "value at location ${location()} is null and can't be mapped");
    }
    return block(nonNull());
  }

  R letOrNull<R>(R Function(NonNullPick pick) block) {
    if (value == null) return null;
    return block(nonNull());
  }

  String location() {
    return path.map((it) => "`$it`").join(",");
  }

  NonNullPick nonNull() => NonNullPick(value, path);
}

class NonNullPick extends Pick {
  NonNullPick(dynamic value, List<dynamic> path)
      : assert(value != null),
        super(value, path);
}

class PickException implements Exception {
  PickException(this.message);

  final String message;

  @override
  String toString() {
    return 'PickException{message: $message}';
  }
}
