import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../checkout/checkout_models.dart';
import '../checkout/order_repository.dart';

final orderHistoryProvider = FutureProvider<List<OrderSummary>>(
  (ref) => ref.watch(orderRepositoryProvider).listOrders(),
  retry: (count, error) => null,
);

final orderDetailsProvider = FutureProvider.autoDispose
    .family<SavedOrder?, String>(
      (ref, reference) => ref.watch(orderRepositoryProvider).find(reference),
      retry: (count, error) => null,
    );
