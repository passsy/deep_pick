import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

void main() {
  test("null is acceptable", () {
    final p = pick(null);
    expect(p.value, isNull);
  });

  test("toString() works as expected", () {
    // ignore: deprecated_member_use_from_same_package
    expect(Pick("a", ["b", 0]).toString(), "Pick(value=a, path=[b, 0])");
  });
}
