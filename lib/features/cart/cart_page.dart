import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format_price.dart';
import '../../shared/widgets/garment_preview.dart';
import 'cart_controller.dart';

class CartHeading extends ConsumerWidget {
  const CartHeading({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(
      cartProvider.select(
        (cart) =>
            cart.lines.values.fold(0, (count, line) => count + line.quantity),
      ),
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
    final cart = ref.watch(cartProvider);
    if (cart.lines.isEmpty) return _EmptyCart(onBrowse: onBrowse);

    final controller = ref.read(cartProvider.notifier);
    return Column(
      children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                primary: false,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  for (final entry in cart.lines.entries)
                    _CartLineCard(
                      key: ValueKey(entry.key),
                      line: entry.value,
                      onQuantity: (quantity) =>
                          controller.setQuantity(entry.key, quantity),
                      onRemove: () => controller.remove(entry.key),
                    ),
                ],
              ),
            ),
          ),
        ),
        _SubtotalStrip(subtotalCentavos: cart.subtotalCentavos),
      ],
    );
  }
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
  final ValueChanged<int> onQuantity;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final label = '${line.product.name}, size ${line.variant.size}';

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
                    assetPath: line.product.imageAsset,
                    artHeight: 64,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.product.name,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text('Size ${line.variant.size}'),
                      if (line.quantity > 1)
                        Text('${line.variant.priceLabel} each'),
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
                        onPressed: line.quantity == 1
                            ? null
                            : () => onQuantity(line.quantity - 1),
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
                        onPressed: () => onQuantity(line.quantity + 1),
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
