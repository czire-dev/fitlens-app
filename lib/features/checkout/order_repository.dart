import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../cart/cart_controller.dart';
import '../cart/cart_repository.dart';
import 'checkout_models.dart';

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepository(ref.read(cartRepositoryProvider).database),
);

class CheckoutChanged implements Exception {
  const CheckoutChanged();
}

class OrderRepository {
  const OrderRepository(this._open);

  final Future<Database> Function() _open;

  Future<SavedOrder?> find(String reference) async =>
      _find(await _open(), reference);

  Future<SavedOrder> save(
    CheckoutReview review, {
    required bool Function() reviewIsCurrent,
  }) async {
    final db = await _open();
    return db.transaction((txn) async {
      // A retry after commit returns the original order and leaves any new cart alone.
      final existing = await _find(txn, review.reference);
      if (existing != null) return existing;

      final checkedOut = {
        for (final item in review.items)
          (productId: item.productId, size: item.size): item.quantity,
      };
      final savedCart = await readCartRows(txn);
      if (checkedOut.isEmpty ||
          !mapEquals(savedCart, checkedOut) ||
          !reviewIsCurrent()) {
        throw const CheckoutChanged();
      }

      final createdAt = DateTime.now().toUtc();
      final delivery = review.delivery;
      await txn.insert('orders', {
        'reference': review.reference,
        'created_at': createdAt.toIso8601String(),
        'name': delivery.name,
        'mobile': delivery.mobile,
        'address': delivery.address,
        'city': delivery.city,
        'postal_code': delivery.postalCode,
        'subtotal_centavos': review.subtotalCentavos,
        'delivery_centavos': CheckoutReview.deliveryCentavos,
        'total_centavos': review.totalCentavos,
      });
      for (final item in review.items) {
        await txn.insert('order_items', {
          'order_reference': review.reference,
          'product_id': item.productId,
          'product_name': item.productName,
          'size': item.size,
          'quantity': item.quantity,
          'unit_price_centavos': item.unitPriceCentavos,
        });
      }
      await txn.delete('cart_lines');
      return SavedOrder(
        reference: review.reference,
        createdAt: createdAt,
        delivery: delivery,
        subtotalCentavos: review.subtotalCentavos,
        deliveryCentavos: CheckoutReview.deliveryCentavos,
        totalCentavos: review.totalCentavos,
        items: List.unmodifiable(review.items),
      );
    });
  }

  Future<SavedOrder?> _find(DatabaseExecutor db, String reference) async {
    final order = (await db.query(
      'orders',
      where: 'reference = ?',
      whereArgs: [reference],
    )).singleOrNull;
    if (order == null) return null;
    final lines = await db.query(
      'order_items',
      where: 'order_reference = ?',
      whereArgs: [reference],
      orderBy: 'rowid',
    );
    return SavedOrder(
      reference: reference,
      createdAt: DateTime.parse(order['created_at'] as String),
      delivery: (
        name: order['name'] as String,
        mobile: order['mobile'] as String,
        address: order['address'] as String,
        city: order['city'] as String,
        postalCode: order['postal_code'] as String,
      ),
      subtotalCentavos: order['subtotal_centavos'] as int,
      deliveryCentavos: order['delivery_centavos'] as int,
      totalCentavos: order['total_centavos'] as int,
      items: List.unmodifiable([
        for (final line in lines)
          (
            productId: line['product_id'] as String,
            productName: line['product_name'] as String,
            size: line['size'] as String,
            quantity: line['quantity'] as int,
            unitPriceCentavos: line['unit_price_centavos'] as int,
          ),
      ]),
    );
  }
}
