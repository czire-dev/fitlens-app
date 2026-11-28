import 'package:fitlens/features/cart/cart_controller.dart';
import 'package:fitlens/features/catalog/catalog_provider.dart';
import 'package:fitlens/features/catalog/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  late CartController controller;
  const medium = (productId: 'black', size: 'M');
  const large = (productId: 'black', size: 'L');
  Cart cart() => container.read(cartProvider);

  setUp(() async {
    container = ProviderContainer(
      overrides: [
        catalogProvider.overrideWith(
          (ref) async => [_shirt('black'), _shirt('slate')],
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(catalogProvider.future);
    controller = container.read(cartProvider.notifier);
  });

  test('Identical variants merge and distinct variants stay separate', () {
    expect(controller.add('black', 'M'), isTrue);
    expect(controller.add('black', 'M'), isTrue);
    expect(controller.add('black', 'L'), isTrue);
    expect(cart().lines.length, 2);
    expect(cart().lines[medium]?.quantity, 2);
    expect(cart().lines[medium]?.totalCentavos, 179800);
    expect(cart().lines[large]?.quantity, 1);
    expect(cart().subtotalCentavos, 274700);

    expect(controller.setQuantity(medium, 1), isTrue);
    expect(cart().subtotalCentavos, 184800);

    expect(controller.add('slate', 'M'), isTrue);
    expect(cart().lines.length, 3);
    expect(cart().lines[(productId: 'slate', size: 'M')]?.quantity, 1);
  });

  test('Invalid variants and quantities preserve cart state', () {
    controller.add('black', 'M');
    final original = cart();
    expect(controller.add('black', 'XS'), isFalse);
    expect(controller.add('missing', 'M'), isFalse);
    expect(controller.setQuantity(medium, 0), isFalse);
    expect(controller.setQuantity(medium, -2), isFalse);
    expect(controller.setQuantity(large, 1), isFalse);
    expect(cart(), same(original));
  });

  test('Remove deletes only the requested line and updates subtotal', () {
    controller.add('black', 'M');
    controller.add('black', 'L');
    controller.remove(medium);
    expect(cart().lines.keys, [large]);
    expect(cart().subtotalCentavos, 94900);
    controller.remove(large);
    expect(cart().lines, isEmpty);
    expect(cart().subtotalCentavos, 0);
  });
}

Product _shirt(String id) => Product(
  id: id,
  name: 'Shirt',
  description: 'Sample',
  imageAsset: 'sample.png',
  variants: const [
    ProductVariant(size: 'M', priceCentavos: 89900),
    ProductVariant(size: 'L', priceCentavos: 94900),
  ],
);
