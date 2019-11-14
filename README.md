# deep_pick

[![Pub](https://img.shields.io/pub/v/deep_pick.svg)](https://pub.dartlang.org/packages/deep_pick)

A library to access deep nested values inside of dart data structures (nested Lists and Maps).
 - json parsed with `dart:convert` `dynamic jsonDecode(String source)`
 - `DocumentSnapshot`s in Firebase Firestore

## Example


```dart
import 'dart:convert';

import 'package:deep_pick/deep_pick.dart';

void main() {
  final json = jsonDecode('''
{
  "shoes": [
     { 
       "id": "421",
       "name": "Nike Zoom Fly 3",
       "tags": ["nike", "JustDoIt"]
     },
     { 
       "id": "532",
       "name": "adidas Ultraboost",
       "manufacturer": "adidas",
       "tags": ["adidas", "ImpossibleIsNothing"]
     }
  ]
}
''');
  // pick a value deep down the json structure
  final firstTag = pick(json, 'shoes', 1, 'tags', 0).asStringOrNull();
  print(firstTag); // adidas

  // fallback to null if it couldn't be found
  final manufacturer = pick(json, 'shoes', 0, 'manufacturer').asStringOrNull();
  print(manufacturer); // null

  // use required() to crash if a object doesn't exist
  final name = pick(json, 'shoes', 0, 'name').required().asString();
  print(name); // Nike Zoom Fly 3

  // you decide which type you want
  final id = pick(json, 'shoes', 0, 'id');
  print(id.asIntOrNull()); // 421
  print(id.asDoubleOrNull()); // 421.0
  print(id.asStringOrNull()); // "421"

  // pick lists
  final tags = pick(json, 'shoes', 0, 'tags').asListOrEmpty<String>();
  print(tags); // [nike, JustDoIt]

  // pick maps
  final shoe = pick(json, 'shoes', 0).required().asMap();
  print(shoe); // {id: 421, name: Nike Zoom Fly 3, tags: [nike, JustDoIt]}

  // easily pick and map objects to dart objects
  final firstShoe = pick(json, 'shoes', 0).letOrNull((p) => Shoe.fromPick(p));
  print(firstShoe);
  // Shoe{id: 421, name: Nike Zoom Fly 3, tags: [nike, JustDoIt]}

  // falls back to null when the value couldn't be picked
  final thirdShoe = pick(json, 'shoes', 2).letOrNull((p) => Shoe.fromPick(p));
  print(thirdShoe); // null

  // map list of picks to dart objects
  final shoes =
      pick(json, 'shoes').asListOrEmpty((p) => Shoe.fromPick(p.required()));
  print(shoes);
  // [
  //   Shoe{id: 421, name: Nike Zoom Fly 3, tags: [nike, JustDoIt]},
  //   Shoe{id: 532, name: adidas Ultraboost, tags: [adidas, ImpossibleIsNothing]}
  // ]
}
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
