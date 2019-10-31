import 'package:deep_pick/deep_pick.dart';

extension MapPick on Pick {
  Map<RK, RV> asMap<RK, RV>() {
    if (value == null) {
      throw PickException(
          "value at location ${location()} is null and not an instance of Map<dynamic, dynamic>");
    }
    if (value is Map) {
      return (value as Map<dynamic, dynamic>).cast();
    } else {
      throw PickException(
          "value $value of type ${value.runtimeType} at location ${location()} can't be casted to Map<dynamic, dynamic>");
    }
  }

  Map<RK, RV> asMapOrEmpty<RK, RV>() {
    if (value == null) return <RK, RV>{};
    if (value is Map) {
      return (value as Map<dynamic, dynamic>).cast();
    } else {
      return <RK, RV>{};
    }
  }

  Map<RK, RV> /*?*/ asMapOrNull<RK, RV>() {
    if (value == null) return null;
    if (value is Map) {
      return (value as Map<dynamic, dynamic>).cast();
    } else {
      return null;
    }
  }
}
