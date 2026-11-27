import 'dart:convert';
import 'dart:ui' as ui;

import 'package:fitlens/features/catalog/product.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'The shipped bundle has five products with decodable local artwork',
    () async {
      final products = await loadProducts(rootBundle);
      expect(products, hasLength(5));
      expect(products.map((product) => product.id).toSet(), hasLength(5));
      expect(
        products.map((product) => product.imageAsset).toSet(),
        hasLength(5),
      );

      final blackTee = products.singleWhere(
        (p) => p.id == 'sevn-black-graphic-tee',
      );
      expect(blackTee.variants.map((variant) => variant.size), ['M', 'L']);
      expect(blackTee.catalogPriceLabel, '₱899.00');
      expect(products.last.catalogPriceLabel, 'From ₱949.50');

      for (final product in products) {
        final paths = [product.imageAsset, ?product.backImageAsset];
        for (final path in paths) {
          final bytes = await rootBundle.load(path);
          final codec = await ui.instantiateImageCodec(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          );
          final frame = await codec.getNextFrame();
          expect(frame.image.width, greaterThan(0), reason: path);
          frame.image.dispose();
          codec.dispose();
        }
      }
    },
  );

  test('The catalog rejects duplicate product IDs', () async {
    await expectLater(
      loadProducts(_JsonBundle([_shirt, _shirt])),
      throwsFormatException,
    );
  });

  test('A product rejects duplicate sizes, including case and whitespace', () {
    expect(
      () => Product.fromJson({
        ..._shirt,
        'variants': [
          {'size': 'M', 'priceCentavos': 89900},
          {'size': ' m ', 'priceCentavos': 99900},
        ],
      }),
      throwsFormatException,
    );
  });

  test('A variant requires a positive integer price', () {
    for (final badPrice in [0, -1, 899.5, '89900', null]) {
      expect(
        () => ProductVariant.fromJson({'size': 'M', 'priceCentavos': badPrice}),
        throwsFormatException,
        reason: '$badPrice',
      );
    }
  });

  test('Required fields and at least one variant are enforced', () {
    for (final field in _shirt.keys) {
      expect(
        () => Product.fromJson({..._shirt}..remove(field)),
        throwsFormatException,
        reason: field,
      );
    }
    expect(
      () => Product.fromJson({..._shirt, 'variants': []}),
      throwsFormatException,
    );
  });
}

const _shirt = {
  'id': 'test-shirt',
  'name': 'Test Shirt',
  'description': 'Sample shirt for validation.',
  'imageAsset': 'assets/products/black-graphic-front.png',
  'variants': [
    {'size': 'M', 'priceCentavos': 89900},
  ],
};

class _JsonBundle extends CachingAssetBundle {
  _JsonBundle(this.json);

  final Object json;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return jsonEncode(json);
  }

  @override
  Future<ByteData> load(String key) {
    throw UnsupportedError('This test bundle only provides JSON.');
  }
}
