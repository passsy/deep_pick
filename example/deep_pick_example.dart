// ignore_for_file: avoid_print, always_require_non_null_named_parameters
import 'dart:convert';

import 'package:deep_pick/deep_pick.dart';

void main() {
  final json = jsonDecode('''
{
  "shoes": [
     { 
       "id": "421",
       "name": "Nike Zoom Fly 3",
       "manufacturer": "nike",
       "tags": ["nike", "JustDoIt"]
     },
     { 
       "id": "532",
       "name": "adidas Ultraboost",
       "manufacturer": "adidas",
       "tags": ["adidas", "ImpossibleIsNothing"],
       "price": null
     }
  ]
}
''');


  // final milestoneCreator = json?['milestone']?['creator']?['login'] as String;
  final milestoneCreator = pick(json, 'milestone', 'creator', 'login').asStringOrThrow();
  print(milestoneCreator);

  // pick a value deep down the json structure
  final firstTag = pick(json, 'shoes', 1, 'tags', 0).asStringOrThrow();
  print(firstTag); // adidas


  final firstTag2 = json['shoes']?[23]?['id'] as String?;
  print(firstTag2); // adidas


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
  final tags =
      pick(json, 'shoes', 0, 'tags').asListOrEmpty((it) => it.asString());
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
  final shoes = pick(json, 'shoes').asListOrEmpty((p) => Shoe.fromPick(p));
  print(shoes);
  // [
  //   Shoe{id: 421, name: Nike Zoom Fly 3, tags: [nike, JustDoIt]},
  //   Shoe{id: 532, name: adidas Ultraboost, tags: [adidas, ImpossibleIsNothing]}
  // ]

  // Use the Context API to pass contextual information down to parsing
  // without adding new arguments
  final newShoes = pick(json, 'shoes')
      .withContext('newApi', true)
      .asListOrEmpty((p) => Shoe.fromPick(p));
  print(newShoes);

  // access value out of range
  final puma = pick(
    json,
    'shoes',
    1,
  );
  print(puma.isAbsent()); // true;
  print(puma.value); // null
}

/// A data class representing a shoe model
///
/// PODO - plain old dart object
class Shoe {
  const Shoe({
    required this.id,
    required this.name,
    this.manufacturer,
    required this.tags,
    required this.price,
  });

  factory Shoe.fromPick(RequiredPick pick) {
    // read context API
    final newApi = pick.fromContext('newApi').asBoolOrFalse();
    final pricePick = pick('price');
    return Shoe(
      id: pick('id').required().asString(),
      name: pick('name').required().asString(),
      // manufacturer is a required field in the new API
      manufacturer: newApi
          ? pick('manufacturer').required().asString()
          : pick('manufacturer').asStringOrNull(),
      tags: pick('tags').asListOrEmpty((it) => it.asString()),
      price: () {
        // when server doesn't send the price field the shoe is not available
        if (pricePick.isAbsent()) return 'Not for sale';
        return pricePick.asStringOrNull() ?? 'Price available soon';
      }(),
    );
  }

  /// never null
  final String id;

  /// never null
  final String name;

  /// optional
  final String? manufacturer;

  /// never null, falls back to empty list
  final List<String> tags;

  /// what to display as price
  final String price;

  @override
  String toString() {
    return 'Shoe{id: $id, name: "$name", price: "$price", tags: $tags}';
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
