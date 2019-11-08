import 'package:deep_pick/src/pick.dart';

extension Let on RequiredPick {
  R let<R>(R Function(RequiredPick pick) block) {
    return block(this);
  }
}

extension NullableLet on Pick {
  R letOrNull<R>(R Function(RequiredPick pick) block) {
    if (value == null) return null;
    return block(required());
  }
}
