import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/catalog_provider.dart';
import '../catalog/product.dart';
import 'cart_database.dart';
import 'cart_repository.dart';

export 'cart_repository.dart' show CartKey;

class CartLine {
  const CartLine(this.product, this.variant, this.quantity);

  final Product? product;
  final ProductVariant? variant;
  final int quantity;

  int get totalCentavos => totalFor(variant?.priceCentavos ?? 0, quantity);

  static int totalFor(int unitPriceCentavos, int quantity) =>
      unitPriceCentavos * quantity;
}

class Cart {
  const Cart._(this.lines, {this.writeFailed = false});

  final Map<CartKey, CartLine> lines;
  final bool writeFailed;

  bool get canCheckout =>
      !writeFailed &&
      lines.isNotEmpty &&
      lines.values.every((line) => line.variant != null);

  int get itemCount => lines.values.fold(
    0,
    (count, line) => count + (line.variant == null ? 0 : line.quantity),
  );

  int get subtotalCentavos =>
      lines.values.fold(0, (subtotal, line) => subtotal + line.totalCentavos);
}

class CartCatalogLoadException implements Exception {
  const CartCatalogLoadException(this.cause);

  final Object cause;
}

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final repository = CartRepository(openCartDatabase);
  ref.onDispose(() => unawaited(repository.close()));
  return repository;
});

final cartProvider = AsyncNotifierProvider<CartController, Cart>(
  CartController.new,
  retry: (retryCount, error) => null,
);

class CartController extends AsyncNotifier<Cart> {
  final _edits = Queue<_CartEdit>();
  bool _writing = false;
  late Map<String, Product> _products;

  bool get hasPendingEdits => _writing || _edits.isNotEmpty;

  @override
  Future<Cart> build() async {
    final repository = ref.read(cartRepositoryProvider);
    final List<Product> products;
    try {
      products = await ref.read(catalogProvider.future);
    } catch (error) {
      throw CartCatalogLoadException(error);
    }

    final rows = await repository.read();
    _products = {for (final product in products) product.id: product};
    return _resolve(rows);
  }

  void retryLoad() {
    if (state.error is CartCatalogLoadException) {
      ref.invalidate(catalogProvider);
    }
    ref.invalidateSelf();
  }

  void retryWrite() {
    if (state.asData?.value.writeFailed == true) unawaited(_drain());
  }

  Future<bool> add(String productId, String size) {
    final key = (productId: productId, size: size);
    return _enqueue((repository, cart) async {
      if (_products[productId]?.variantForSize(size) == null) return null;
      return repository.add(key);
    });
  }

  Future<bool> setQuantity(CartKey key, int quantity) =>
      _enqueue((repository, cart) async {
        if (quantity < 1 || cart.lines[key]?.variant == null) return null;
        return repository.setQuantity(key, quantity);
      });

  Future<bool> adjustQuantity(CartKey key, int delta) =>
      _enqueue((repository, cart) async {
        final line = cart.lines[key];
        if (line == null || line.variant == null || line.quantity + delta < 1) {
          return null;
        }
        return repository.adjustQuantity(key, delta);
      });

  Future<bool> remove(CartKey key) => _enqueue((repository, cart) async {
    if (!cart.lines.containsKey(key)) return null;
    return repository.remove(key);
  });

  Cart _resolve(CartRows rows) => Cart._(
    Map.unmodifiable({
      for (final entry in rows.entries)
        entry.key: CartLine(
          _products[entry.key.productId],
          _products[entry.key.productId]?.variantForSize(entry.key.size),
          entry.value,
        ),
    }),
  );

  Future<bool> _enqueue(
    Future<CartRows?> Function(CartRepository, Cart) write,
  ) {
    final cart = state.asData?.value;
    if (cart == null || cart.writeFailed) return Future.value(false);

    final edit = _CartEdit(write);
    _edits.addLast(edit);
    unawaited(_drain());
    return edit.result.future;
  }

  Future<void> _drain() async {
    if (_writing) return;
    _writing = true;
    try {
      final repository = ref.read(cartRepositoryProvider);
      while (_edits.isNotEmpty && ref.mounted) {
        final edit = _edits.first;
        final cart = state.requireValue;
        final CartRows? rows;
        try {
          rows = await edit.write(repository, cart);
        } catch (_) {
          // Keep the failed edit at the head so Retry runs that edit once.
          if (ref.mounted) {
            state = AsyncData(Cart._(cart.lines, writeFailed: true));
          }
          return;
        }

        _edits.removeFirst();
        edit.result.complete(rows != null);
        if (!ref.mounted) return;
        if (rows != null) {
          state = AsyncData(_resolve(rows));
        } else if (cart.writeFailed) {
          state = AsyncData(Cart._(cart.lines));
        }
      }
    } finally {
      _writing = false;
    }
  }
}

class _CartEdit {
  _CartEdit(this.write);

  final Future<CartRows?> Function(CartRepository, Cart) write;
  final result = Completer<bool>();
}
