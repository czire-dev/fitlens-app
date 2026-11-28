import 'dart:io';

import 'package:fitlens/features/cart/cart_controller.dart';
import 'package:fitlens/features/cart/cart_database.dart';
import 'package:fitlens/features/cart/cart_repository.dart';
import 'package:fitlens/features/catalog/catalog_provider.dart';
import 'package:fitlens/features/catalog/product.dart';
import 'package:fitlens/features/checkout/checkout_models.dart';
import 'package:fitlens/features/checkout/order_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _medium = (productId: 'shirt', size: 'M');
const _large = (productId: 'shirt', size: 'L');
const _delivery = (
  name: 'Mika',
  mobile: '+639171234567',
  address: '12-A Rizal St., Brgy. 6',
  city: 'Quezon City',
  postalCode: '1100',
);

const _product = Product(
  id: 'shirt',
  name: 'Reviewed Shirt',
  description: 'Demo',
  imageAsset: 'shirt.png',
  variants: [
    ProductVariant(size: 'M', priceCentavos: 89900),
    ProductVariant(size: 'L', priceCentavos: 94900),
  ],
);

void main() {
  late String databasePath;
  late CartRepository cart;
  late OrderRepository orders;

  CartRepository openCart() => CartRepository(
    () => databaseFactoryFfi.openDatabase(
      databasePath,
      options: cartDatabaseOptions,
    ),
  );

  setUp(() async {
    sqfliteFfiInit();
    final directory = await Directory.systemTemp.createTemp('fitlens-orders-');
    addTearDown(() => directory.delete(recursive: true));
    databasePath = path.join(directory.path, 'cart.sqlite');
    cart = openCart();
    addTearDown(cart.close);
    orders = OrderRepository(cart.database);
  });

  Future<CheckoutReview> review() async {
    final container = ProviderContainer(
      overrides: [
        cartRepositoryProvider.overrideWithValue(cart),
        catalogProvider.overrideWith((ref) async => [_product]),
      ],
    );
    addTearDown(container.dispose);
    return CheckoutReview(
      'FL-REVIEW',
      await container.read(cartProvider.future),
      _delivery,
    );
  }

  test(
    'Version 1 cart survives migration and the reviewed order survives reopening',
    () async {
      final oldDb = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) => db.execute('''
          CREATE TABLE cart_lines (
            product_id TEXT NOT NULL, size TEXT NOT NULL,
            quantity INTEGER NOT NULL CHECK (typeof(quantity) = 'integer' AND quantity > 0),
            PRIMARY KEY (product_id, size)
          )
        '''),
        ),
      );
      await oldDb.insert('cart_lines', {
        'product_id': 'shirt',
        'size': 'M',
        'quantity': 2,
      });
      await oldDb.insert('cart_lines', {
        'product_id': 'shirt',
        'size': 'L',
        'quantity': 1,
      });
      await oldDb.close();

      expect(await cart.read(), {_medium: 2, _large: 1});
      final approved = await review();
      final saved = await orders.save(approved, reviewIsCurrent: () => true);
      await cart.close();

      final reopened = openCart();
      addTearDown(reopened.close);
      final stored = await OrderRepository(
        reopened.database,
      ).find(saved.reference);
      expect(stored?.createdAt, saved.createdAt);
      expect(stored?.delivery, _delivery);
      expect(stored?.subtotalCentavos, 274700);
      expect(stored?.deliveryCentavos, 0);
      expect(stored?.totalCentavos, 274700);
      expect(stored?.items, approved.items);
      expect(stored?.items.first.productName, 'Reviewed Shirt');
      expect(stored?.items.first.unitPriceCentavos, 89900);
      expect(await reopened.read(), isEmpty);
    },
  );

  test(
    'Failed cart deletion rolls everything back and a committed retry leaves a new cart',
    () async {
      await cart.add(_medium);
      await cart.add(_large);
      final approved = await review();
      final db = await cart.database();
      await db.execute('''
      CREATE TRIGGER fail_checkout AFTER DELETE ON cart_lines
      WHEN OLD.size = 'L'
      BEGIN SELECT RAISE(ABORT, 'forced checkout failure'); END
    ''');
      await expectLater(
        orders.save(approved, reviewIsCurrent: () => true),
        throwsA(isA<DatabaseException>()),
      );
      expect(await db.query('orders'), isEmpty);
      expect(await db.query('order_items'), isEmpty);
      expect(await cart.read(), {_medium: 1, _large: 1});

      await db.execute('DROP TRIGGER fail_checkout');
      final saved = await orders.save(approved, reviewIsCurrent: () => true);
      expect(await cart.read(), isEmpty);
      await cart.add(_medium);
      final repeated = await orders.save(
        approved,
        reviewIsCurrent: () => false,
      );
      expect(repeated.reference, saved.reference);
      expect(repeated.items, saved.items);
      expect(await db.query('orders'), hasLength(1));
      expect(await db.query('order_items'), hasLength(2));
      expect(await cart.read(), {_medium: 1});
    },
  );

  test('Changed catalog or cart prevents an order from being saved', () async {
    await cart.add(_medium);
    final approved = await review();
    expect(approved.matchesCatalog([_product]), isTrue);
    expect(approved.matchesCatalog([]), isFalse);
    const repriced = Product(
      id: 'shirt',
      name: 'Reviewed Shirt',
      description: 'Demo',
      imageAsset: 'shirt.png',
      variants: [ProductVariant(size: 'M', priceCentavos: 90000)],
    );
    await expectLater(
      orders.save(
        approved,
        reviewIsCurrent: () => approved.matchesCatalog([repriced]),
      ),
      throwsA(isA<CheckoutChanged>()),
    );
    await cart.add(_large);
    await expectLater(
      orders.save(approved, reviewIsCurrent: () => true),
      throwsA(isA<CheckoutChanged>()),
    );
    expect(await orders.find(approved.reference), isNull);
    expect(await cart.read(), {_medium: 1, _large: 1});
  });
}
