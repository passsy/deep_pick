[![Pub](https://img.shields.io/pub/v/deep_pick)](https://pub.dartlang.org/packages/deep_pick)
[![Pub](https://img.shields.io/pub/v/deep_pick?include_prereleases)](https://pub.dartlang.org/packages/deep_pick)
[![style: lint](https://img.shields.io/badge/style-lint-4BC0F5.svg)](https://pub.dev/packages/lint)
![License](https://img.shields.io/github/license/passsy/deep_pick)
[![likes](https://badges.bar/deep_pick/likes)](https://pub.dev/packages/deep_pick/score)
![Build](https://img.shields.io/github/workflow/status/passsy/deep_pick/Dart%20CI)

# deep_pick

Simplifies manual JSON parsing with a type-safe API. 
- No `null` checks
- No `dynamic` and manual casting
- single line null-aware mapping

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

Parsing Dart Maps is easy but error prone. Forgetting a `?` may cause a crash.
```dart
final json = jsonDecode(response.data);
final milestoneCreator = json?['milestone']?['creator']?['login'] as String?;
print(milestoneCreator); // octocat  
```

Before Dart 2.12 you had to write even more code to be save!
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

With `deep_pick` parsing becomes short again while being type-safe
```dart
final milestoneCreator = pick(json, 'milestone', 'creator', 'login').asStringOrNull();
print(milestoneCreator); // octocat  
```

`deep_pick` is especially useful when the JSON response in deeply nested and only a few values needs to be parsed.

### Make values required and non-nullable
`deep_pick` is perfect when working with Firestore `DocumentSnapshot`. 
Usually it's too much effort to map it to an actual Object (because you don't need all fields).
Instead, parse the values in place while staying type-safe. 

Use `.required()` when your 100% confident the value is never `null` and **always** exists. 
The return type then becomes non-nullable (`String` instead of `String?`).
When the `data` doesn't contain the `full_name` field (against your assumption) it would crash throwing a `PickException`.

```dart
final DocumentSnapshot userDoc = 
    await FirebaseFirestore.instance.collection('users').doc(userId).get();
final data = userDoc.data();
final String fullName = pick(data, 'full_name').required().asString();
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
