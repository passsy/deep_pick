import 'package:deep_pick/src/pick.dart';

extension DateTimePick on RequiredPick {
  /// Examples of parsable date formats:
  ///
  /// - `"2012-02-27 13:27:00"`
  /// - `"2012-02-27 13:27:00.123456z"`
  /// - `"2012-02-27 13:27:00,123456z"`
  /// - `"20120227 13:27:00"`
  /// - `"20120227T132700"`
  /// - `"20120227"`
  /// - `"+20120227"`
  /// - `"2012-02-27T14Z"`
  /// - `"2012-02-27T14+00:00"`
  /// - `"-123450101 00:00:00 Z"`: in the year -12345.
  /// - `"2002-02-27T14:00:00-0500"`: Same as `"2002-02-27T19:00:00Z"`
  DateTime asDateTime() {
    if (value is String) {
      final dateTime = DateTime.tryParse(value as String);
      if (dateTime != null) {
        return dateTime;
      }
    }
    throw PickException(
        "value $value of type ${value.runtimeType} at location ${location()} can't be parsed as DateTime");
  }
}

extension NullableDateTimePick on Pick {
  @Deprecated("Use .required().asDateTime()")
  DateTime asDateTime() {
    if (value == null) {
      throw PickException(
          "value at location ${location()} is null and not an instance of DateTime");
    }
    return required().asDateTime();
  }

  /// Examples of parsable date formats:
  ///
  /// - `"2012-02-27 13:27:00"`
  /// - `"2012-02-27 13:27:00.123456z"`
  /// - `"2012-02-27 13:27:00,123456z"`
  /// - `"20120227 13:27:00"`
  /// - `"20120227T132700"`
  /// - `"20120227"`
  /// - `"+20120227"`
  /// - `"2012-02-27T14Z"`
  /// - `"2012-02-27T14+00:00"`
  /// - `"-123450101 00:00:00 Z"`: in the year -12345.
  /// - `"2002-02-27T14:00:00-0500"`: Same as `"2002-02-27T19:00:00Z"`
  DateTime /*?*/ asDateTimeOrNull() {
    if (value == null) return null;
    try {
      return required().asDateTime();
    } catch (_) {
      return null;
    }
  }
}
