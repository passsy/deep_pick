import 'package:deep_pick/src/pick.dart';

extension StringPick on RequiredPick {
  String asString() {
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
}

extension NullableStringPick on Pick {
  String asString() {
    if (value == null) {
      throw PickException(
          "value at location ${location()} is null and not an instance of String");
    }
    return required().asString();
  }

  String /*?*/ asStringOrNull() {
    if (value == null) return null;
    try {
      return required().asString();
    } catch (_) {
      return null;
    }
  }
}
