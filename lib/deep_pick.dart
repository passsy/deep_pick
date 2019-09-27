import 'dart:convert';

import 'package:deep_pick/src/pick.dart';

export 'package:deep_pick/src/pick.dart';

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
