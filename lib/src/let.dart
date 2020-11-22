import 'package:deep_pick/src/pick.dart';

extension Let on RequiredPick {
  /// Maps the pick and returns the result
  ///
  /// This allows writing parsing logic from left to right without nesting
  ///
  /// Example:
  ///
  /// ```
  /// // with .let
  /// User user = pick(json, 'users', 0).required().let((pick) => User.fromJson(pick.asMap()));
  ///
  /// // without .let
  /// User user = User.fromJson(pick(json, 'users', 0).required().asMap());
  ///
  /// ```
  R let<R>(R Function(RequiredPick pick) block) {
    return block(this);
  }
}

extension NullableLet on Pick {
  /// Maps the pick if [value] != null and returns the result.
  ///
  /// This methods allows mapping of optional values in a single line
  ///
  /// Example:
  ///
  /// ```
  /// // with letOrNull
  /// User? user = pick(json, 'users', 0).letOrNull((pick) => User.fromJson(pick.asMap()));
  ///
  /// // traditionally
  /// Pick pick = pick(json, 'users', 0);
  /// User? user;
  /// if (pick.value != null) {
  ///   user = User.fromJson(pick.asMap());
  /// }
  /// ```
  R? letOrNull<R>(R Function(RequiredPick pick) block) {
    if (value == null) return null;
    return block(required());
  }
}
