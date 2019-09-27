# deep_pick

[![Pub](https://img.shields.io/pub/v/deep_pick.svg)](https://pub.dartlang.org/packages/deep_pick)

A library to access deep nested values inside of dart data structures, like returned from `dynamic jsonDecode(String source)`.

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
       "tags": ["cool", "new"]
     }
  ]
}
''');

  final name = pick(json, 'shoes', 0, 'name').asString();
  print(name); // Nike Zoom Fly 3

  final manufacturer = pick(json, 'shoes', 0, 'manufacturer').asStringOrNull();
  print(manufacturer); // null

  final id = pick(json, 'shoes', 0, 'id').asInt();
  print(id); // 421

  final tags = pick(json, 'shoes', 0, 'tags').asListOrEmpty<String>();
  print(tags); // [cool, new]
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
