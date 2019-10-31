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
