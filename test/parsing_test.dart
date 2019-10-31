import 'package:deep_pick/deep_pick.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

void main() {
  group("Pick parsing", () {
    test("asString()", () {
      expect(_picked("adam").asString(), "adam");
      expect(_picked(1).asString(), "1");
      expect(_picked(2.0).asString(), "2.0");
      expect(() => _nullPick().asString(),
          throwsA(pickException(containing: ["unknownKey", "null", "String"])));
    });

    test("asString() doesn't transform Maps and Lists with toString", () {
      expect(
          () => _picked(["a", "b"]).asString(),
          throwsA(pickException(
              containing: ["List<String>", "not a List or Map", "[a, b]"])));
      expect(
          () => _picked({"a": "b"}).asString(),
          throwsA(pickException(containing: [
            "Map<String, String>",
            "not a List or Map",
            "{a: b}"
          ])));
    });

    test("asStringOrNull()", () {
      expect(_picked("adam").asStringOrNull(), "adam");
      expect(_nullPick().asStringOrNull(), isNull);
    });

    test("asMap()", () {
      expect(_picked({"ab": "cd"}).asMap(), {"ab": "cd"});
      expect(_picked({"ab": "cd"}).asMap<String>(), {"ab": "cd"});
      expect(
          () => _picked({"ab": "cd"}).asMap<int>(),
          throwsA(pickException(
              containing: ["{ab: cd}", "String", "Map<int, dynamic>"])));
      expect(
          () => _picked("Bubblegum").asMap<int>(),
          throwsA(pickException(
              containing: ["Bubblegum", "String", "Map<int, dynamic>"])));
      expect(
          () => _nullPick().asMap<String>(),
          throwsA(pickException(
              containing: ["unknownKey", "null", "Map<String, dynamic>"])));
    });

    test("asMapOrNull()", () {
      expect(_picked({"ab": "cd"}).asMapOrNull(), {"ab": "cd"});
      expect(_nullPick().asMapOrNull(), isNull);
    });

    test("asMapOrEmpty()", () {
      expect(_picked({"ab": "cd"}).asMapOrEmpty(), {"ab": "cd"});
      expect(_nullPick().asMapOrEmpty(), {});
    });

    test("asList()", () {
      expect(_picked(["a", "b", "c"]).asList(), ["a", "b", "c"]);
      expect(_picked([1, 2, 3]).asList<int>(), [1, 2, 3]);
      expect(
          () => _picked("Bubblegum").asList(),
          throwsA(pickException(
              containing: ["Bubblegum", "String", "List<dynamic>"])));
      expect(
          () => _nullPick().asList(),
          throwsA(pickException(
              containing: ["unknownKey", "null", "List<dynamic>"])));
      expect(
          () => _nullPick().asList<String>(),
          throwsA(pickException(
              containing: ["unknownKey", "null", "List<String>"])));
    });

    test("asListOrNull()", () {
      expect(_picked([1, 2, 3]).asListOrNull<int>(), [1, 2, 3]);
      expect(_nullPick().asListOrNull<int>(), isNull);
    });

    test("asListOrEmpty()", () {
      expect(_picked([1, 2, 3]).asListOrEmpty<int>(), [1, 2, 3]);
      expect(_nullPick().asListOrEmpty<int>(), []);
    });

    test("asBool()", () {
      expect(_picked(true).asBool(), isTrue);
      expect(() => _picked("Bubblegum").asBool(),
          throwsA(pickException(containing: ["Bubblegum", "String", "bool"])));
      expect(() => _nullPick().asBool(),
          throwsA(pickException(containing: ["unknownKey", "null", "bool"])));
    });

    test("asBoolOrNull()", () {
      expect(_picked(true).asBoolOrNull(), isTrue);
      expect(_nullPick().asBoolOrNull(), isNull);
    });

    test("asBoolOrTrue()", () {
      expect(_picked(true).asBoolOrTrue(), isTrue);
      expect(_picked(false).asBoolOrTrue(), isFalse);
      expect(_nullPick().asBoolOrTrue(), isTrue);
    });

    test("asBoolOrFalse()", () {
      expect(_picked(true).asBoolOrFalse(), isTrue);
      expect(_picked(false).asBoolOrFalse(), isFalse);
      expect(_nullPick().asBoolOrFalse(), isFalse);
    });

    test("asInt()", () {
      expect(_picked(1).asInt(), 1);
      expect(_picked("1").asInt(), 1);
      expect(() => _picked("Bubblegum").asInt(),
          throwsA(pickException(containing: ["Bubblegum", "String", "int"])));
      expect(() => _nullPick().asInt(),
          throwsA(pickException(containing: ["unknownKey", "null", "int"])));
    });

    test("asIntOrNull()", () {
      expect(_picked(1).asIntOrNull(), 1);
      expect(_nullPick().asIntOrNull(), isNull);
    });

    test("asDouble()", () {
      expect(_picked(1).asDouble(), 1.0);
      expect(_picked(2.0).asDouble(), 2.0);
      expect(_picked("3.0").asDouble(), 3.0);
      expect(
          () => _picked("Bubblegum").asDouble(),
          throwsA(
              pickException(containing: ["Bubblegum", "String", "double"])));
      expect(() => _nullPick().asDouble(),
          throwsA(pickException(containing: ["unknownKey", "null", "double"])));
    });

    test("asDoubleOrNull()", () {
      expect(_picked(1).asDoubleOrNull(), 1.0);
      expect(_picked(2.0).asDoubleOrNull(), 2.0);
      expect(_picked("3.0").asDoubleOrNull(), 3.0);
      expect(_picked("a").asDoubleOrNull(), isNull);
      expect(_nullPick().asDoubleOrNull(), isNull);
    });

    test("asDateTime()", () {
      expect(_picked("2012-02-27 13:27:00,123456z").asDateTime(),
          DateTime.utc(2012, 2, 27, 13, 27, 0, 123, 456));
      expect(
          () => _picked("Bubblegum").asDateTime(),
          throwsA(
              pickException(containing: ["Bubblegum", "String", "DateTime"])));
      expect(
          () => _nullPick().asDateTime(),
          throwsA(
              pickException(containing: ["unknownKey", "null", "DateTime"])));
    });

    test("asDateTimeOrNull()", () {
      expect(_picked("2012-02-27 13:27:00,123456z").asDateTimeOrNull(),
          DateTime.utc(2012, 2, 27, 13, 27, 0, 123, 456));
      expect(_picked("1").asDateTimeOrNull(), isNull);
      expect(_picked("Bubblegum").asDateTimeOrNull(), isNull);
      expect(_nullPick().asDateTimeOrNull(), isNull);
    });

    test("let()", () {
      expect(
          _picked({"name": "John Snow"})
              .let((pick) => Person.fromJson(pick.asMap())),
          Person(name: "John Snow"));
      expect(
          () => _nullPick().let((pick) => Person.fromJson(pick.asMap())),
          throwsA(pickException(
              containing: ["unknownKey", "null", "can't be mapped"])));
    });

    test("mapOrNull()", () {
      expect(
          _picked({"name": "John Snow"})
              .letOrNull((pick) => Person.fromJson(pick.asMap())),
          Person(name: "John Snow"));
      expect(
          _nullPick().letOrNull((pick) => Person.fromJson(pick.asMap())), null);
    });

    test("mapList(Pick -> T)", () {
      final data = [
        {"name": "John Snow"},
        {"name": "Daenerys Targaryen"},
      ];
      expect(_picked(data).mapList((pick) => Person.fromJson(pick.asMap())), [
        Person(name: "John Snow"),
        Person(name: "Daenerys Targaryen"),
      ]);
      expect(_picked([]).mapList((pick) => Person.fromJson(pick.asMap())), []);
      expect(() => _nullPick().mapList((pick) => Person.fromJson(pick.asMap())),
          throwsA(pickException(containing: ["unknownKey", "null", "List"])));
    });

    test("mapListOrEmpty(Pick -> T)", () {
      final data = [
        {"name": "John Snow"},
        {"name": "Daenerys Targaryen"},
      ];
      expect(
          _picked(data).mapListOrEmpty((pick) => Person.fromJson(pick.asMap())),
          [
            Person(name: "John Snow"),
            Person(name: "Daenerys Targaryen"),
          ]);
      expect(
          _picked([]).mapListOrEmpty((pick) => Person.fromJson(pick.asMap())),
          []);
      expect(
          _nullPick().mapListOrEmpty((pick) => Person.fromJson(pick.asMap())),
          []);
    });

    test("mapListOrNull(Pick -> T)", () {
      final data = [
        {"name": "John Snow"},
        {"name": "Daenerys Targaryen"},
      ];
      expect(
          _picked(data).mapListOrNull((pick) => Person.fromJson(pick.asMap())),
          [
            Person(name: "John Snow"),
            Person(name: "Daenerys Targaryen"),
          ]);
      expect(_picked([]).mapListOrNull((pick) => Person.fromJson(pick.asMap())),
          []);
      expect(_nullPick().mapListOrNull((pick) => Person.fromJson(pick.asMap())),
          null);
    });
  });
}

Pick _picked(dynamic value) {
  return pick([value], 0);
}

Pick _nullPick() {
  return pick(<String, dynamic>{}, "unknownKey");
}

Matcher pickException({List<String> containing}) {
  return const TypeMatcher<PickException>()
      .having((e) => e.message, 'message', stringContainsInOrder(containing));
}

class Person {
  Person({
    @required this.name,
  }) : assert(name != null);

  factory Person.fromJson(Map<String, dynamic> data) {
    return Person(
      name: pick(data, "name").asString(),
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
