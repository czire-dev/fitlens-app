import 'dart:async';

import 'package:fitlens/features/catalog/catalog_provider.dart';
import 'package:fitlens/features/catalog/product.dart';
import 'package:fitlens/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Shopper can choose and switch shirt sizes', (tester) async {
    const shirt = 'SEVN Black Graphic Tee';
    final medium = find.widgetWithText(ChoiceChip, 'M');
    final large = find.widgetWithText(ChoiceChip, 'L');
    final back = find.widgetWithText(ChoiceChip, 'Back');

    await tester.pumpWidget(const ProviderScope(child: MainApp()));
    await tester.pumpAndSettle();
    expect(find.text(shirt), findsOneWidget);
    expect(find.text('₱899'), findsOneWidget);
    expect(find.text('Front placeholder'), findsOneWidget);
    expect(find.text('Back placeholder'), findsOneWidget);

    await tester.tap(find.text('Explore tee'));
    await tester.pumpAndSettle();

    expect(find.text('Product details'), findsOneWidget);
    expect(medium, findsOneWidget);
    expect(large, findsOneWidget);
    expect(tester.widget<ChoiceChip>(medium).selected, isFalse);
    expect(tester.widget<ChoiceChip>(large).selected, isFalse);

    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.text('Back placeholder'), findsOneWidget);
    expect(find.text('Front placeholder'), findsNothing);

    await tester.ensureVisible(large);
    await tester.tap(large);
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(large).selected, isTrue);

    await tester.tap(medium);
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(medium).selected, isTrue);
    expect(tester.widget<ChoiceChip>(large).selected, isFalse);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(shirt));
    await tester.tap(find.text(shirt));
    await tester.pumpAndSettle();
    expect(find.text('Front placeholder'), findsOneWidget);
    expect(tester.widget<ChoiceChip>(medium).selected, isFalse);
    expect(tester.widget<ChoiceChip>(large).selected, isFalse);
  });

  testWidgets('Both screens scroll on a small phone with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogProvider.overrideWith(
            (ref) async => const [
              Product(
                id: 'layout-sample',
                name: 'SEVN Black Graphic Tee',
                pricePhp: 899,
                availableSizes: ['M', 'L'],
              ),
            ],
          ),
        ],
        child: const MainApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Back placeholder'));
    expect(find.text('Back placeholder').hitTestable(), findsOneWidget);

    final explore = find.text('Explore tee');
    await tester.ensureVisible(explore);
    await tester.tap(explore);
    await tester.pumpAndSettle();

    final large = find.widgetWithText(ChoiceChip, 'L');
    await tester.ensureVisible(large);
    await tester.tap(large);
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(large).selected, isTrue);

    await tester.ensureVisible(find.text('Virtual try-on'));
    expect(find.text('Virtual try-on').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Catalog shows loading, then an empty message', (tester) async {
    final bundle = _CatalogBundle();
    await tester.pumpWidget(_appWithBundle(bundle));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    bundle.response.complete('[]');
    await tester.pumpAndSettle();
    expect(find.text('No products available.'), findsOneWidget);
  });

  testWidgets('Catalog handles invalid product data', (tester) async {
    final bundle = _CatalogBundle();
    await tester.pumpWidget(_appWithBundle(bundle));

    bundle.response.complete('[{"id": "incomplete"}]');
    await tester.pumpAndSettle();
    expect(find.text('Could not load the catalog.'), findsOneWidget);
  });

  testWidgets('Catalog handles an unreadable asset', (tester) async {
    final bundle = _CatalogBundle();
    await tester.pumpWidget(_appWithBundle(bundle));

    bundle.response.completeError(StateError('Asset unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load the catalog.'), findsOneWidget);
  });
}

Widget _appWithBundle(AssetBundle bundle) {
  return ProviderScope(
    overrides: [catalogProvider.overrideWith((ref) => loadProducts(bundle))],
    child: const MainApp(),
  );
}

class _CatalogBundle extends CachingAssetBundle {
  final response = Completer<String>();

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    return response.future;
  }

  @override
  Future<ByteData> load(String key) {
    throw UnsupportedError('This test bundle only provides strings.');
  }
}
