import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

void main() {
  test("can't have null value", () {
    expect(() => RequiredPick(null), throwsA(isA<StateError>()));
  });

  test("toString() works as expected", () {
    // ignore: deprecated_member_use_from_same_package
    expect(RequiredPick("a", ["b", 0]).toString(),
        "RequiredPick(value=a, path=[b, 0])");
  });
}
