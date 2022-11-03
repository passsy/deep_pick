// ignore_for_file: avoid_dynamic_calls

import 'package:deep_pick/deep_pick.dart';

extension SetValueExtension on Pick {
  void set(Object? value) {
    if (target == null) {
      throw PickException('Can not set value on null');
    }
    final /*Map|List|null*/ dynamic data = target;
    final path = this.path.toList();
    final Object key = path.removeAt(0);

    if (key is String) {
      final map = data as Map;
      if (path.isEmpty) {
        map[key] = value;
        return;
      }
    } else if (key is int) {
      final list = data as List;
      while (list.length <= key) {
        list.add(null);
      }
      if (path.isEmpty) {
        list[key] = value;
        return;
      }
    } else {
      throw PickException(
        'Can not set value for object ${data.runtimeType} $data',
      );
    }

    final nextKey = path.isEmpty ? null : path[0];
    if (data[key] == null) {
      if (nextKey is int) {
        data[key] = [];
      } else if (nextKey is String) {
        data[key] = {};
      }
    }
    pickDeep(data[key], path).set(value);
  }
}
