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
