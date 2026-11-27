import 'package:flutter/material.dart';

import '../../shared/widgets/garment_preview.dart';
import 'product.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  GarmentView _view = GarmentView.front;
  String? _selectedSize;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
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
                  GarmentPreview(view: _view, artHeight: 264),
                  const SizedBox(height: 8),
                  Align(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final view in GarmentView.values)
                          ChoiceChip(
                            label: Text(view.label),
                            selected: _view == view,
                            onSelected: (_) => setState(() => _view = view),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(product.name, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(product.priceLabel, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 22),
                  Text('Size', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  if (product.availableSizes.isEmpty)
                    const Text('No sizes available.')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final size in product.availableSizes)
                          ChoiceChip(
                            label: Text(size),
                            selected: _selectedSize == size,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedSize = size);
                              }
                            },
                          ),
                      ],
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
