import 'package:fitlens/features/cart/cart_controller.dart';
import 'package:fitlens/features/catalog/catalog_provider.dart';
import 'package:fitlens/features/catalog/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_cart_repository.dart';

void main() {
  late ProviderContainer container;
  late CartController controller;
  const medium = (productId: 'black', size: 'M');
  const large = (productId: 'black', size: 'L');
  late TestCartRepository repository;
  Cart cart() => container.read(cartProvider).requireValue;

  setUp(() async {
    repository = TestCartRepository();
    container = ProviderContainer(
      overrides: [
        cartRepositoryProvider.overrideWithValue(repository),
        catalogProvider.overrideWith(
          (ref) async => [_shirt('black'), _shirt('slate')],
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(cartProvider.future);
    controller = container.read(cartProvider.notifier);
  });

  test(
    'Identical variants merge and distinct variants stay separate',
    () async {
      expect(
        await Future.wait([
          controller.add('black', 'M'),
          controller.add('black', 'M'),
          controller.add('black', 'L'),
        ]),
        [true, true, true],
      );
      expect(cart().lines.length, 2);
      expect(cart().lines[medium]?.quantity, 2);
      expect(cart().lines[medium]?.totalCentavos, 179800);
      expect(cart().lines[large]?.quantity, 1);
      expect(cart().subtotalCentavos, 274700);

      expect(await controller.setQuantity(medium, 1), isTrue);
      expect(cart().subtotalCentavos, 184800);

      expect(await controller.add('slate', 'M'), isTrue);
      expect(cart().lines.length, 3);
      expect(cart().lines[(productId: 'slate', size: 'M')]?.quantity, 1);
    },
  );

  test('Invalid variants and quantities preserve cart state', () async {
    await controller.add('black', 'M');
    final original = cart();
    expect(await controller.add('black', 'XS'), isFalse);
    expect(await controller.add('missing', 'M'), isFalse);
    expect(await controller.setQuantity(medium, 0), isFalse);
    expect(await controller.setQuantity(medium, -2), isFalse);
    expect(await controller.setQuantity(large, 1), isFalse);
    expect(cart(), same(original));
  });

  test('Remove deletes only the requested line and updates subtotal', () async {
    await controller.add('black', 'M');
    await controller.add('black', 'L');
    await controller.remove(medium);
    expect(cart().lines.keys, [large]);
    expect(cart().subtotalCentavos, 94900);
    await controller.remove(large);
    expect(cart().lines, isEmpty);
    expect(cart().subtotalCentavos, 0);
  });

  test(
    'Retry adds exactly one unit and resumes queued edits in order',
    () async {
      await controller.add('black', 'M');
      repository.failNextWrite = true;
      final failed = controller.add('black', 'M');
      final queued = controller.add('black', 'L');
      await Future<void>.delayed(Duration.zero);
      expect(cart().writeFailed, isTrue);
      expect(cart().lines[medium]?.quantity, 1);
      expect(cart().subtotalCentavos, 89900);

      controller.retryWrite();
      controller.retryWrite();
      expect(await Future.wait([failed, queued]), [true, true]);
      expect(cart().lines[medium]?.quantity, 2);
      expect(cart().subtotalCentavos, 274700);
    },
  );
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
