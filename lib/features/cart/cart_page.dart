import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format_price.dart';
import '../../shared/widgets/garment_preview.dart';
import 'cart_controller.dart';
import 'cart_issue.dart';

class CartHeading extends ConsumerWidget {
  const CartHeading({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(
      cartProvider.select((cart) => cart.asData?.value.itemCount ?? 0),
    );
    final theme = Theme.of(context);

    return Wrap(
      spacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('Your cart'),
        if (items > 0)
          Text(
            items == 1 ? '1 item' : '$items items',
            style: theme.textTheme.bodyMedium,
          ),
      ],
    );
  }
}

class CartPage extends ConsumerWidget {
  const CartPage({super.key, required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final controller = ref.read(cartProvider.notifier);
    if (cartState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Loading cart'),
      );
    }
    final cart = cartState.asData?.value;
    final issue = CartIssue(cart: cartState, controller: controller);
    if (cart == null) return Center(child: SingleChildScrollView(child: issue));

    return Column(
      children: [
        issue,
        Expanded(
          child: cart.lines.isEmpty
              ? _EmptyCart(onBrowse: onBrowse)
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ListView(
                      primary: false,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        for (final entry in cart.lines.entries)
                          if (entry.value.variant == null)
                            _UnavailableLine(
                              key: ValueKey(entry.key),
                              name:
                                  entry.value.product?.name ??
                                  entry.key.productId,
                              size: entry.key.size,
                              quantity: entry.value.quantity,
                              onRemove: cart.writeFailed
                                  ? null
                                  : () => controller.remove(entry.key),
                            )
                          else
                            _CartLineCard(
                              key: ValueKey(entry.key),
                              line: entry.value,
                              onQuantity: cart.writeFailed
                                  ? null
                                  : (delta) => controller.adjustQuantity(
                                      entry.key,
                                      delta,
                                    ),
                              onRemove: cart.writeFailed
                                  ? null
                                  : () => controller.remove(entry.key),
                            ),
                      ],
                    ),
                  ),
                ),
        ),
        if (cart.lines.isNotEmpty)
          _SubtotalStrip(subtotalCentavos: cart.subtotalCentavos),
      ],
    );
  }
}

class _UnavailableLine extends StatelessWidget {
  const _UnavailableLine({
    super.key,
    required this.name,
    required this.size,
    required this.quantity,
    required this.onRemove,
  });

  final String name;
  final String size;
  final int quantity;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: Theme.of(context).textTheme.titleMedium),
          Text('Size $size · Quantity $quantity'),
          const Text('No longer available'),
          TextButton(onPressed: onRemove, child: const Text('Remove')),
        ],
      ),
    ),
  );
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ExcludeSemantics(
              child: SizedBox(
                width: 208,
                child: GarmentPreview(
                  assetPath: 'assets/products/black-graphic-front.png',
                  artHeight: 132,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a shirt and size to start your order.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onBrowse,
              child: const Text('Browse shirts'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubtotalStrip extends StatelessWidget {
  const _SubtotalStrip({required this.subtotalCentavos});

  final int subtotalCentavos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              spacing: 12,
              overflowSpacing: 4,
              overflowAlignment: OverflowBarAlignment.end,
              children: [
                Text('Subtotal', style: theme.textTheme.titleMedium),
                Text(
                  formatPesos(subtotalCentavos),
                  textAlign: TextAlign.end,
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartLineCard extends StatelessWidget {
  const _CartLineCard({
    super.key,
    required this.line,
    required this.onQuantity,
    required this.onRemove,
  });

  final CartLine line;
  final ValueChanged<int>? onQuantity;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final product = line.product!;
    final variant = line.variant!;
    final label = '${product.name}, size ${variant.size}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colors.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 88,
                  child: GarmentPreview(
                    assetPath: product.imageAsset,
                    artHeight: 64,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Size ${variant.size}'),
                      if (line.quantity > 1) Text('${variant.priceLabel} each'),
                      const SizedBox(height: 4),
                      Text(
                        formatPesos(line.totalCentavos),
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.outlineVariant),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Decrease quantity for $label',
                        onPressed: line.quantity == 1 || onQuantity == null
                            ? null
                            : () => onQuantity!(-1),
                        icon: const Icon(Icons.remove, size: 18),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 24),
                        child: Text(
                          '${line.quantity}',
                          textAlign: TextAlign.center,
                          semanticsLabel: 'Quantity ${line.quantity}',
                        ),
                      ),
                      IconButton(
                        tooltip: 'Increase quantity for $label',
                        onPressed: onQuantity == null
                            ? null
                            : () => onQuantity!(1),
                        icon: const Icon(Icons.add, size: 18),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onRemove,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: colors.onSurfaceVariant,
                  ),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
