import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/catalog_provider.dart';
import '../catalog/product.dart';

typedef CartKey = ({String productId, String size});

class CartLine {
  const CartLine(this.product, this.variant, this.quantity);

  final Product product;
  final ProductVariant variant;
  final int quantity;

  int get totalCentavos => variant.priceCentavos * quantity;
}

class Cart {
  const Cart._(this.lines);

  final Map<CartKey, CartLine> lines;

  int get subtotalCentavos =>
      lines.values.fold(0, (subtotal, line) => subtotal + line.totalCentavos);
}

final cartProvider = NotifierProvider<CartController, Cart>(CartController.new);

class CartController extends Notifier<Cart> {
  @override
  Cart build() => const Cart._({});

  bool add(String productId, String size) {
    final products = ref.read(catalogProvider).asData?.value;
    final product = products?.where((item) => item.id == productId).firstOrNull;
    final variant = product?.variantForSize(size);
    if (product == null || variant == null) return false;

    final key = (productId: productId, size: size);
    final quantity = (state.lines[key]?.quantity ?? 0) + 1;
    state = Cart._(
      Map.unmodifiable({
        ...state.lines,
        key: CartLine(product, variant, quantity),
      }),
    );
    return true;
  }

  bool setQuantity(CartKey key, int quantity) {
    final line = state.lines[key];
    if (quantity < 1 || line == null) return false;

    state = Cart._(
      Map.unmodifiable({
        ...state.lines,
        key: CartLine(line.product, line.variant, quantity),
      }),
    );
    return true;
  }

  void remove(CartKey key) {
    final lines = {...state.lines}..remove(key);
    state = Cart._(Map.unmodifiable(lines));
  }
}
