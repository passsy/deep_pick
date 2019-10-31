import 'package:deep_pick/deep_pick.dart';

extension StringPick on Pick {
  String asString() {
    if (value == null) {
      throw PickException(
          "value at location ${location()} is null and not an instance of String");
    }
    if (value is String) {
      return value as String;
    } else {
      if (value is List || value is Map) {
        throw PickException(
            "value at location ${location()} is of type ${value.runtimeType}. "
            "Drill further down to a value which is not a List or Map. "
            "value: $value");
      }
      return value.toString();
    }
  }

  String /*?*/ asStringOrNull() {
    if (value == null) return null;
    if (value is String) {
      return value as String;
    } else {
      return value.toString();
    }
  }
}
