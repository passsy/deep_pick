import 'dart:convert';

import 'package:deep_pick/src/pick.dart';

export 'package:deep_pick/src/pick.dart';

@Deprecated("Call jsonDecode(String) yourself and then call pick(json, arg0, arg1, ...).as*() for further parsing")
dynamic parseRawJsonTo<T>(
  String text, [
  dynamic arg0,
  dynamic arg1,
  dynamic arg2,
  dynamic arg3,
  dynamic arg4,
  dynamic arg5,
  dynamic arg6,
  dynamic arg7,
  dynamic arg8,
  dynamic arg9,
]) {
  final dynamic json = jsonDecode(text);
  return pick(json, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9).value;
}

@Deprecated("Replace with pick(json, arg0, arg1, ...).asMapOrNull()")
Map<String, dynamic> parseJsonToMap(
  dynamic json, [
  dynamic arg0,
  dynamic arg1,
  dynamic arg2,
  dynamic arg3,
  dynamic arg4,
  dynamic arg5,
  dynamic arg6,
  dynamic arg7,
  dynamic arg8,
  dynamic arg9,
]) {
  return pick(json, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9).asMapOrNull();
}

@Deprecated("Replace with pick(json, arg0, arg1, ...).asMapOrEmpty()")
Map<String, dynamic> parseJsonToNonNullMap(
  dynamic json, [
  dynamic arg0,
  dynamic arg1,
  dynamic arg2,
  dynamic arg3,
  dynamic arg4,
  dynamic arg5,
  dynamic arg6,
  dynamic arg7,
  dynamic arg8,
  dynamic arg9,
]) {
  return pick(json, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9).asMapOrEmpty();
}

@Deprecated("Replace with pick(json, arg0, arg1, ...).asList<T>()")
List<T> parseJsonToList<T>(
  dynamic json, [
  dynamic arg0,
  dynamic arg1,
  dynamic arg2,
  dynamic arg3,
  dynamic arg4,
  dynamic arg5,
  dynamic arg6,
  dynamic arg7,
  dynamic arg8,
  dynamic arg9,
]) {
  return pick(json, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9).asList<T>();
}

@Deprecated("Replace with pick(json, arg0, arg1, ...).asListOrEmpty<T>()")
List<T> parseJsonToNonNullList<T>(
  dynamic json, [
  dynamic arg0,
  dynamic arg1,
  dynamic arg2,
  dynamic arg3,
  dynamic arg4,
  dynamic arg5,
  dynamic arg6,
  dynamic arg7,
  dynamic arg8,
  dynamic arg9,
]) {
  return pick(json, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9).asListOrEmpty<T>();
}

@Deprecated("Replace with pick(json, arg0, arg1, ...).asBool()")
bool parseJsonToBool(
  dynamic json, [
  dynamic arg0,
  dynamic arg1,
  dynamic arg2,
  dynamic arg3,
  dynamic arg4,
  dynamic arg5,
  dynamic arg6,
  dynamic arg7,
  dynamic arg8,
  dynamic arg9,
]) {
  return pick(json, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9).asBool();
}

@Deprecated("Replace with pick(json, arg0, arg1, ...).asStringOrNull()")
String parseJsonToString(
  dynamic json, [
  dynamic arg0,
  dynamic arg1,
  dynamic arg2,
  dynamic arg3,
  dynamic arg4,
  dynamic arg5,
  dynamic arg6,
  dynamic arg7,
  dynamic arg8,
  dynamic arg9,
]) {
  return pick(json, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9).asStringOrNull();
}

@Deprecated("Replace with pick(json, arg0, arg1, ...).asIntOrNull()")
int parseJsonToInt(
  dynamic json, [
  dynamic arg0,
  dynamic arg1,
  dynamic arg2,
  dynamic arg3,
  dynamic arg4,
  dynamic arg5,
  dynamic arg6,
  dynamic arg7,
  dynamic arg8,
  dynamic arg9,
]) {
  return pick(json, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9).asIntOrNull();
}

@Deprecated("Replace with pick(json, arg0, arg1, ...).asDoubleOrNull()")
double parseJsonToDouble(
  dynamic json, [
  dynamic arg0,
  dynamic arg1,
  dynamic arg2,
  dynamic arg3,
  dynamic arg4,
  dynamic arg5,
  dynamic arg6,
  dynamic arg7,
  dynamic arg8,
  dynamic arg9,
]) {
  return pick(json, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9).asDoubleOrNull();
}

@Deprecated("Replace with pick(json, arg0, arg1, ...).value")
T parseJsonTo<T>(
  dynamic json, [
  dynamic arg0,
  dynamic arg1,
  dynamic arg2,
  dynamic arg3,
  dynamic arg4,
  dynamic arg5,
  dynamic arg6,
  dynamic arg7,
  dynamic arg8,
  dynamic arg9,
]) {
  final data = pick(json, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9).value;
  if (data == null) return null;
  if (data is T) return data;
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
