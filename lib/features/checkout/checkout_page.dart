import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format_price.dart';
import '../../shared/widgets/garment_preview.dart';
import '../cart/cart_controller.dart';
import '../catalog/catalog_provider.dart';
import 'checkout_models.dart';
import 'delivery_form.dart';
import 'order_repository.dart';

final _deliveryDraft =
    NotifierProvider<_DeliveryDraft, Map<DeliveryField, String>>(
      _DeliveryDraft.new,
    );

class _DeliveryDraft extends Notifier<Map<DeliveryField, String>> {
  @override
  Map<DeliveryField, String> build() => const {};

  void change(DeliveryField field, String value) =>
      state = {...state, field: value};
  void clear() => state = const {};
}

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key, required this.onContinueShopping});

  final VoidCallback onContinueShopping;

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _form = GlobalKey<FormState>();

  Future<void> _review() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final cart = ref.read(cartProvider).asData?.value;
    if (cart == null ||
        !cart.canCheckout ||
        ref.read(cartProvider.notifier).hasPendingEdits) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check your cart before continuing.')),
      );
      return;
    }

    final review = CheckoutReview(
      newOrderReference(),
      cart,
      deliveryFromDraft(ref.read(_deliveryDraft)),
    );
    final result = await Navigator.of(context).push<Object>(
      MaterialPageRoute(builder: (_) => _ReviewPage(review: review)),
    );
    if (!mounted) return;
    if (result == _EditCart.requested) {
      Navigator.of(context).pop();
    } else if (result is SavedOrder) {
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(
          builder: (_) => _ConfirmationPage(
            order: result,
            onContinueShopping: widget.onContinueShopping,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CheckoutLayout(
      title: 'Delivery details',
      child: DeliveryForm(
        formKey: _form,
        draft: ref.read(_deliveryDraft),
        onChanged: (field, value) =>
            ref.read(_deliveryDraft.notifier).change(field, value),
        onReview: _review,
      ),
    );
  }
}

enum _EditCart { requested }

class _ReviewPage extends ConsumerStatefulWidget {
  const _ReviewPage({required this.review});

  final CheckoutReview review;

  @override
  ConsumerState<_ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<_ReviewPage> {
  late CheckoutReview _review = widget.review;
  bool _busy = false;
  bool _saveFailed = false;
  bool _needsReview = false;

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    final repository = ref.read(orderRepositoryProvider);
    final cartController = ref.read(cartProvider.notifier);
    try {
      final saved = await repository.save(
        _review,
        reviewIsCurrent: () =>
            mounted &&
            !cartController.hasPendingEdits &&
            _review.matchesCart(ref.read(cartProvider).asData?.value) &&
            _review.matchesCatalog(ref.read(catalogProvider).asData?.value),
      );
      if (!mounted) return;
      ref.invalidate(cartProvider);
      ref.read(_deliveryDraft.notifier).clear();
      Navigator.of(context).pop(saved);
    } on CheckoutChanged {
      if (!mounted) return;
      if (!cartController.hasPendingEdits) ref.invalidate(cartProvider);
      setState(() {
        _saveFailed = false;
        _needsReview = true;
      });
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshReview() async {
    if (_busy || ref.read(cartProvider.notifier).hasPendingEdits) return;
    setState(() => _busy = true);
    try {
      final cart = await ref.refresh(cartProvider.future);
      if (!mounted || !cart.canCheckout) return;
      final updated = CheckoutReview(
        newOrderReference(),
        cart,
        _review.delivery,
      );
      setState(() {
        _review = updated;
        _needsReview = false;
        _saveFailed = false;
      });
    } catch (_) {
      if (mounted) setState(() => _needsReview = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = ref.watch(cartProvider).asData?.value;
    final products = ref.watch(catalogProvider).asData?.value;
    final artwork = {
      if (products != null)
        for (final product in products) product.id: product.imageAsset,
    };
    final changed =
        _needsReview ||
        !_review.matchesCart(cart) ||
        !_review.matchesCatalog(products);
    final delivery = _review.delivery;

    return PopScope(
      canPop: !_busy,
      child: _CheckoutLayout(
        title: 'Review order',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ReviewSection(
              title: 'Items',
              editLabel: 'Edit cart items',
              onEdit: _busy
                  ? null
                  : () => Navigator.of(context).pop(_EditCart.requested),
            ),
            for (final item in _review.items)
              _ReviewedItem(item: item, assetPath: artwork[item.productId]),
            const SizedBox(height: 20),
            _ReviewSection(
              title: 'Deliver to',
              editLabel: 'Edit delivery details',
              onEdit: _busy ? null : () => Navigator.of(context).pop(),
            ),
            Card(
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(delivery.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(delivery.mobile),
                    Text(delivery.address),
                    Text('${delivery.city} ${delivery.postalCode}'),
                  ],
                ),
              ),
            ),
            const Divider(height: 32),
            _AmountRow(label: 'Subtotal', centavos: _review.subtotalCentavos),
            _AmountRow(
              label: 'Delivery',
              centavos: CheckoutReview.deliveryCentavos,
            ),
            _AmountRow(
              label: 'Total',
              centavos: _review.totalCentavos,
              emphasized: true,
            ),
            if (changed) ...[
              const SizedBox(height: 12),
              const Text(
                'Your cart or prices changed. Review the updated items before saving.',
              ),
              TextButton(
                onPressed: _busy || cart?.canCheckout == false
                    ? null
                    : _refreshReview,
                child: const Text('Review updated items'),
              ),
            ],
            if (_saveFailed) ...[
              const SizedBox(height: 12),
              const Text(
                'Could not save your demo order. Retry to check whether it was saved and finish if needed.',
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Saved on this device. No payment or delivery is initiated.',
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy || (changed && !_saveFailed) ? null : _save,
              child: Text(
                _busy
                    ? 'Please wait…'
                    : _saveFailed
                    ? 'Retry'
                    : 'Save demo order',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.editLabel,
    required this.onEdit,
  });

  final String title;
  final String editLabel;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      TextButton(
        onPressed: onEdit,
        child: Text('Edit', semanticsLabel: editLabel),
      ),
    ],
  );
}

class _ReviewedItem extends StatelessWidget {
  const _ReviewedItem({required this.item, required this.assetPath});

  final OrderItem item;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (assetPath case final path?) ...[
              SizedBox(
                width: 76,
                child: GarmentPreview(assetPath: path, artHeight: 52),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName, style: theme.textTheme.titleMedium),
                  Text('Size ${item.size} · Quantity ${item.quantity}'),
                  if (item.quantity > 1)
                    Text('${formatPesos(item.unitPriceCentavos)} each'),
                  const SizedBox(height: 4),
                  Text(
                    formatPesos(
                      CartLine.totalFor(item.unitPriceCentavos, item.quantity),
                    ),
                    style: theme.textTheme.titleMedium,
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

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.centavos,
    this.emphasized = false,
  });

  final String label;
  final int centavos;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasized
        ? theme.textTheme.titleLarge
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: EdgeInsets.only(top: emphasized ? 10 : 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              formatPesos(centavos),
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationPage extends StatefulWidget {
  const _ConfirmationPage({
    required this.order,
    required this.onContinueShopping,
  });

  final SavedOrder order;
  final VoidCallback onContinueShopping;

  @override
  State<_ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<_ConfirmationPage> {
  String? _copyFeedback;

  Future<void> _copyReference() async {
    String message;
    try {
      await Clipboard.setData(ClipboardData(text: widget.order.reference));
      message = 'Order reference copied.';
    } catch (_) {
      message = 'Select the order reference to copy it.';
    }
    if (mounted) setState(() => _copyFeedback = message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final order = widget.order;
    return _CheckoutLayout(
      title: 'Demo order saved',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CircleAvatar(
              radius: 32,
              backgroundColor: colors.surfaceContainerHigh,
              foregroundColor: colors.onSurface,
              child: const Icon(Icons.check_rounded, size: 32),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This demo order was saved on this device.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Card(
            color: colors.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Order reference',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: _copyReference,
                        child: const Text('Copy'),
                      ),
                    ],
                  ),
                  SelectableText(order.reference),
                  if (_copyFeedback case final feedback?) ...[
                    const SizedBox(height: 6),
                    Semantics(liveRegion: true, child: Text(feedback)),
                  ],
                  const Divider(height: 24),
                  _AmountRow(
                    label: 'Total',
                    centavos: order.totalCentavos,
                    emphasized: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              widget.onContinueShopping();
              Navigator.of(context).pop();
            },
            child: const Text('Continue shopping'),
          ),
        ],
      ),
    );
  }
}

class _CheckoutLayout extends StatelessWidget {
  const _CheckoutLayout({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      ),
    ),
  );
}
