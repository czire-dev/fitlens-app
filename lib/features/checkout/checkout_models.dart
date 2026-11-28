import 'dart:math';

import 'package:flutter/foundation.dart';

import '../cart/cart_controller.dart';
import '../catalog/product.dart';

enum DeliveryField {
  name('Full name', 'Enter your name.'),
  mobile(
    'Mobile number',
    'Enter a mobile number in 09XXXXXXXXX or +639XXXXXXXXX format.',
  ),
  address('House, street, and barangay', 'Enter your delivery address.'),
  city('City or municipality', 'Enter a city or municipality name.'),
  postalCode('Postal code', 'Enter a four-digit postal code.');

  const DeliveryField(this.label, this.error);

  final String label;
  final String error;

  String clean(String value) => this == mobile
      ? value.trim().replaceAll(RegExp(r'[\s-]+'), '')
      : value.trim();

  String? validate(String? input) {
    final value = clean(input ?? '');
    final valid = switch (this) {
      mobile => RegExp(r'^(?:09|\+639)[0-9]{9}$').hasMatch(value),
      postalCode => RegExp(r'^[0-9]{4}$').hasMatch(value),
      city => RegExp(r'\p{L}', unicode: true).hasMatch(value),
      _ => value.isNotEmpty,
    };
    return valid ? null : error;
  }
}

typedef DeliveryDetails = ({
  String name,
  String mobile,
  String address,
  String city,
  String postalCode,
});

DeliveryDetails deliveryFromDraft(Map<DeliveryField, String> draft) => (
  name: DeliveryField.name.clean(draft[DeliveryField.name] ?? ''),
  mobile: DeliveryField.mobile.clean(draft[DeliveryField.mobile] ?? ''),
  address: DeliveryField.address.clean(draft[DeliveryField.address] ?? ''),
  city: DeliveryField.city.clean(draft[DeliveryField.city] ?? ''),
  postalCode: DeliveryField.postalCode.clean(
    draft[DeliveryField.postalCode] ?? '',
  ),
);

typedef OrderItem = ({
  String productId,
  String productName,
  String size,
  int quantity,
  int unitPriceCentavos,
});

class CheckoutReview {
  CheckoutReview(this.reference, Cart cart, this.delivery)
    : subtotalCentavos = cart.subtotalCentavos,
      _reviewedLines = _items(cart);

  final String reference;
  final DeliveryDetails delivery;
  Iterable<OrderItem> get items => _reviewedLines.values;
  final int subtotalCentavos;
  final Map<CartKey, OrderItem> _reviewedLines;
  static const deliveryCentavos = 0;
  int get totalCentavos => subtotalCentavos + deliveryCentavos;

  bool matchesCart(Cart? cart) =>
      cart != null &&
      cart.canCheckout &&
      mapEquals(_reviewedLines, _items(cart));

  bool matchesCatalog(List<Product>? products) {
    if (products == null) return false;
    final byId = {for (final product in products) product.id: product};
    return items.every((item) {
      final product = byId[item.productId];
      return product?.name == item.productName &&
          product?.variantForSize(item.size)?.priceCentavos ==
              item.unitPriceCentavos;
    });
  }

  static Map<CartKey, OrderItem> _items(Cart cart) => {
    for (final entry in cart.lines.entries)
      if (entry.value.variant case final variant?)
        entry.key: (
          productId: entry.key.productId,
          productName: entry.value.product!.name,
          size: entry.key.size,
          quantity: entry.value.quantity,
          unitPriceCentavos: variant.priceCentavos,
        ),
  };
}

String newOrderReference() {
  final random = Random.secure();
  final bytes = List.generate(12, (_) => random.nextInt(256));
  return 'FL-${bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join().toUpperCase()}';
}

class SavedOrder {
  const SavedOrder({
    required this.reference,
    required this.createdAt,
    required this.delivery,
    required this.subtotalCentavos,
    required this.deliveryCentavos,
    required this.totalCentavos,
    required this.items,
  });

  final String reference;
  final DateTime createdAt;
  final DeliveryDetails delivery;
  final int subtotalCentavos;
  final int deliveryCentavos;
  final int totalCentavos;
  final List<OrderItem> items;
}

typedef OrderSummary = ({
  String reference,
  DateTime createdAt,
  int totalCentavos,
});
