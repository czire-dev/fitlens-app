import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'product.dart';

final catalogProvider = FutureProvider<List<Product>>(
  (ref) => loadProducts(rootBundle),
  // A bad bundled file cannot recover by repeatedly reading the same asset.
  retry: (retryCount, error) => null,
);
