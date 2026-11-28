import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/garment_preview.dart';
import '../cart/cart_controller.dart';
import '../cart/cart_issue.dart';
import 'product.dart';
import 'size_chart.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  const ProductDetailPage({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  bool _showBack = false;
  String? _selectedSize;

  Future<void> _addToCart(ProductVariant variant) async {
    final added = await ref
        .read(cartProvider.notifier)
        .add(widget.product.id, variant.size);
    if (!mounted || !added) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Size ${variant.size} added to cart.'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cartState = ref.watch(cartProvider);
    final canAdd = cartState.asData?.value.writeFailed == false;
    final selected = product.variantForSize(_selectedSize ?? '');
    final sizes = {
      ...sevnChartSizes,
      ...product.variants.map((variant) => variant.size),
    };
    final backImage = product.backImageAsset;
    final visibleBackImage = _showBack ? backImage : null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GarmentPreview(
                    assetPath: visibleBackImage ?? product.imageAsset,
                    viewLabel: visibleBackImage == null ? 'Front' : 'Back',
                    artHeight: 264,
                  ),
                  if (backImage != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          ChoiceChip(
                            label: const Text('Front'),
                            selected: !_showBack,
                            onSelected: (_) =>
                                setState(() => _showBack = false),
                          ),
                          ChoiceChip(
                            label: const Text('Back'),
                            selected: _showBack,
                            onSelected: (_) => setState(() => _showBack = true),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(product.name, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    selected?.priceLabel ?? product.catalogPriceLabel,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(product.description),
                  const SizedBox(height: 22),
                  Text('Size', style: theme.textTheme.titleMedium),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: () => showSevnSizeChart(context),
                      child: const Text('SEVN size chart'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final size in sizes)
                        ChoiceChip(
                          label: Text(size),
                          selected: selected?.size == size,
                          onSelected: product.variantForSize(size) == null
                              ? null
                              : (checked) {
                                  if (checked) {
                                    setState(() => _selectedSize = size);
                                  }
                                },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: selected == null || !canAdd
                        ? null
                        : () => _addToCart(selected),
                    child: const Text('Add to cart'),
                  ),
                  CartIssue(
                    cart: cartState,
                    controller: ref.read(cartProvider.notifier),
                  ),
                  const SizedBox(height: 18),
                  const _ComingLater(
                    icon: Icons.straighten_rounded,
                    title: 'Find my size',
                  ),
                  const SizedBox(height: 8),
                  const _ComingLater(
                    icon: Icons.photo_camera_outlined,
                    title: 'Virtual try-on',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComingLater extends StatelessWidget {
  const _ComingLater({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: colors.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const Text('Coming later'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
