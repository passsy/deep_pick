# deep_pick

[![Pub](https://img.shields.io/pub/v/deep_pick)](https://pub.dartlang.org/packages/deep_pick)
[![Pub](https://img.shields.io/pub/v/deep_pick?include_prereleases)](https://pub.dartlang.org/packages/deep_pick)
[![style: lint](https://img.shields.io/badge/style-lint-4BC0F5.svg)](https://pub.dev/packages/lint)
![License](https://img.shields.io/github/license/passsy/deep_pick)
[![likes](https://badges.bar/deep_pick/likes)](https://pub.dev/packages/deep_pick/score)
![Build](https://img.shields.io/github/workflow/status/passsy/deep_pick/Dart%20CI)

Simplifies manual JSON parsing with a type-safe API. 
- No `dynamic`
- No manual casting
- Flexible typed inputs, fix typed outputs

```dart
import 'package:deep_pick/deep_pick.dart';

pick(json, 'parsing', 'is', 'fun').asBool(); // true
```

```yaml
dependencies:
  deep_pick: ^0.6.0
```

### Write less when parsing JSON API responses
Example of parsing an `issue` object of the [GitHub v3 API](https://developer.github.com/v3/issues/#get-an-issue).

Before Dart 2.12 and the `?[]` operator you had to write a lot of code to prevent crashes when a value isn't set! 
This is when the `deep_pick` idea was born.
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

Today with Dart 2.12+ parsing Dart Maps is easy again. 
```dart
final json = jsonDecode(response.data);
final milestoneCreator = json?['milestone']?['creator']?['login'] as String?;
print(milestoneCreator); // octocat
```

`deep_pick` offers a similar API previous Dart versions (`<2.12`).

```dart
final milestoneCreator = pick(json, 'milestone', 'creator', 'login').asStringOrNull();
print(milestoneCreator); // octocat  
```

Even with the latest Dart version, `deep_pick` offers great features over vanilla parsing:

#### 1. Flexible input types 

Some ids are `String` others `int`. Bools are delivered as `true` or `"true"`. 
Different languages and json libraries generate different json. 
The meaning is the same but from a type perspective they are not.

`deep_pick` does the basic conversions automatically. 
By requesting a specific return type, apps won't break when a `double` value returns a `int` (`1` instead of `1.0`) for whole numbers.

```dart
pick('2').asIntOrNull(); // 2
pick(42).asDoubleOrNull(); // 42.0
pick('true').asBoolOrFalse(); // true
```

#### 2. Nullable by default

It's so easy to accidentally cast a value to `String` instead of `String?`.
Easy to write and easy to miss in a code review.
Forgetting that `null` could be valid return type results in:

```dart
json?['milestone']?['creator']?['login'] as String;
//                                      ----^
// Unhandled exception:
// type 'Null' is not a subtype of type 'String' in type cast
``` 

With `deep_pick`, all methods have `null` in mind.
For each type you have to choose between at least two ways to deal with `null`.

```dart
pick(json, 'milestone', 'creator', 'login').asStringOrNull();
pick(json, 'milestone', 'creator', 'login').asStringOrThrow();
```

Having "throw" or "null" in the method name, clearly indicates about the possible outcome in case the values couldn't be picked. 


#### 3. Map objects with let

Even with the new ?[] operator, mapping that value to a new object can't be done in a single line

```dart
final value = json?['id'] as String?;
final UserId id = value == null ? null : UserId(value);
```

`deep_pick` borrows the [let function](https://kotlinlang.org/api/latest/jvm/stdlib/kotlin/let.html) from Kotlin creating a neat one-liner

```dart
final UserId id = pick(json, 'id').letOrNull((it) => UserId(it.asString()));
```

### Make values required and non-nullable
`deep_pick` is perfect when working with Firestore `DocumentSnapshot`. 
Usually it's too much effort to map it to an actual Object (because you don't need all fields).
Instead, parse the values in place while staying type-safe. 

Use `.asStringOrThrow()` when confident the value is never `null` and **always** exists. 
The return type then becomes non-nullable (`String` instead of `String?`).
When the `data` doesn't contain the `full_name` field (against your assumption) it would crash throwing a `PickException`.

```dart
final DocumentSnapshot userDoc = 
    await FirebaseFirestore.instance.collection('users').doc(userId).get();
final data = userDoc.data();
final String fullName = pick(data, 'full_name').asStringOrThrow();
final String? level = pick(data, 'level').asIntOrNull();
```


## Supported types

### String
Returns the picked `Object` as String representation.
It doesn't matter if the value is actually a `int`, `double`, `bool` or any other Object.
`pick` calls the objects `toString` method.

```dart
pick('a').asStringOrNull(); // "a"
pick(1).asStringOrNull(); // "1"
pick(1.0).asStringOrNull(); // "1.0"
pick(true).asStringOrNull(); // "true"
pick(User(name: "Jason")).asStringOrNull(); // User{name: Jason}
```

### `int` & `double`
`pick` tries to parse Strings with `int.tryParse` and `double.tryParse`.
A `int` can be parsed as `double` (no precision loss) but not vice versa because it could lead to mistakes.

```dart
pick(1).asDoubleOrNull(); // 1.0
pick("2.7").asDoubleOrNull(); // 2.7
pick("3").asIntOrNull(); // 3
```

### `bool`

Parsing a bool is easy. Use any of the self-explaining methods
```dart
pick(true).required().asBool(); // true
pick(false).required().asBool(); // true
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

Accepts most common date formats such as `ISO 8601`. For more supported formats see [`DateTime.parse`](https://api.dart.dev/stable/1.24.2/dart-core/DateTime/parse.html).

```dart
pick('2020-03-01T13:00:00Z').asDateTimeOrNull(); // a valid DateTime object
```

### `List`

When the JSON object contains a List of items that List can be mapped to a `List<T>` of objects (`T`).

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

  static Person fromPick(RequiredPick pick) {
    return Person(
      name: pick('name').required().asString(),
    );
  }
}
```

Extract the mapper function and using it as a reference allows to write it in a single line again :smile:

```dart
List<Person> persons = pick(users).asListOrEmpty(Person.fromPick);
```

Replacing the static function with a factory constructor doesn't work.
Constructors cannot be referenced as functions, yet ([dart-lang/language/issues/216](https://github.com/dart-lang/language/issues/216)).
Meanwhile, use `.asListOrEmpty((it) => Person.fromPick(it))` when using a factory constructor.
 

### `Map`


## Custom parsers

### let

### extension functions


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
