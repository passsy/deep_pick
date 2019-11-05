import 'package:deep_pick/src/pick.dart';

extension Let on RequiredPick {
  R let<R>(R Function(RequiredPick pick) block) {
    return block(this);
  }
}

extension NullableLet on Pick {
  R let<R>(R Function(RequiredPick pick) block) {
    if (value == null) {
      throw PickException(
          "value at location ${location()} is null and can't be mapped");
    }
    return block(required());
  }

  R letOrNull<R>(R Function(RequiredPick pick) block) {
    if (value == null) return null;
    return block(required());
  }
}
