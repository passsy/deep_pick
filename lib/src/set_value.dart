import 'package:deep_pick/deep_pick.dart';

extension SetValueExtension on Pick {
  void set(Object? value) {
    if (target == null) {
      throw PickException('Can not set value on null');
    }
    final data = target!;
    final path = this.path.toList();
    final key = path.removeAt(0);

    if (key is String) {
      final map = data as Map;
      if (path.isEmpty) {
        map[key] = value;
        return;
      }
      final nextKey = path.isEmpty ? null : path[0];
      if (map[key] == null) {
        if (nextKey is int) {
          map[key] = [];
        } else if (nextKey is String) {
          map[key] = {};
        }
      }
      pickDeep((data as Map)[key], path).set(value);
    } else if (key is int) {
      final list = data as List;
      while (list.length <= key) {
        list.add(null);
      }
      if (path.isEmpty) {
        list[key] = value;
        return;
      } else {
        final nextKey = path.isEmpty ? null : path[0];
        if (list[key] == null) {
          if (nextKey is int) {
            list[key] = [];
          } else if (nextKey is String) {
            list[key] = {};
          }
        }
        pickDeep(list[key], path).set(value);
      }
    }
  }
}
