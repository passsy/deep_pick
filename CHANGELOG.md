# Changelog

## 1.0.0 (`19.03.23`)

- Remove long deprecated methods: `addContext`, `asBool`, `asDateTime`, `asDouble`, `asInt`, `asList`, `asMap`, `asString`. Use their `as*OrThrow` replacements.
- Add support for timezones in `asDateTime*` methods [#47](https://github.com/passsy/deep_pick/pull/47), [#51](https://github.com/passsy/deep_pick/pull/51)
- Add official support for date formats `RFC 3339`, `RFC 2822` and `RFC 1036`
- Push test coverage to 100% 🤘


## 0.10.0 (`01.10.21`)

- New: Support for more date formats. `asDateTime*` received an optional `format` parameter. By default, all possible formats will be parsed. To the existing `ISO 8601` format, `RFC 1123`, `RFC 850` and `asctime` have been added which are typically used for the HTTP header or cookies.
- Documentation added for `asDouble` and `asMap`

## 0.9.0 (`02.08.21`)

- New: `pickFromJson(json, args...)` allows parsing of a json String, without manually calling `jsonDecode` [#41](https://github.com/passsy/deep_pick/pull/41)
- New: `pickDeep(json, 'some.key.inside.the.object'.split('.'))` allows picking with a dynamic depth [#40](https://github.com/passsy/deep_pick/pull/40)
- Add `Pick.index` to get the element index for list items [#38](https://github.com/passsy/deep_pick/pull/38)

  ```dart
  pick(["John", "Paul", "George", "Ringo"]).asListOrThrow((pick) {
    final index = pick.index!;
    return Artist(id: index, name: pick.asStringOrThrow());
  );
  ```

- `Pick.asIntOrThrow()` now allows parsing of doubles when one of the new `roundDouble` or `truncateDouble` parameters is `true` [#37](https://github.com/passsy/deep_pick/pull/37). Thx @stevendz
- Add dartdoc to `asList*()` extensions

## 0.8.0 (and 0.6.10 for Dart <2.12) (`12.02.21`)

- Deprecated parsing extensions of `RequiredPick` to acknowledge that all parsers eventually causes errors.
  From now on, always use `.asIntOrThrow()` instead of `.required().asInt()`. Only exception is `.required().toString()`.
  Read more in [#34](https://github.com/passsy/deep_pick/pull/34)
- Replace `dynamic` with `Object` where possible
- Rename `Pick.location()` to `Pick.debugParsingExit`
- Removal of `PickLocaiton` and `PickContext` mixins. They are now part of `Pick`
- `RequiredPick` now extends `Pick` making it easier to write parsers for custom types

## 0.7.0

- Enable nullsafety (requires Dart >=2.12)

## 0.6.10

Backports 0.8.0 to pre-nullsafety

## 0.6.0

### API changes

- Remove long deprecated `parseJsonTo*` methods. Use the `pick(json, args*)` api
- New `asXyzOrThrow()` methods as shorthand for `.required().asXyz()` featuring better error messages
  - `asBoolOrThrow()`
  - `asDateTimeOrThrow()`
  - `asDoubleOrThrow()`
  - `asIntOrThrow()`
  - `letOrThrow()`
  - `asListOrThrow()`
  - `asMapOrThrow()`
  - `asStringOrThrow()`
- New `Pick.isAbsent` getter to check if a value is absent or `null` [#24](https://github.com/passsy/deep_pick/pull/24). Absent could mean
  1. Accessing a key which doesn't exist in a `Map`
  2. Reading the value from `List` when the index is greater than the length
  3. Trying to access a key in a `Map` but the found data a `Object` which isn't a Map
- New `RequiredPick.nullable()` converting a `RequiredPick` back to a `Pick` with potential `null` value
- New `PickLocation.followablePath`. While `PickLocation.path` contains the full path to the value, `followablePath` contains only the part which could be followed with a non-nullable value

- **Breaking** `asList*()` now *requires* the mapping function.
- **Breaking** `asList*()` now ignores `null` values when parsing. The map function now receives a `RequiredPick` as fist parameter instead of a `Pick` with a potential null value, making parsing easier.

  Therefore `pick().required().asList((RequiredPick pick) => /*...*/)` only maps non-nullable values. When your lists contain `null` it will be ignored.
  This is fine in most cases and simplifies the map function.

  In rare cases, where your lists contain `null` values with meaning, use the second parameter `whenNull` to map those null values `.asList((pick) => Person.fromPick(pick), whenNull: (Pick it) => null)`. The function still receives a `Pick` which gives access to the `context` api or the `PickLocation`. But the `Pick` never holds any value.

### Parsing changes

- The String `"true"` and `"false"` are now parsed as boolean
- **Breaking** Don't parse doubles as int because the is no rounding method which satisfies all [#31](https://github.com/passsy/deep_pick/pull/31)
- **Breaking** Allow parsing of "german" doubles with `,` as decimal separator [#30](https://github.com/passsy/deep_pick/pull/30)

- Improve error messages with more details where parsing stopped

## 0.6.0-nullsafety.2

- **Breaking** `asList*()` methods now ignore `null` values. The map function now receives a `RequiredPick` as fist parameter instead of a `Pick` making parsing easier.

  Therefore `pick().required().asList((RequiredPick pick) => /*...*/)` only maps non-nullable values. When your lists contain `null` it will be ignored.
  This is fine in most cases and simplifies the map function.

  In rare cases, where your lists contain `null` values with meaning, use the second parameter `whenNull` to map those null values `.asList((pick) => Person.fromPick(pick), whenNull: (Pick it) => null)`. The function still receives a `Pick` which gives access to the `context` api or the `PickLocation`. But the `Pick` never holds any value.
  
- **Breaking** Don't parse doubles as int because the is no rounding method which satisfies all [#31](https://github.com/passsy/deep_pick/pull/31)
- **Breaking** Allow parsing of "german" doubles with `,` as decimal separator [#30](https://github.com/passsy/deep_pick/pull/30)
- Improve error messages with more details where parsing stopped
- New `RequiredPick.nullable()` converting a `RequiredPick` back to a `Pick` with potential `null` value
- New `PickLocation.followablePath`. While `PickLocation.path` contains the full path to the value, `followablePath` contains only the part which could be followed with a non-nullable value

## 0.6.0-nullsafety.1

- New `asXyzOrThrow()` methods as shorthand for `.required().asXyz()` featuring better error messages
  - `asBoolOrThrow()`
  - `asDateTimeOrThrow()`
  - `asDoubleOrThrow()`
  - `asIntOrThrow()`
  - `letOrThrow()`
  - `asListOrThrow()`
  - `asMapOrThrow()`
  - `asStringOrThrow()`
- New `Pick.isAbsent` getter to check if a value is absent or `null` [#24](https://github.com/passsy/deep_pick/pull/24). Absent could mean
  1. Accessing a key which doesn't exist in a `Map`
  2. Reading the value from `List` when the index is greater than the length
  3. Trying to access a key in a `Map` but the found data a `Object` which isn't a Map
- The String `"true"` and `"false"` are now parsed as boolean
- More nnbd refactoring

## 0.6.0-nullsafety.0

- Migrate to nullsafety (required Dart >=2.12)
- Remove long deprecated `parseJsonTo*` methods. Use the `pick(json, args*)` api
- Improve dartdoc

## 0.5.1

- Rename `Pick.addContext` to `Pick.withContext` using deprecation
- `Pick.fromContext` now accepts 10 arguments for nested structures
- Fix `Pick.fromContext` always returning `context` not the value for `key` in context `Map`

## 0.5.0

- New context API. You can now attach relevant additional information for parsing directly to the `Pick` object. This allows passing information into `fromPick` constructors without adding new parameters to all constructors in between.

  ```dart
  // Add context
  final shoes = pick(json, 'shoes')
      .addContext('apiVersion', "2.3.0")
      .addContext('lang', "en-US")
      .asListOrEmpty((p) => Shoe.fromPick(p.required()));
  ```

  ```dart
  import 'package:version/version.dart';

  // Read context
  factory Shoe.fromPick(RequiredPick pick) {
    // read context API
    final version = pick.fromContext('newApi').required().let((pick) => Version(pick.asString()));
    return Shoe(
      id: pick('id').required().asString(),
      name: pick('name').required().asString(),
      // manufacturer is a required field in the new API
      manufacturer: version >= Version(2, 3, 0)
          ? pick('manufacturer').required().asString()
          : pick('manufacturer').asStringOrNull(),
      tags: pick('tags').asListOrEmpty(),
    );
  }
  ```

- Breaking: `Pick` and `RequiredPick` have chained their constructor signature. `path` is now a named argument and `context` has been added.

```diff
- RequiredPick(this.value, [this.path = const []])
+ RequiredPick(this.value, {this.path = const [], Map<String, dynamic> context})
```

- The `path` is now correctly forwarded after `Pick#call` or `Pick#asListOrEmpty` and always shows the full path since origin

## 0.4.3

- Fix error reporting for `asMapOr[Empty|Null]` and don't swallow parsing errors
- Throw Map cast errors when parsing, not lazily when accessing the data

## 0.4.2

- Fix error reporting of `asListOrNull(mapToUser)` and `asListOrEmpty(mapToUser)`. Both now return errors during mapping and don't swallow them

## 0.4.1

- Print correct path in error message when json is `null`
- `asDateTime()` now skips parsing when the value is already a `DateTime`

## 0.4.0

### Map objects

New APIs to map picks to objects and to map list elements to objects.

```dart
RequiredPick.let<R>(R Function(RequiredPick pick) block): R
Pick.letOrNull<R>(R Function(RequiredPick pick) block): R

RequiredPick.asList<T>([T Function(Pick) map]): List<T> 
Pick.asListOrNull<T>([T Function(Pick) map]): List<T> 
Pick.asListOrEmpty<T>([T Function(Pick) map]): List<T> 
```

Here are two example how to actually use them.

```dart
// easily pick and map objects to dart objects
final Shoe oneShoe = pick(json, 'shoes', 0).letOrNull((p) => Shoe.fromPick(p));

// map list of picks to dart objects
final List<Shoe> shoes = 
     pick(json, 'shoes').asListOrEmpty((p) => Shoe.fromPick(p.required()));
```

### Required picks

`Pick` now offers a new `required()` method returning a `RequiredPick`. It makes sure the picked value exists or crashes if it is `null`. Because it can't be `null`, `RequiredPick` doesn't offer fallback methods like `.asIntOrNull()` but only `.asInt()`. This makes the API a bit easier to use for values you can't live without.

```dart
// use required() to crash if a object doesn't exist
final name = pick(json, 'shoes', 0, 'name').required().asString();
print(name); // Nike Zoom Fly 3
```

Note: Calling `.asString()` directly on `Pick` has been deprecated. You now have to call `required()` first to convert the `Pick` to a `RequiredPick` or use a mapping method with fallbacks.

### Pick deeper

Ever got a `Pick`/`RequiredPick` and you wanted to pick even further. This is now possible with the `call` method. Very useful in constructors when parsing methods.

```dart
  factory Shoe.fromPick(RequiredPick pick) {
    return Shoe(
      id: pick('id').required().asString(),
      name: pick('name').required().asString(),
      manufacturer: pick('manufacturer').asStringOrNull(),
      tags: pick('tags').asListOrEmpty(),
    );
  }
```

### Bugfixes

- Don't crash when selecting a out of range index from a `List`
- `.asMap()`, `.asMapOrNull()` and `.asMapOrEmpty()` now consistently return `Map<dynamic, dynamic>` (was `Map<String, dynamic>`)

---

Also the lib has been converted to use static extension methods which were introduced in Dart 2.6

## 0.3.0

`asMap` now expects the key type, defaults to `dynamic` instead of `String`

```diff
-Pick.asMap(): Map<String, dynamic>
+Pick.asMap<T>(): Map<T, dynamic>
```

## 0.2.0

New API!
The old `parse*` methods are now deprecated, but still work.
Replace them with the new `pick(json, arg0-9...)` method.

```diff
- final name = parseJsonToString(json, 'shoes', 0, 'name');
+ final name = pick(json, 'shoes', 0, 'name').asString();
```

`pick` returns a `Pick` which offers a rich API to parse values.

```text
.asString()
.asStringOrNull()
.asMap()
.asMapOrEmpty()
.asMapOrNull()
.asList()
.asListOrEmpty()
.asListOrNull()
.asBool()
.asBoolOrNull()
.asBoolOrTrue()
.asBoolOrFalse()
.asInt()
.asIntOrNull()
.asDouble()
.asDoubleOrNull()
.asDateTime()
.asDateTimeOrNull()
```

## 0.1.1

- pubspec description updated

## 0.1.0

- Initial version
