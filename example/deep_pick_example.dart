// ignore_for_file: avoid_print, always_require_non_null_named_parameters, omit_local_variable_types, avoid_dynamic_calls, unreachable_from_main
import 'dart:convert';

import 'package:deep_pick/deep_pick.dart';
import 'package:http/http.dart' as http;

const String rawJson = '''
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
''';

/// The same shoes in a JSON object, with the brand as key
const String rawJsonByBrand = '''
{
  "nike": { 
    "id": "421",
    "name": "Nike Zoom Fly 3",
    "manufacturer": "nike",
    "tags": ["nike", "JustDoIt"]
  },
  "adidas": { 
    "id": "532",
    "name": "adidas Ultraboost",
    "manufacturer": "adidas",
    "tags": ["adidas", "ImpossibleIsNothing"],
    "price": null
  }
}
''';

Future<void> main() async {
  final firstTag3 =
      pickFromJson(rawJson, 'shoes', 1, 'tags', 0).asStringOrThrow();
  print(firstTag3);

  final json = jsonDecode(rawJson);
  // pick a value deep down the json structure or crash
  final firstTag = pick(json, 'shoes', 1, 'tags', 0).asStringOrThrow();
  print(firstTag); // adidas

  // The unsafe vanilla way
  final firstTag2 = json['shoes']?[1]?['tags'][0] as String?;
  print(firstTag2); // adidas

  // fallback to null if it couldn't be found
  final manufacturer = pick(json, 'shoes', 0, 'manufacturer').asStringOrNull();
  print(manufacturer); // null

  // you decide which type you want
  final id = pick(json, 'shoes', 0, 'id');
  print(id.asIntOrNull()); // 421
  print(id.asDoubleOrNull()); // 421.0
  print(id.asStringOrNull()); // "421"

  // pick lists
  final tags = pick(json, 'shoes', 0, 'tags')
      .asListOrEmpty((it) => it.asStringOrThrow());
  print(tags); // [nike, JustDoIt]

  // pick maps
  final shoe = pick(json, 'shoes', 0).required().asMapOrThrow();
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

  // map the values of a JSON object to dart objects
  final Map<String, Shoe> shoesByBrand = pickFromJson(rawJsonByBrand)
      .asJsonObjectOrEmpty()
      .mapValues((p) => Shoe.fromPick(p));
  print(shoesByBrand);
  // {
  //   nike: Shoe{id: 421, name: "Nike Zoom Fly 3", price: "Not for sale", tags: [nike, JustDoIt]},
  //   adidas: Shoe{id: 532, name: "adidas Ultraboost", price: "Price available soon", tags: [adidas, ImpossibleIsNothing]}
  // }

  // convert the keys as well, a key is a pick too
  final Map<Uri, Shoe> shoesByWebsite = pickFromJson(rawJsonByBrand)
      .asJsonObjectOrEmpty()
      .mapKeys((key) => Uri.parse('https://${key.asStringOrThrow()}.com'))
      .mapValues((p) => Shoe.fromPick(p));
  print(shoesByWebsite.keys); // (https://nike.com, https://adidas.com)

  // Use the Context API to pass contextual information down to parsing
  // without adding new arguments
  final newShoes = pick(json, 'shoes')
      .withContext('newApi', true)
      .asListOrEmpty((p) => Shoe.fromPick(p));
  print(newShoes);

  // access value out of range
  final puma = pick(json, 'shoes', 1);
  print(puma.isAbsent); // true;
  print(puma.value); // null

  // Load data from an API
  final latest = await getLatestVersion();
  print(latest.version);

  // pick values with a dynamic selector
  pickDeep(json, 'some.key.inside.the.object'.split('.')).asStringOrNull();
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
      id: pick('id').asStringOrThrow(),
      name: pick('name').asStringOrThrow(),
      // manufacturer is a required field in the new API
      manufacturer: newApi
          ? pick('manufacturer').asStringOrThrow()
          : pick('manufacturer').asStringOrNull(),
      tags: pick('tags').asListOrEmpty((it) => it.asStringOrThrow()),
      price: () {
        // when server doesn't send the price field the shoe is not available
        if (pricePick.isAbsent) return 'Not for sale';
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

Future<PackageVersion> getLatestVersion() async {
  final response =
      await http.get(Uri.parse('https://pub.dev/api/packages/deep_pick'));
  final json = jsonDecode(response.body);

  // Parse individual fields
  final String? name = pick(json, 'name').asStringOrNull();
  final String version = pick(json, 'latest', 'version').asStringOrThrow();
  final String? sdk =
      pick(json, 'latest', 'pubspec', 'environment', 'sdk').asStringOrNull();
  print('name $name, version $version, sdk: "$sdk"');

  // Parse the full object
  final PackageVersion latest =
      PackageVersion.fromPick(pick(json, 'latest').required());

  // Parse lists
  final List<PackageVersion> versions = pick(json, 'versions')
      .asListOrEmpty((pick) => PackageVersion.fromPick(pick));
  print(versions.length);

  // Parse the values of a JSON object
  final Map<String, String> devDependencies =
      pick(json, 'latest', 'pubspec', 'dev_dependencies')
          .asJsonObjectOrEmpty()
          .mapValues((pick) => pick.asStringOrThrow());
  print(devDependencies);
  // {http: >=0.13.0 <2.0.0, lint: >=1.5.1 <3.0.0, test: ^1.16.0}

  return latest;
}

class PackageVersion {
  const PackageVersion({
    required this.version,
    required this.archiveUrl,
    required this.published,
    this.description,
  });

  final String version;
  final String archiveUrl;
  final DateTime published;
  final String? description;

  factory PackageVersion.fromPick(RequiredPick pick) {
    return PackageVersion(
      version: pick('version').asStringOrThrow(),
      archiveUrl: pick('archive_url').asStringOrThrow(),
      published: pick('published').asDateTimeOrThrow(),
      description: pick('pubspec', 'description').asStringOrNull(),
    );
  }
}
