import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/garment_preview.dart';
import 'catalog_provider.dart';
import 'product.dart';
import 'product_detail_page.dart';

class CatalogPage extends ConsumerWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(catalogProvider)
        .when(
          loading: () => const Center(
            child: CircularProgressIndicator(semanticsLabel: 'Loading catalog'),
          ),
          error: (error, stackTrace) =>
              const _CatalogMessage('Could not load the catalog.'),
          data: (products) => products.isEmpty
              ? const _CatalogMessage('No products available.')
              : _Storefront(products: products),
        );
  }
}

class _Storefront extends StatelessWidget {
  const _Storefront({required this.products});

  final List<Product> products;

  void _openProduct(BuildContext context, Product product) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ProductDetailPage(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CollectionBanner(
                  onExplore: () => _openProduct(context, products.first),
                ),
                const SizedBox(height: 24),
                for (final product in products)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ProductCard(
                      product: product,
                      onOpen: () => _openProduct(context, product),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectionBanner extends StatelessWidget {
  const _CollectionBanner({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final decoration = colors.secondaryContainer;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: ColoredBox(
        color: colors.primary,
        child: Stack(
          children: [
            Positioned(
              top: -95,
              right: -106,
              child: IgnorePointer(
                child: Container(
                  width: 305,
                  height: 305,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: decoration.withValues(alpha: .28),
                    ),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: decoration.withValues(alpha: .21),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SEVN CO.',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: decoration,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Streetwear\ncollection',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: colors.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: onExplore,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.onPrimary,
                      foregroundColor: colors.primary,
                    ),
                    child: const Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('Explore tee'),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onOpen});

  final Product product;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name, style: theme.textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                product.catalogPriceLabel,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GarmentPreview(
                      assetPath: product.imageAsset,
                      viewLabel: 'Front',
                      artHeight: 120,
                    ),
                  ),
                  if (product.backImageAsset case final backImage?) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: GarmentPreview(
                        assetPath: backImage,
                        viewLabel: 'Back',
                        artHeight: 120,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogMessage extends StatelessWidget {
  const _CatalogMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
