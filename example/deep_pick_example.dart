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
