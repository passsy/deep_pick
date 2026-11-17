@TestOn('vm')
library redact_by_default_test;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// Runs print_errors.dart with [defines] and returns its output by label
Future<Map<String, String>> runPrintErrors(List<String> defines) async {
  final result = await Process.run(Platform.resolvedExecutable, [
    ...defines,
    'test/src/redact_by_default/print_errors.dart',
  ]);
  expect(result.exitCode, 0, reason: '${result.stderr}');
  return (jsonDecode(result.stdout as String) as Map).cast();
}

void main() {
  test('values are shown without the define', () async {
    final messages = await runPrintErrors([]);
    expect(messages['default'], contains('PRIVATE_VALUE'));
    expect(messages['isolate'], contains('PRIVATE_VALUE'));
  });

  test('the define redacts by default, also in other isolates', () async {
    final messages = await runPrintErrors(['-Ddeep_pick.redactValues=true']);
    expect(messages['default'], contains('could not parse an int at name'));
    expect(messages['default'], isNot(contains('PRIVATE_VALUE')));
    expect(messages['isolate'], isNot(contains('PRIVATE_VALUE')));
  });

  test('redactValues(enabled: false) shows values despite the define',
      () async {
    final messages = await runPrintErrors(['-Ddeep_pick.redactValues=true']);
    expect(messages['opt-out'], contains('PRIVATE_VALUE'));
  });
}
