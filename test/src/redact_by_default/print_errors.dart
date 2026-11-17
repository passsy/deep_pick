// Prints the messages of picks that fail, for redact_by_default_test.dart,
// which runs it with and without --define=deep_pick.redactValues=true
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:deep_pick/deep_pick.dart';

const _data = {'name': 'PRIVATE_VALUE'};

String _message(Pick root) {
  try {
    root('name').asIntOrThrow();
  } on PickException catch (e) {
    return e.message;
  }
  throw StateError('did not throw');
}

void _inIsolate(SendPort port) {
  port.send(_message(pick(_data)));
}

Future<void> main() async {
  final port = ReceivePort();
  await Isolate.spawn(_inIsolate, port.sendPort);
  stdout.writeln(jsonEncode({
    'default': _message(pick(_data)),
    'opt-out': _message(pick(_data).redactValues(enabled: false)),
    'isolate': await port.first,
  }));
}
