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
  @Deprecated(
      "By default values are optional and can only be converted when a fallback is provided "
      "i.e. .asStringOrNull() which falls back to `null`. "
      "Use .required().asString() in cases the value is mandatory. "
      "It will crash when the value couldn't be picked.")
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
