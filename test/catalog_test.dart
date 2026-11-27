import 'dart:async';

import 'package:fitlens/features/catalog/catalog_provider.dart';
import 'package:fitlens/features/catalog/product.dart';
import 'package:fitlens/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Product> bundledProducts;

  setUpAll(() async {
    bundledProducts = await loadProducts(rootBundle);
  });

  testWidgets('Shopper can choose and switch shirt sizes', (tester) async {
    const shirt = 'SEVN Black Graphic Tee';
    final medium = find.widgetWithText(ChoiceChip, 'M');
    final large = find.widgetWithText(ChoiceChip, 'L');
    final back = find.widgetWithText(ChoiceChip, 'Back');

    await tester.pumpWidget(_appWithProducts(bundledProducts));
    await tester.pumpAndSettle();
    expect(find.text(shirt), findsOneWidget);
    expect(find.text('₱899.00'), findsOneWidget);
    expect(find.text('Back · Sample artwork'), findsOneWidget);

    await tester.tap(find.text('Explore tee'));
    await tester.pumpAndSettle();

    expect(find.text('Product details'), findsOneWidget);
    expect(medium, findsOneWidget);
    expect(large, findsOneWidget);
    expect(tester.widget<ChoiceChip>(medium).selected, isFalse);
    expect(tester.widget<ChoiceChip>(large).selected, isFalse);

    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.text('Back · Sample artwork'), findsOneWidget);
    expect(find.text('Front · Sample artwork'), findsNothing);

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
    expect(find.text('Front · Sample artwork'), findsOneWidget);
    expect(tester.widget<ChoiceChip>(medium).selected, isFalse);
    expect(tester.widget<ChoiceChip>(large).selected, isFalse);
  });

  testWidgets('Shop keeps its scroll offset and opens the last product', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_appWithProducts(bundledProducts));
    await tester.pumpAndSettle();

    final nav = find.byType(NavigationBar);
    final slate = find.text('SEVN Slate Signal Tee');
    final lastCard = find.ancestor(of: slate, matching: find.byType(InkWell));
    await tester.ensureVisible(lastCard);
    final catalogPosition = tester.getTopLeft(slate);
    expect(
      tester.getBottomLeft(lastCard).dy,
      lessThan(tester.getTopLeft(nav).dy),
    );
    expect(find.text('From ₱949.50').hitTestable(), findsOneWidget);

    Finder tab(String label) =>
        find.descendant(of: nav, matching: find.text(label));

    final placeholders = {
      'My fit': 'Your measurements and fit preferences will appear here.',
      'Cart': 'The shirts and sizes you add will appear here.',
      'Orders': 'You’ll be able to see your past orders here.',
    };
    for (final (index, entry) in placeholders.entries.indexed) {
      await tester.tap(tab(entry.key));
      await tester.pumpAndSettle();
      expect(tester.widget<NavigationBar>(nav).selectedIndex, index + 1);
      expect(find.text('Work in progress').hitTestable(), findsOneWidget);
      expect(find.text(entry.value).hitTestable(), findsOneWidget);
    }
    await tester.tap(tab('Shop'));
    await tester.pumpAndSettle();
    expect(tester.widget<NavigationBar>(nav).selectedIndex, 0);
    expect(tester.getTopLeft(slate), catalogPosition);

    await tester.tap(slate);
    await tester.pumpAndSettle();
    expect(nav, findsNothing);
    expect(slate, findsOneWidget);
    expect(
      find.text(
        'A slate-blue crewneck with a pale signal graphic across the chest.',
      ),
      findsOneWidget,
    );
    expect(
      (tester.widget<Image>(find.byType(Image)).image as AssetImage).assetName,
      'assets/products/slate-signal.png',
    );
    expect(find.widgetWithText(ChoiceChip, 'Back'), findsNothing);
    expect(find.text('From ₱949.50'), findsOneWidget);
    for (final size in ['M', 'L', 'XL']) {
      final chip = find.widgetWithText(ChoiceChip, size);
      expect(tester.widget<ChoiceChip>(chip).selected, isFalse);
    }
    expect(find.widgetWithText(ChoiceChip, 'S'), findsNothing);

    final medium = find.widgetWithText(ChoiceChip, 'M');
    final extraLarge = find.widgetWithText(ChoiceChip, 'XL');
    await tester.tap(extraLarge);
    await tester.pumpAndSettle();
    expect(find.text('₱999.00'), findsOneWidget);
    expect(find.text('From ₱949.50'), findsNothing);
    await tester.tap(medium);
    await tester.pumpAndSettle();
    expect(find.text('₱949.50'), findsOneWidget);
    expect(tester.widget<ChoiceChip>(extraLarge).selected, isFalse);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(slate), catalogPosition);
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

    await tester.pumpWidget(_appWithProducts(bundledProducts));
    await tester.pumpAndSettle();
    final backArtwork = find.text('Back · Sample artwork');
    await tester.ensureVisible(backArtwork);
    expect(backArtwork.hitTestable(), findsOneWidget);

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

Widget _appWithProducts(List<Product> products) {
  return ProviderScope(
    overrides: [catalogProvider.overrideWith((ref) async => products)],
    child: const MainApp(),
  );
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
