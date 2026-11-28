import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format_price.dart';
import '../../shared/widgets/order_amount_row.dart';
import '../cart/cart_controller.dart';
import '../checkout/checkout_models.dart';
import 'order_providers.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key, required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
    top: false,
    child: ref
        .watch(orderHistoryProvider)
        .when(
          skipLoadingOnRefresh: false,
          loading: () => const Center(
            child: CircularProgressIndicator(semanticsLabel: 'Loading orders'),
          ),
          error: (_, _) => _OrderMessage(
            message: 'Could not load your orders.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(orderHistoryProvider),
          ),
          data: (orders) => orders.isEmpty
              ? _OrderMessage(
                  message: 'No orders yet',
                  actionLabel: 'Browse shirts',
                  onAction: onBrowse,
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _OrderRow(order: orders[index]),
                    ),
                  ),
                ),
        ),
  );
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => OrderDetailsPage(reference: order.reference),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localDate(context, order.createdAt),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(order.reference, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      formatPesos(order.totalCentavos),
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderDetailsPage extends ConsumerWidget {
  const OrderDetailsPage({super.key, required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = orderDetailsProvider(reference);
    return Scaffold(
      appBar: AppBar(title: const Text('Order details')),
      body: SafeArea(
        top: false,
        child: ref
            .watch(details)
            .when(
              skipLoadingOnRefresh: false,
              loading: () => const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Loading order details',
                ),
              ),
              error: (_, _) => _OrderMessage(
                message: 'Could not load this order.',
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(details),
              ),
              data: (order) => order == null
                  ? const _OrderMessage(
                      message: 'This order could not be found.',
                    )
                  : _OrderReceipt(order: order),
            ),
      ),
    );
  }
}

class _OrderReceipt extends StatelessWidget {
  const _OrderReceipt({required this.order});

  final SavedOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delivery = order.delivery;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Demo order saved on this device.'),
              const SizedBox(height: 12),
              _ReceiptCard(
                children: [
                  Text('Order reference', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  SelectableText(order.reference),
                  const SizedBox(height: 4),
                  Text(_localDate(context, order.createdAt)),
                ],
              ),
              const SizedBox(height: 16),
              Text('Items', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              for (final item in order.items) ...[
                _ReceiptCard(
                  children: [
                    Text(item.productName, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Size ${item.size} · Quantity ${item.quantity}'),
                    Text('${formatPesos(item.unitPriceCentavos)} each'),
                    OrderAmountRow(
                      label: 'Line total',
                      centavos: CartLine.totalFor(
                        item.unitPriceCentavos,
                        item.quantity,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              Text('Deliver to', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              _ReceiptCard(
                children: [
                  Text(delivery.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(delivery.mobile),
                  Text(delivery.address),
                  Text('${delivery.city} ${delivery.postalCode}'),
                ],
              ),
              const SizedBox(height: 16),
              _ReceiptCard(
                children: [
                  OrderAmountRow(
                    label: 'Subtotal',
                    centavos: order.subtotalCentavos,
                  ),
                  OrderAmountRow(
                    label: 'Delivery',
                    centavos: order.deliveryCentavos,
                  ),
                  const Divider(height: 20),
                  OrderAmountRow(
                    label: 'Total',
                    centavos: order.totalCentavos,
                    emphasized: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}

class _OrderMessage extends StatelessWidget {
  const _OrderMessage({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (actionLabel case final label?) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(label)),
          ],
        ],
      ),
    ),
  );
}

String _localDate(BuildContext context, DateTime timestamp) =>
    MaterialLocalizations.of(context).formatShortDate(timestamp.toLocal());
