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

  test(
      "picking from sets by index is illegal "
      "because to order is not guaranteed", () {
    final data = {
      "set": {"a", "b", "c"},
    };
    expect(
        () => pick(data, 'set', 0),
        throwsA(isA<PickException>().having((e) => e.toString(), 'toString',
            allOf(contains('[set]'), contains("Set"), contains("index (0)")))));
  });

  test("pick further", () {
    final data = [
      {"name": "John Snow"},
      {"name": "Daenerys Targaryen"},
    ];

    final picked = pick(data, 0);
    expect(picked.value, {"name": "John Snow"});

    // pick further
    expect(picked("name").asString(), "John Snow");
  });
}
