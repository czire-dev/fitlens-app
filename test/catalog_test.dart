import 'dart:async';

import 'package:fitlens/features/cart/cart_controller.dart';
import 'package:fitlens/features/cart/cart_page.dart';
import 'package:fitlens/features/catalog/catalog_provider.dart';
import 'package:fitlens/features/catalog/product.dart';
import 'package:fitlens/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_cart_repository.dart';

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

    final add = find.widgetWithText(FilledButton, 'Add to cart');
    expect(tester.widget<FilledButton>(add).onPressed, isNull);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'XS'))
          .onSelected,
      isNull,
    );

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
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text('Size M added to cart.'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Cart'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Size M').hitTestable(), findsOneWidget);
    expect(find.text('1 item').hitTestable(), findsOneWidget);
    expect(find.text('₱899.00 each').hitTestable(), findsNothing);
    final cartPage = find.byType(CartPage);
    Finder cartText(String text) =>
        find.descendant(of: cartPage, matching: find.text(text));
    expect(cartText('Subtotal'), findsOneWidget);
    expect(cartText('₱899.00'), findsNWidgets(2));
    final minus = find.byTooltip(
      'Decrease quantity for SEVN Black Graphic Tee, size M',
    );
    final minusButton = find.byWidgetPredicate(
      (widget) =>
          widget is IconButton &&
          widget.tooltip ==
              'Decrease quantity for SEVN Black Graphic Tee, size M',
    );
    expect(tester.widget<IconButton>(minusButton).onPressed, isNull);
    await tester.tap(
      find.byTooltip('Increase quantity for SEVN Black Graphic Tee, size M'),
    );
    await tester.pumpAndSettle();
    expect(cartText('₱1,798.00'), findsNWidgets(2));
    expect(find.text('₱899.00 each').hitTestable(), findsOneWidget);
    await tester.tap(minus);
    await tester.pumpAndSettle();
    expect(cartText('₱899.00'), findsNWidgets(2));
    await tester.tap(find.text('Remove').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Browse shirts').hitTestable());
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );

    await tester.ensureVisible(find.text(shirt));
    await tester.tap(find.text(shirt));
    await tester.pumpAndSettle();
    expect(find.text('Front · Sample artwork'), findsOneWidget);
    expect(tester.widget<ChoiceChip>(medium).selected, isFalse);
    expect(tester.widget<ChoiceChip>(large).selected, isFalse);
  });

  testWidgets('Cart fits a short phone with large text and pins its subtotal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    const longName = 'SEVN Extended Collection Black Graphic Streetwear Tee';
    final original = bundledProducts.first;
    await tester.pumpWidget(
      _appWithProducts([
        Product(
          id: original.id,
          name: longName,
          description: original.description,
          imageAsset: original.imageAsset,
          variants: original.variants,
        ),
      ]),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MainApp)),
    );
    final cart = container.read(cartProvider.notifier);
    final nav = find.byType(NavigationBar);
    await tester.tap(find.descendant(of: nav, matching: find.text('Cart')));
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty').hitTestable(), findsOneWidget);
    await tester.ensureVisible(find.text('Browse shirts'));
    expect(find.text('Browse shirts').hitTestable(), findsOneWidget);

    cart.add(original.id, 'M');
    cart.add(original.id, 'M');
    cart.add(original.id, 'L');
    await tester.pumpAndSettle();
    expect(find.text('3 items').hitTestable(), findsOneWidget);
    final subtotal = find.text('Subtotal').hitTestable();
    expect(subtotal, findsOneWidget);
    final position = tester.getTopLeft(subtotal);
    final list = find.descendant(
      of: find.byType(CartPage),
      matching: find.byType(Scrollable),
    );
    final lastSize = find.text('Size L');
    await tester.scrollUntilVisible(lastSize, 120, scrollable: list);
    await tester.pumpAndSettle();
    expect(lastSize.hitTestable(), findsOneWidget);
    expect(tester.getTopLeft(subtotal), position);
    final lastRemove = find.descendant(
      of: find.ancestor(of: lastSize, matching: find.byType(Card)),
      matching: find.text('Remove'),
    );
    await tester.scrollUntilVisible(lastRemove, 100, scrollable: list);
    await tester.pumpAndSettle();
    expect(lastRemove.hitTestable(), findsOneWidget);
    expect(tester.getTopLeft(subtotal), position);
    expect(tester.takeException(), isNull);
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
      'Cart': 'Your cart is empty',
      'Orders': 'You’ll be able to see your past orders here.',
    };
    for (final (index, entry) in placeholders.entries.indexed) {
      await tester.tap(tab(entry.key));
      await tester.pumpAndSettle();
      expect(tester.widget<NavigationBar>(nav).selectedIndex, index + 1);
      if (entry.key != 'Cart') {
        expect(find.text('Work in progress').hitTestable(), findsOneWidget);
      }
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
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'S'))
          .onSelected,
      isNull,
    );

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

  testWidgets('A failed add preserves totals and Retry adds one unit', (
    tester,
  ) async {
    final product = bundledProducts.first;
    final repository = TestCartRepository({
      (productId: product.id, size: 'M'): 1,
    })..failNextWrite = true;
    await tester.pumpWidget(_appWithProducts(bundledProducts, repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore tee'));
    await tester.pumpAndSettle();
    final size = find.widgetWithText(ChoiceChip, 'M');
    await tester.ensureVisible(size);
    await tester.tap(size);
    final add = find.text('Add to cart');
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text('Could not save the cart change.'), findsOneWidget);
    expect(find.text('Size M added to cart.'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _openCart(tester);
    expect(find.text('1 item'), findsOneWidget);
    expect(find.text('₱899.00').hitTestable(), findsWidgets);

    await tester.tap(find.text('Retry').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('2 items'), findsOneWidget);
    expect(find.text('₱1,798.00'), findsNWidgets(2));
    expect(find.text('Could not save the cart change.'), findsNothing);
  });

  testWidgets(
    'Saved rows survive a read retry and unavailable sizes stay removable',
    (tester) async {
      final product = bundledProducts.first;
      final missing = (productId: product.id, size: 'XS');
      final repository = TestCartRepository({
        (productId: product.id, size: 'M'): 2,
        missing: 3,
      })..failNextRead = true;
      await tester.pumpWidget(_appWithProducts(bundledProducts, repository));
      await tester.pumpAndSettle();
      await _openCart(tester);
      expect(find.text('Could not load your saved cart.'), findsOneWidget);
      expect(find.text('Your cart is empty'), findsNothing);

      await tester.tap(find.text('Retry').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('No longer available'), findsOneWidget);
      final checkout = find.widgetWithText(FilledButton, 'Checkout');
      expect(tester.widget<FilledButton>(checkout).onPressed, isNull);
      expect(find.text('Size XS · Quantity 3'), findsOneWidget);
      expect(find.text('2 items'), findsOneWidget);
      expect(find.text('₱1,798.00'), findsNWidgets(2));
      final unavailableCard = find.ancestor(
        of: find.text('No longer available'),
        matching: find.byType(Card),
      );
      final remove = find.descendant(
        of: unavailableCard,
        matching: find.text('Remove'),
      );
      await tester.ensureVisible(remove);
      await tester.pumpAndSettle();
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect((await repository.read()).containsKey(missing), isFalse);
      expect(tester.widget<FilledButton>(checkout).onPressed, isNotNull);
      expect(find.text('₱1,798.00'), findsNWidgets(2));
    },
  );

  testWidgets(
    'Catalog failure is reported separately from unavailable variants',
    (tester) async {
      final bundle = _CatalogBundle();
      await tester.pumpWidget(_appWithBundle(bundle));
      bundle.response.completeError(StateError('Missing catalog'));
      await tester.pumpAndSettle();
      await _openCart(tester);
      expect(
        find.text('Could not load the catalog for your cart.'),
        findsOneWidget,
      );
      expect(find.text('No longer available'), findsNothing);
      expect(find.text('Your cart is empty'), findsNothing);
    },
  );

  testWidgets('Catalog shows loading, then an empty message', (tester) async {
    final bundle = _CatalogBundle();
    await tester.pumpWidget(_appWithBundle(bundle));
    expect(
      find.byType(CircularProgressIndicator).hitTestable(),
      findsOneWidget,
    );

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

Future<void> _openCart(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Cart'),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _appWithProducts(
  List<Product> products, [
  TestCartRepository? repository,
]) {
  return ProviderScope(
    overrides: [
      catalogProvider.overrideWith((ref) async => products),
      cartRepositoryProvider.overrideWithValue(
        repository ?? TestCartRepository(),
      ),
    ],
    child: const MainApp(),
  );
}

Widget _appWithBundle(AssetBundle bundle) {
  return ProviderScope(
    overrides: [
      catalogProvider.overrideWith((ref) => loadProducts(bundle)),
      cartRepositoryProvider.overrideWithValue(TestCartRepository()),
    ],
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
