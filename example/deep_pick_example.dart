// ignore_for_file: avoid_print
import 'dart:convert';

import 'package:deep_pick/deep_pick.dart';
import 'package:meta/meta.dart';

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
  final oneShoe = pick(json, 'shoes', 0).letOrNull((p) => Shoe.fromPick(p));
  print(oneShoe);
  // Shoe{id: 421, name: Nike Zoom Fly 3, tags: [nike, JustDoIt]}

  // map list of picks to dart objects
  final shoes =
      pick(json, 'shoes').asListOrEmpty((p) => Shoe.fromPick(p.required()));
  print(shoes);
  // [
  //   Shoe{id: 421, name: Nike Zoom Fly 3, tags: [nike, JustDoIt]},
  //   Shoe{id: 532, name: adidas Ultraboost, tags: [adidas, ImpossibleIsNothing]}
  // ]
}

/// A data class representing a shoe model
///
/// PODO - plain old dart object
class Shoe {
  const Shoe({
    @required this.id,
    @required this.name,
    @required this.manufacturer,
    @required this.tags,
  })  : assert(id != null),
        assert(name != null),
        assert(tags != null);

  factory Shoe.fromPick(RequiredPick pick) {
    return Shoe(
      id: pick('id').asString(),
      name: pick('name').asString(),
      manufacturer: pick('manufacturer').asStringOrNull(),
      tags: pick('tags').asListOrEmpty(),
    );
  }

  /// never null
  final String id;

  /// never null
  final String name;

  /// optional
  final String manufacturer;

  /// never null, falls back to empty list
  final List<String> tags;

  @override
  String toString() {
    return 'Shoe{id: $id, name: $name, tags: $tags}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Shoe &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          tags == other.tags;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ tags.hashCode;
}
