import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

void main() {
  group("Pick", () {
    test("pick from null returns null Pick with full location", () {
      final p = pick(null, 'some', 'path');
      expect(p.path, ['some', 'path']);
      expect(p.value, null);
    });

    test("toString() prints value and path", () {
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
          throwsA(isA<PickException>().having(
              (e) => e.toString(),
              'toString',
              allOf(
                  contains('[set]'), contains("Set"), contains("index (0)")))));
    });

    test("call()", () {
      final data = [
        {"name": "John Snow"},
        {"name": "Daenerys Targaryen"},
      ];

      final picked = pick(data, 0);
      expect(picked.value, {"name": "John Snow"});

      // pick further
      expect(picked("name").required().asString(), "John Snow");
    });

    test("pick deeper than data structure returns null pick", () {
      final p = pick([], "a", "b");
      expect(p.path, ["a", "b"]);
      expect(p.value, isNull);
    });
  });

  group("parsing", () {
    test("asStringOrNull()", () {
      expect(picked("adam").asStringOrNull(), "adam");
      expect(nullPick().asStringOrNull(), isNull);
    });

    test("asStringOrDefault()", () {
      expect(picked("adam").asStringOrDefault("eva"), "adam");
      expect(nullPick().asStringOrDefault("eva"), "eva");
    });

    test("asMapOrNull()", () {
      expect(picked({"ab": "cd"}).asMapOrNull(), {"ab": "cd"});
      expect(nullPick().asMapOrNull(), isNull);
    });

    test("asMapOrEmpty()", () {
      expect(picked({"ab": "cd"}).asMapOrEmpty(), {"ab": "cd"});
      expect(picked("a").asMapOrEmpty(), {});
      expect(nullPick().asMapOrEmpty(), {});
    });

    test("asMapOrDefault()", () {
      expect(picked({"ab": "cd"}).asMapOrDefault({"foo": "bar"}), {"ab": "cd"});
      expect(picked("a").asMapOrDefault({"foo": "bar"}), {"foo": "bar"});
      expect(nullPick().asMapOrDefault({"foo": "bar"}), {"foo": "bar"});
    });

    test("asListOrNull()", () {
      expect(picked([1, 2, 3]).asListOrNull<int>(), [1, 2, 3]);
      expect(nullPick().asListOrNull<int>(), isNull);
    });

    test("asListOrEmpty()", () {
      expect(picked([1, 2, 3]).asListOrEmpty<int>(), [1, 2, 3]);
      expect(picked("a").asListOrEmpty<int>(), []);
      expect(nullPick().asListOrEmpty<int>(), []);
    });

    test("asListOrDefault()", () {
      expect(picked([1, 2, 3]).asListOrDefault<int>([8, 9]), [1, 2, 3]);
      expect(picked("a").asListOrDefault<int>([8, 9]), [8, 9]);
      expect(nullPick().asListOrDefault<int>([8, 9]), [8, 9]);
    });

    test("asBoolOrNull()", () {
      expect(picked(true).asBoolOrNull(), isTrue);
      expect(nullPick().asBoolOrNull(), isNull);
    });

    test("asBoolOrTrue()", () {
      expect(picked(true).asBoolOrTrue(), isTrue);
      expect(picked(false).asBoolOrTrue(), isFalse);
      expect(nullPick().asBoolOrTrue(), isTrue);
    });

    test("asBoolOrFalse()", () {
      expect(picked(true).asBoolOrFalse(), isTrue);
      expect(picked(false).asBoolOrFalse(), isFalse);
      expect(nullPick().asBoolOrFalse(), isFalse);
    });

    test("asIntOrNull()", () {
      expect(picked(1).asIntOrNull(), 1);
      expect(nullPick().asIntOrNull(), isNull);
    });

    test("asIntOrDefault()", () {
      expect(picked(1).asIntOrDefault(9), 1);
      expect(nullPick().asIntOrDefault(9), 9);
    });

    test("asDoubleOrNull()", () {
      expect(picked(1).asDoubleOrNull(), 1.0);
      expect(picked(2.0).asDoubleOrNull(), 2.0);
      expect(picked("3.0").asDoubleOrNull(), 3.0);
      expect(picked("a").asDoubleOrNull(), isNull);
      expect(nullPick().asDoubleOrNull(), isNull);
    });

    test("asDoubleOrDefault()", () {
      expect(picked(1).asDoubleOrDefault(9.0), 1.0);
      expect(picked(2.0).asDoubleOrDefault(9.0), 2.0);
      expect(picked("3.0").asDoubleOrDefault(9.0), 3.0);
      expect(picked("a").asDoubleOrDefault(9.0), 9.0);
      expect(nullPick().asDoubleOrDefault(9.0), 9.0);
    });

    test("asDateTimeOrNull()", () {
      expect(picked("2012-02-27 13:27:00,123456z").asDateTimeOrNull(),
          DateTime.utc(2012, 2, 27, 13, 27, 0, 123, 456));
      expect(picked("1").asDateTimeOrNull(), isNull);
      expect(picked("Bubblegum").asDateTimeOrNull(), isNull);
      expect(nullPick().asDateTimeOrNull(), isNull);
    });

    test("asDateTimeOrDefault()", () {
      final defaultValue = DateTime.utc(2020, 10, 20);
      expect(
          picked("2012-02-27 13:27:00,123456z")
              .asDateTimeOrDefault(defaultValue),
          DateTime.utc(2012, 2, 27, 13, 27, 0, 123, 456));
      expect(picked("1").asDateTimeOrDefault(defaultValue), defaultValue);
      expect(
          picked("Bubblegum").asDateTimeOrDefault(defaultValue), defaultValue);
      expect(nullPick().asDateTimeOrDefault(defaultValue), defaultValue);
    });

    test("letOrNull()", () {
      expect(
          picked({"name": "John Snow"})
              .letOrNull((pick) => Person.fromJson(pick.asMap())),
          Person(name: "John Snow"));
      expect(
          nullPick().letOrNull((pick) => Person.fromJson(pick.asMap())), null);
    });

    test("letOrDefault()", () {
      final defaultValue = Person(name: "Arya Stark");
      expect(
          picked({"name": "John Snow"}).letOrDefault(
              defaultValue, (pick) => Person.fromJson(pick.asMap())),
          Person(name: "John Snow"));
      expect(
          nullPick().letOrDefault(
              defaultValue, (pick) => Person.fromJson(pick.asMap())),
          defaultValue);
    });

    test("asListOrEmpty(Pick -> T)", () {
      final data = [
        {"name": "John Snow"},
        {"name": "Daenerys Targaryen"},
      ];
      expect(
          picked(data)
              .asListOrEmpty((it) => Person.fromJson(it.required().asMap())),
          [
            Person(name: "John Snow"),
            Person(name: "Daenerys Targaryen"),
          ]);
      expect(
          picked([])
              .required()
              .asList((pick) => Person.fromJson(pick.required().asMap())),
          []);
      expect(
          nullPick().asListOrEmpty(
              (pick) => Person.fromJson(pick.required().asMap())),
          []);
    });

    test("asListOrNull(Pick -> T)", () {
      final data = [
        {"name": "John Snow"},
        {"name": "Daenerys Targaryen"},
      ];
      expect(
          picked(data)
              .asListOrNull((pick) => Person.fromJson(pick.required().asMap())),
          [
            Person(name: "John Snow"),
            Person(name: "Daenerys Targaryen"),
          ]);
      expect(
          picked([])
              .asListOrNull((pick) => Person.fromJson(pick.required().asMap())),
          []);
      expect(
          nullPick()
              .asListOrNull((pick) => Person.fromJson(pick.required().asMap())),
          null);
    });

    test("asListOrDefault(Pick -> T)", () {
      final data = [
        {"name": "John Snow"},
        {"name": "Daenerys Targaryen"},
      ];
      final defaultValue = [
        Person(name: "Arya Stark"),
      ];
      expect(
          picked(data).asListOrDefault(
              defaultValue, (pick) => Person.fromJson(pick.required().asMap())),
          [
            Person(name: "John Snow"),
            Person(name: "Daenerys Targaryen"),
          ]);
      expect(
          picked([]).asListOrDefault(
              defaultValue, (pick) => Person.fromJson(pick.required().asMap())),
          []);
      expect(
          nullPick().asListOrDefault(
              defaultValue, (pick) => Person.fromJson(pick.required().asMap())),
          defaultValue);
    });
  });

  group("invalid pick", () {
    test("out of range in list returns null pick", () {
      final data = [
        {"name": "John Snow"},
        {"name": "Daenerys Targaryen"},
      ];
      expect(pick(data, 10).value, isNull);
    });

    test("unknown property in map returns null", () {
      final data = {"name": "John Snow"};
      expect(pick(data, 'birthday').value, isNull);
    });
  });
}

Pick picked(dynamic value) {
  return pick([value], 0);
}

Pick nullPick() {
  return pick(<String, dynamic>{}, "unknownKey");
}

Matcher pickException({List<String> containing}) {
  return const TypeMatcher<PickException>()
      .having((e) => e.message, 'message', stringContainsInOrder(containing));
}

class Person {
  Person({
    this.name,
  }) : assert(name != null);

  factory Person.fromJson(Map<String, dynamic> data) {
    return Person(
      name: pick(data, "name").required().asString(),
    );
  }

  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}
