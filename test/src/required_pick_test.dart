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

  test("(required) pick further", () {
    final data = [
      {"name": "John Snow"},
      {"name": "Daenerys Targaryen"},
    ];

    final picked = pick(data, 0).required();
    expect(picked.value, {"name": "John Snow"});

    // pick further
    expect(picked("name").required().asString(), "John Snow");
  });
}
