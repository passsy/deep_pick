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
- Remove deprecated long deprecated `parseJsonTo*` methods. Use the `pick(json, args*)` api
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
- Breaking: `Pick` and `RequiredPick` have chained their constructor signature. `path` is now a named argument 
and `context` has been added.

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

```
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
