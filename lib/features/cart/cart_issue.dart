import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cart_controller.dart';

class CartIssue extends StatelessWidget {
  const CartIssue({super.key, required this.cart, required this.controller});

  final AsyncValue<Cart> cart;
  final CartController controller;

  @override
  Widget build(BuildContext context) {
    final error = cart.error;
    final writeFailed = cart.asData?.value.writeFailed == true;
    if (error == null && !writeFailed) return const SizedBox.shrink();

    final text = writeFailed
        ? 'Could not save the cart change.'
        : error is CartCatalogLoadException
        ? 'Could not load the catalog for your cart.'
        : 'Could not load your saved cart.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(text),
          TextButton(
            onPressed: writeFailed
                ? controller.retryWrite
                : controller.retryLoad,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
