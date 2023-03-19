# deep_pick

[![Pub](https://img.shields.io/pub/v/deep_pick)](https://pub.dartlang.org/packages/deep_pick)
[![Pub Likes](https://img.shields.io/pub/likes/deep_pick)](https://pub.dev/packages/deep_pick/score)
![Build](https://img.shields.io/github/actions/workflow/status/passsy/deep_pick/dart.yml?branch=master)
![License](https://img.shields.io/github/license/passsy/deep_pick)
[![style: lint](https://img.shields.io/badge/style-lint-4BC0F5.svg)](https://pub.dev/packages/lint)

Simplifies manual JSON parsing with a type-safe API. 
- No `dynamic`, no manual casting
- Flexible inputs types, fixed output types
- Useful parsing error messages

```dart
import 'package:deep_pick/deep_pick.dart';

pick(json, 'parsing', 'is', 'fun').asBool(); // true
```

```bash
$ dart pub add deep_pick
```

```yaml
dependencies:
  deep_pick: ^0.10.0
```

### Example

This example demonstrates parsing of an HTTP response using `deep_pick`. You can either use it to parse individual values of a json response or parse whole objects using the `fromPick` constructor.

<table>
<tr>
<td>

```dart

  final response = await http.get(Uri.parse('https://api.countapi.xyz/stats'));
  final json = jsonDecode(response.body);

  // Parse individual fields (nullable)
  final int? requests = pick(json, 'requests').asIntOrNull();
  
  // Require values to be non-null or throw a useful error message
  final int keys_created = pick(json, 'keys_created').asIntOrThrow();
  
  // Pick deep nested values without parsing all objects in between
  final String? version = pick(json, 'meta', 'version', 'commit').asStringOrNull();
  
  
  // Parse a full object using a fromPick factory constructor
  final CounterApiStats stats = CounterApiStats.fromPick(pick(json).required());

  
  // Parse lists with a fromPick constructor 
  final List<CounterApiStats> multipleStats = pick(json, 'items')
      .asListOrEmpty((pick) => CounterApiStats.fromPick(pick));
  

```

</td>
<td>

```dart
// Http response model
class CounterApiStats {
  const CounterApiStats({
    required this.requests,
    required this.keys_created,
    required this.keys_updated,
    this.version,
  });

  final int requests;
  final int keys_created;
  final int keys_updated;
  final String? version;

  factory CounterApiStats.fromPick(RequiredPick pick) {
    return CounterApiStats(
      requests: pick('requests').asIntOrThrow(),
      keys_created: pick('keys_created').asIntOrThrow(),
      keys_updated: pick('keys_updated').asIntOrThrow(),
      version: pick('version').asStringOrNull(),
    );
  }
}
```
</td>
</tr>
</table>




## Supported types

### `String`
Returns the picked `Object` as String representation.
It doesn't matter if the value is actually a `int`, `double`, `bool` or any other Object.
`pick` calls the objects `toString` method.

```dart
pick('a').asStringOrThrow(); // "a"
pick(1).asStringOrNull(); // "1"
pick(1.0).asStringOrNull(); // "1.0"
pick(true).asStringOrNull(); // "true"
pick(User(name: "Jason")).asStringOrNull(); // User{name: Jason}
```

### `int` & `double`
`pick` tries to parse Strings with `int.tryParse` and `double.tryParse`.
A `int` can be parsed as `double` (no precision loss) but not vice versa because it could lead to mistakes.

```dart
pick(3).asIntOrThrow(); // 3
pick("3").asIntOrNull(); // 3
pick(1).asDoubleOrThrow(); // 1.0
pick("2.7").asDoubleOrNull(); // 2.7
```

### `bool`

Parsing a bool couldn't be easier with those self-explaining methods
```dart
pick(true).asBoolOrThrow(); // true
pick(false).asBoolOrThrow(); // true
pick(null).asBoolOrTrue(); // true
pick(null).asBoolOrFalse(); // false
pick(null).asBoolOrNull(); // null
pick('true').asBoolOrNull(); // true;
pick('false').asBoolOrNull(); // false;
```

`deep_pick` does not treat the `int` values `0` and `1` as `bool` as some other languages do.
Write your own logic using `.let` instead.

```dart
pick(1).asBoolOrNull(); // null
pick(1).letOrNull((pick) => pick.value == 1 ? true : pick.value == 0 ? false : null); // true 
```

### `DateTime`

Accepts most common date formats such as 
- [`ISO 8601`](https://www.w3.org/TR/NOTE-datetime) including [`RFC-3339`](https://datatracker.ietf.org/doc/html/rfc3339#section-5.6), 
- [`RFC 1123`](https://www.rfc-editor.org/rfc/rfc1123#page-55) including [HTTP `date`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Date) header, [RSS2](https://validator.w3.org/feed/docs/rss2.html) `pubDate`, [`RFC 822`](https://www.rfc-editor.org/rfc/rfc822#section-5), [`RFC 1036`](https://datatracker.ietf.org/doc/html/rfc1036#section-2.1.2) and [`RFC 2822`](https://datatracker.ietf.org/doc/html/rfc2822#page-14), 
- [`RFC 850`](https://www.rfc-editor.org/rfc/rfc850#section-2.1.4) including [`RFC 1036`](https://www.rfc-editor.org/rfc/rfc1036#section-2.1.2), `COOKIE`
- `ANSI C asctime()`

```dart
pick('2021-11-01T11:53:15Z').asDateTimeOrNull(); // UTC
pick('2021-11-01T11:53:15+0000').asDateTimeOrNull(); // ISO 8601
pick('Monday, 01-Nov-21 11:53:15 UTC').asDateTimeOrThrow(); // RFC 850
pick('Wed, 21 Oct 2015 07:28:00 GMT').asDateTimeOrThrow(); // RFC 1123
pick('Sun Nov  6 08:49:37 1994').asDateTimeOrThrow(); // asctime()
```

### `List`

When the JSON object contains a List of items that List can be mapped to a `List<T>` of objects (`T`).

```dart
pick([]).asListOrNull(SomeObject.fromPick);
pick([]).asListOrThrow(SomeObject.fromPick);
pick([]).asListOrEmpty(SomeObject.fromPick);
```

```dart
final users = [
  {'name': 'John Snow'},
  {'name': 'Daenerys Targaryen'},
];
List<Person> persons = pick(users).asListOrEmpty((pick) {
  return Person(
    name: pick('name').required().asString(),
  );
});

class Person {
  final String name;

  Person({required this.name});
}
```

#### Note 1
Extract the mapper function and use it as a reference allows to write it in a single line again :smile:

```dart
List<Person> persons = pick(users).asListOrEmpty(Person.fromPick);
```

Replacing the static function with a factory constructor doesn't work.
Constructors cannot be referenced as functions, yet ([dart-lang/language/issues/216](https://github.com/dart-lang/language/issues/216)).
Meanwhile, use `.asListOrEmpty((it) => Person.fromPick(it))` when using a factory constructor.

#### Note 2
`pick` called in the `fromPick` function uses the parameter `pick`, not the top-level function.
This is possible because `Pick` implements the `.call()` method.
This allows chaining indefinitely on the same `Pick` object while maintaining internal references for useful error messages.

Both versions produce the same result and shows you're not limited to 10 arguments.
```dart
pick(json, 'shoes', 1, 'tags', 0).asStringOrThrow();
pick(json)('shoes')(1)('tags')(0).asStringOrThrow();
```

#### whenNull

To simplify the `asList` API, the functions ignores `null` values in the `List`.
This allows the usage of `RequiredPick` over `Pick` in the `map` function.

When `null` is important for your logic you can process the `null` value by providing an optional `whenNull` mapper function.

```dart
pick([1, null, 3]).asListOrNull(
  (it) => it.asInt(), 
  whenNull: (Pick pick) => 25;
); 
// [1, 25, 3]
``` 

### `Map`

Picking the `Map` is rarely used, because `Pick` itself grants further picking using the `.call(args)` method.
Converting back to a `Map` is usually only used for existing `fromMap` mapper functions.

```dart
pick(json).asMapOrNull<String, dynamic>();
pick(json).asMapOrThrow<String, dynamic>();
pick(json).asMapOrEmpty<String, dynamic>();
```


## Custom parsers

Parsers in `deep_pick` are based on extension functions on the classes `Pick`.
This makes it flexible and easy for 3rd-party types to add custom parsers.

This example parses a `int` as Firestore `Timestamp`.
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deep_pick/deep_pick.dart';

extension TimestampPick on Pick {
  Timestamp asFirestoreTimeStampOrThrow() {
    final value = required().value;
    if (value is Timestamp) {
      return value;
    }
    if (value is int) {
      return Timestamp.fromMillisecondsSinceEpoch(value);
    }
    throw PickException("value $value at $debugParsingExit can't be casted to Timestamp");
  }

  Timestamp? asFirestoreTimeStampOrNull() {
    if (value == null) return null;
    try {
      return asFirestoreTimeStampOrThrow();
    } catch (_) {
      return null;
    }
  }
}
```

### let

When using a custom type in only a few places, it might be overkill to create all the extensions.
For those cases use the [let function](https://kotlinlang.org/api/latest/jvm/stdlib/kotlin/let.html) borrowed from Kotlin to creating neat one-liners.

```dart
final UserId id = pick(json, 'id').letOrNull((it) => UserId(it.asString()));
final Timestamp timestamp = pick(json, 'time')
    .letOrThrow((it) => Timestamp.fromMillisecondsSinceEpoch(it.asInt()));
```

## Examples

### Reading documents from Firestore
Picking values from a Firebase `DocumentSnapshot` is usually very selective.
Only a fraction of the properties have to be parsed.
In this scenario it would be overkill to map the whole document to a Dart object.
Instead, parse the values in place while staying type-safe.

Use `.asStringOrThrow()` when confident that the value is never `null` and **always** exists.
The return type then becomes non-nullable (`String` instead of `String?`).
When the `data` doesn't contain the `full_name` field (against your assumption) it would crash throwing a `PickException`.

```dart
final DocumentSnapshot userDoc = 
    await FirebaseFirestore.instance.collection('users').doc(userId).get();
final data = userDoc.data();
final String fullName = pick(data, 'full_name').asStringOrThrow();
final String? level = pick(data, 'level').asIntOrNull();
```

`deep_pick` offers an alternative `required()` API with the same result. 
This is useful to make sure a value exists before parsing it. 
In case it is `null` or absent a useful error message is printed.

```dart
final String fullName = pick(data, 'full_name').required().asString();
```

## Background & Justification

Before Dart 2.12 and the new `?[]` operator one had to write a lot of code to prevent crashes when a value isn't set! 
Reducing this boilerplate was the origin of `deep_pick`.
```dart
String milestoneCreator;
final milestone = json['milestore'];
if (milestone != null) {
  final creator = json['creator'];
  if (creator != null) {
    final login = creator['login'];
    if (login is String) {
      milestoneCreator = login;
    }
  }
}
print(milestoneCreator); // octocat
```
This example of parses an `issue` object of the [GitHub v3 API](https://developer.github.com/v3/issues/#get-an-issue).

Today with Dart 2.12+ parsing Dart data structures has become way easier with the introduction of the `?[]` operator. 
```dart
final json = jsonDecode(response.data);
final milestoneCreator = json?['milestone']?['creator']?['login'] as String?;
print(milestoneCreator); // octocat
```

`deep_pick` backports this short syntax to previous Dart versions (`<2.12`).

```dart
final milestoneCreator = pick(json, 'milestone', 'creator', 'login').asStringOrNull();
print(milestoneCreator); // octocat  
```

## Still better than vanilla

But even with the latest Dart version, `deep_pick` offers fantastic features over vanilla parsing using the `?[]` operators:

### 1. Flexible input types 

Different languages and their JSON libraries generate different JSON. 
Sometimes `id`s are `String`, sometimes `int`. Booleans are provided as `true` or with quotes as String `"true"`. 
The meaning is the same but from a type perspective they are not.

`deep_pick` does the basic conversions automatically. 
By requesting a specific return type, apps won't break when a "price" usually returns `double` (`0.99`) but for whole numbers `int` (`1` instead of `1.0`).

```dart
pick(2).asIntOrNull(); // 2
pick('2').asIntOrNull(); // 2 (Sting -> int)

pick(42.0).asDoubleOrNull(); // 42.0
pick(42).asDoubleOrNull(); // 42.0 (double -> int)

pick(true).asBoolOrFalse(); // true
pick('true').asBoolOrFalse(); // true (String -> bool) 
```

### 2. No RangeError for Lists
Using the `?[]` operator can crash for Lists. 
Accessing a list item by `index` outside of the available range causes a `RangeError`.
You can't access index 23 when the `List` has only 10 items.

```dart
json['shoes']?[23]?['id'] as String?;

// Unhandled exception:
// RangeError (index): Invalid value: Not in inclusive range 0..10: 23
```

`pick` automatically catches the `RangeError` and returns `null`.

```dart
pick(json, 'shoes', 23, 'id').asStringOrNull(); // null
```

### 3. Useful error message

Vanilla Dart returns a type error because `null` is not a `String`.
There is no information available which part is `null` or missing. 

```dart
final milestoneCreator = json?['milestone']?['creator']?['login'] as String;

// Unhandled exception:
// type 'Null' is not a subtype of type 'String' in type cast
```

`deep_pick` shows the exact location where parsing failed, making it easy to report errors to the API team.

```dart
final milestoneCreator = pick(json, 'milestone', 'creator', 'login').asStringOrThrow();

// Unhandled exception:
// PickException(
//   Expected a non-null value but location "milestone" in pick(json, "milestone" (absent), "creator", "login") is absent. 
//   Use asStringOrNull() when the value may be null at some point (String?).
// )
```

Notice the distinction between "absent" and "null" when you see such errors.
- `"absent"` means the key isn't found in a Map or a List has no item at the requested index
- `"null"` means the value at that position is actually `null`

### 4. Null is default, crashes intentional

Parsing objects from external systems isn't type-safe. 
API changes happen, and it is up to the consumer to decide how to handle them.
Consumer always have to assume the worst, such as missing values.

It's so easy to accidentally cast a value to `String` in the happy path, instead of `String?` accounting for all possible cases.
Easy to write, easy to miss in code reviews.

Forgetting that `null` could be a valid return type results in a type error:

```dart
json?['milestone']?['creator']?['login'] as String;
//                                      ----^
// Unhandled exception:
// type 'Null' is not a subtype of type 'String' in type cast
``` 

With `deep_pick`, all casting methods (`.as*()`) have `null` in mind.
For each type you have to choose between at least two ways to deal with `null`.

```dart
pick(json, ...).asStringOrNull();
pick(json, ...).asStringOrThrow();

pick(json, ...).asBoolOrNull();
pick(json, ...).asBoolOrFalse();

pick(json, ...).asListOrNull(SomeClass.fromPick);
pick(json, ...).asListOrEmpty(SomeClass.fromPick);
```

Having "Throw" and "Null" in the method name, clearly indicates the possible outcome in case the values couldn't be picked.
Throwing is not a bad habit, some properties are essential for the business logic and throwing an error the correct handling.
But throwing should be done intentional, not accidental.

### 5. Map Objects with let

Even with the new `?[]` operator, mapping a value to a new Object (i.e. when wrapping it in a domain Object) can't be done in a single line.

```dart
final value = json?['id'] as String?;
final UserId id = value == null ? null : UserId(value);
```

`deep_pick` borrows the [let function](https://kotlinlang.org/api/latest/jvm/stdlib/kotlin/let.html) from Kotlin creating a neat one-liner

```dart
final UserId id = pick(json, 'id').letOrNull((it) => UserId(it.asString()));
```

## License

```
Copyright 2019 Pascal Welsch

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
