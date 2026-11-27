import 'dart:convert';

import 'package:flutter/services.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.pricePhp,
    required this.availableSizes,
  });

  final String id;
  final String name;
  final int pricePhp;
  final List<String> availableSizes;

  String get priceLabel => '₱$pricePhp';

  factory Product.fromJson(Object? json) {
    if (json
        case {
          'id': final String id,
          'name': final String name,
          'pricePhp': final int pricePhp,
          'availableSizes': final List<Object?> sizes,
        }
        when id.trim().isNotEmpty &&
            name.trim().isNotEmpty &&
            pricePhp > 0 &&
            sizes.every((size) => size is String && size.trim().isNotEmpty) &&
            sizes.toSet().length == sizes.length) {
      return Product(
        id: id,
        name: name,
        pricePhp: pricePhp,
        availableSizes: List<String>.unmodifiable(sizes),
      );
    }
    throw const FormatException('Invalid product entry.');
  }
}

Future<List<Product>> loadProducts(AssetBundle bundle) async {
  final source = await bundle.loadString('assets/data/products.json');
  final Object? json = jsonDecode(source);
  if (json is! List<Object?>) {
    throw const FormatException('Expected a list of products.');
  }
  return json.map(Product.fromJson).toList();
}
