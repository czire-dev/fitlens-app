import 'dart:convert';

import 'package:flutter/services.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageAsset,
    this.backImageAsset,
    required this.variants,
  });

  final String id;
  final String name;
  final String description;
  final String imageAsset;
  final String? backImageAsset;
  final List<ProductVariant> variants;

  String get catalogPriceLabel {
    final lowest = variants.reduce(
      (a, b) => a.priceCentavos <= b.priceCentavos ? a : b,
    );
    final pricesVary = variants.any(
      (variant) => variant.priceCentavos != lowest.priceCentavos,
    );
    return pricesVary ? 'From ${lowest.priceLabel}' : lowest.priceLabel;
  }

  factory Product.fromJson(Object? json) {
    if (json
        case final Map<Object?, Object?> entry &&
            {
              'id': final String id,
              'name': final String name,
              'description': final String description,
              'imageAsset': final String imageAsset,
              'variants': final List<Object?> entries,
            }
        when id.trim().isNotEmpty &&
            name.trim().isNotEmpty &&
            description.trim().isNotEmpty &&
            imageAsset.trim().isNotEmpty &&
            entries.isNotEmpty) {
      final backImage = entry['backImageAsset'];
      if (entry.containsKey('backImageAsset') &&
          (backImage is! String || backImage.trim().isEmpty)) {
        throw FormatException('Invalid back image for product $id.');
      }

      final variants = entries.map(ProductVariant.fromJson).toList();
      if (variants.map((variant) => variant.size).toSet().length !=
          variants.length) {
        throw FormatException('Duplicate size in product $id.');
      }

      return Product(
        id: id.trim(),
        name: name.trim(),
        description: description.trim(),
        imageAsset: imageAsset.trim(),
        backImageAsset: (backImage as String?)?.trim(),
        variants: List.unmodifiable(variants),
      );
    }
    throw const FormatException('Invalid product entry.');
  }
}

class ProductVariant {
  const ProductVariant({required this.size, required this.priceCentavos});

  final String size;
  final int priceCentavos;

  String get priceLabel {
    final pesos = priceCentavos ~/ 100;
    final centavos = (priceCentavos % 100).toString().padLeft(2, '0');
    return '₱$pesos.$centavos';
  }

  factory ProductVariant.fromJson(Object? json) {
    if (json case {
      'size': final String size,
      'priceCentavos': final int price,
    } when size.trim().isNotEmpty && price > 0) {
      return ProductVariant(
        size: size.trim().toUpperCase(),
        priceCentavos: price,
      );
    }
    throw const FormatException('Invalid product variant.');
  }
}

Future<List<Product>> loadProducts(AssetBundle bundle) async {
  final source = await bundle.loadString('assets/data/products.json');
  final Object? json = jsonDecode(source);
  if (json is! List<Object?>) {
    throw const FormatException('Expected a list of products.');
  }
  final products = json.map(Product.fromJson).toList();
  if (products.map((product) => product.id).toSet().length != products.length) {
    throw const FormatException('Duplicate product ID.');
  }
  return products;
}
