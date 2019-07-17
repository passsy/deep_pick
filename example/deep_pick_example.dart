import 'dart:convert';

import 'package:deep_pick/deep_pick.dart';

void main() {
final json = jsonDecode('''
    {
      "shoes": [
         { 
           "id": "421",
           "name": "Nike Zoom Fly 3"
         }
      ]
    }
    ''');
final name = parseJsonToString(json, 'shoes', 0, 'name');
print(name); // Nike Zoom Fly 3
final id = parseJsonToInt(json, 'shoes', 0, 'id');
print(id); // 421
}
