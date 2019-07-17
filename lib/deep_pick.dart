import 'dart:convert';

dynamic parseRawJsonTo<T>(String text, [dynamic arg0, dynamic arg1, dynamic arg2, dynamic arg3]) {
  final dynamic json = jsonDecode(text);
  return parseJsonTo<T>(json, arg0, arg1, arg2, arg3);
}

Map<String, dynamic> parseJsonToMap(dynamic json, [dynamic arg0, dynamic arg1, dynamic arg2, dynamic arg3]) {
  return parseJsonTo<Map<String, dynamic>>(json, arg0, arg1, arg2, arg3);
}

Map<String, dynamic> parseJsonToNonNullMap(dynamic json, [dynamic arg0, dynamic arg1, dynamic arg2, dynamic arg3]) {
  return parseJsonTo<Map<String, dynamic>>(json, arg0, arg1, arg2, arg3) ?? const <String, dynamic>{};
}

List<T> parseJsonToList<T>(dynamic json, [dynamic arg0, dynamic arg1, dynamic arg2, dynamic arg3]) {
  return parseJsonTo<List<dynamic>>(json, arg0, arg1, arg2, arg3)?.cast<T>();
}

List<T> parseJsonToNonNullList<T>(dynamic json, [dynamic arg0, dynamic arg1, dynamic arg2, dynamic arg3]) {
  return parseJsonTo<List<dynamic>>(json, arg0, arg1, arg2, arg3)?.cast<T>() ?? <T>[];
}

bool parseJsonToBool(dynamic json, [dynamic arg0, dynamic arg1, dynamic arg2, dynamic arg3]) {
  return parseJsonTo<bool>(json, arg0, arg1, arg2, arg3);
}

String parseJsonToString(dynamic json, [dynamic arg0, dynamic arg1, dynamic arg2, dynamic arg3]) {
  return parseJsonTo<String>(json, arg0, arg1, arg2, arg3);
}

int parseJsonToInt(dynamic json, [dynamic arg0, dynamic arg1, dynamic arg2, dynamic arg3]) {
  return parseJsonTo<int>(json, arg0, arg1, arg2, arg3);
}

double parseJsonToDouble(dynamic json, [dynamic arg0, dynamic arg1, dynamic arg2, dynamic arg3]) {
  return parseJsonTo<double>(json, arg0, arg1, arg2, arg3);
}

T parseJsonTo<T>(dynamic json, [dynamic arg0, dynamic arg1, dynamic arg2, dynamic arg3]) {
  if (json == null) return null;
  final selectors = <dynamic>[arg0, arg1, arg2, arg3].where((dynamic it) => it != null).toList(growable: false);
  dynamic data = json;
  for (final s in selectors) {
    if (data is List) {
      if (s is int) {
        data = data[s];
        continue;
      } else {
        throw "'$s' is not a valid index for List, expected int.";
      }
    }
    if (data is Map) {
      data = data[s];
      continue;
    }
    // can't drill down any more
    return null;
  }
  if (data is T) {
    return data;
  } else {
    if (data == null) return null;
    if (T == int) {
      if (data is String) {
        return num.tryParse(data).toInt() as T;
      }
      if (data is num) {
        return data.toInt() as T;
      }
    }
    if (T == double) {
      if (data is String) {
        return num.tryParse(data).toDouble() as T;
      }
      if (data is num) {
        return data.toDouble() as T;
      }
      return null;
    }
    if (T == String && data is! String) {
      return data.toString() as T;
    }

    return null;
  }
}
