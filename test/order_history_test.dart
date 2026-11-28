import 'dart:async';
import 'dart:io';

import 'package:fitlens/features/cart/cart_controller.dart';
import 'package:fitlens/features/cart/cart_database.dart';
import 'package:fitlens/features/cart/cart_repository.dart';
import 'package:fitlens/features/catalog/catalog_provider.dart';
import 'package:fitlens/features/catalog/product.dart';
import 'package:fitlens/features/checkout/checkout_models.dart';
import 'package:fitlens/features/checkout/order_repository.dart';
import 'package:fitlens/features/orders/order_providers.dart';
import 'package:fitlens/features/orders/orders_page.dart';
import 'package:fitlens/main.dart';
import 'package:fitlens/shared/widgets/order_amount_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _older = 'FL-A-OLDER-ORDER-REFERENCE-THAT-WRAPS-001';
const _newer = 'FL-Z-NEWER';
const _medium = (productId: 'test-tee', size: 'M');
const _delivery = (
  name: 'Mika Example',
  mobile: '09000000000',
  address: '12 Example St., Brgy. Demo',
  city: 'Sample City',
  postalCode: '1100',
);

Product _shirt(String name, int price) => Product(
  id: _medium.productId,
  name: name,
  description: 'Test fixture',
  imageAsset: 'assets/products/black-graphic-front.png',
  variants: [ProductVariant(size: _medium.size, priceCentavos: price)],
);

void main() {
  testWidgets(
    'Reopened history is newest first and the older receipt keeps its saved prices',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final olderAt = DateTime.utc(2026, 10, 31, 9);
      final newerAt = olderAt.add(const Duration(microseconds: 1));
      final container = (await tester.runAsync(() async {
        sqfliteFfiInit();
        final dir = await Directory.systemTemp.createTemp('fitlens-history-');
        addTearDown(() => dir.delete(recursive: true));
        final file = path.join(dir.path, 'cart.sqlite');
        CartRepository openCart() => CartRepository(
          () => databaseFactoryFfi.openDatabase(
            file,
            options: cartDatabaseOptions,
          ),
        );
        final cart = openCart();
        addTearDown(cart.close);
        final orders = OrderRepository(cart.database);
        final checkout = ProviderContainer(
          overrides: [
            cartRepositoryProvider.overrideWithValue(cart),
            catalogProvider.overrideWith(
              (ref) async => [_shirt('Original Tee', 89900)],
            ),
          ],
        );
        addTearDown(checkout.dispose);

        Future<void> save(String reference, int quantity, DateTime time) async {
          for (var count = 0; count < quantity; count++) {
            await cart.add(_medium);
          }
          final state = await checkout.refresh(cartProvider.future);
          await orders.save(
            CheckoutReview(reference, state, _delivery),
            reviewIsCurrent: () => true,
          );
          final database = await cart.database();
          await database.update(
            'orders',
            {'created_at': time.toIso8601String()},
            where: 'reference = ?',
            whereArgs: [reference],
          );
        }

        await save(_older, 2, olderAt);
        await save(_newer, 1, newerAt);
        expect((await orders.listOrders()).map((order) => order.reference), [
          _newer,
          _older,
        ]);
        final db = await cart.database();
        Future<void> setNewerTime(DateTime time) => db.update(
          'orders',
          {'created_at': time.toIso8601String()},
          where: 'reference = ?',
          whereArgs: [_newer],
        );
        await setNewerTime(olderAt);
        expect((await orders.listOrders()).map((order) => order.reference), [
          _older,
          _newer,
        ]);
        await setNewerTime(newerAt);
        await cart.close();

        final reopened = openCart();
        addTearDown(reopened.close);
        final app = ProviderContainer(
          overrides: [
            cartRepositoryProvider.overrideWithValue(reopened),
            catalogProvider.overrideWith(
              (ref) async => [_shirt('Renamed Tee', 94900)],
            ),
          ],
        );
        addTearDown(app.dispose);
        // Keep the real asynchronous reads outside the widget test's fake clock.
        app.listen(orderDetailsProvider(_older), (_, _) {});
        await app.read(orderHistoryProvider.future);
        await app.read(orderDetailsProvider(_older).future);
        await app.read(cartProvider.future);
        return app;
      }))!;

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MainApp()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Renamed Tee').hitTestable(), findsOneWidget);
      expect(find.text('₱949.00').hitTestable(), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Orders'),
        ),
      );
      await tester.pumpAndSettle();

      final older = find.text(_older).hitTestable();
      final newer = find.text(_newer).hitTestable();
      expect(
        tester.getTopLeft(newer).dy,
        lessThan(tester.getTopLeft(older).dy),
      );
      final earlierRow = find.ancestor(of: older, matching: find.byType(Card));
      expect(
        find.descendant(of: earlierRow, matching: find.text('₱1,798.00')),
        findsOneWidget,
      );
      final expectedDate = MaterialLocalizations.of(
        tester.element(older),
      ).formatShortDate(olderAt.toLocal());
      expect(
        find.descendant(of: earlierRow, matching: find.text(expectedDate)),
        findsOneWidget,
      );

      await tester.tap(older);
      await tester.pumpAndSettle();
      expect(find.text('Order details'), findsOneWidget);
      expect(find.widgetWithText(SelectableText, _older), findsOneWidget);
      expect(find.text(expectedDate), findsOneWidget);
      expect(find.text('Original Tee'), findsOneWidget);
      expect(find.text('Size M · Quantity 2'), findsOneWidget);
      expect(find.text('₱899.00 each'), findsOneWidget);
      expect(find.text('₱949.00 each'), findsNothing);
      expect(find.text(_delivery.address), findsOneWidget);
      final total = find.byWidgetPredicate(
        (widget) =>
            widget is OrderAmountRow &&
            widget.label == 'Total' &&
            widget.centavos == 179800,
      );
      expect(
        find.descendant(of: total, matching: find.text('₱1,798.00')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(older, findsOneWidget);
    },
  );

  testWidgets(
    'History distinguishes initial loading, failure, and an empty retry',
    (tester) async {
      final firstRead = Completer<List<OrderSummary>>();
      var reads = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderHistoryProvider.overrideWith(
              (ref) => reads++ == 0 ? firstRead.future : Future.value([]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: OrdersPage(onBrowse: () {})),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Loading orders'), findsOneWidget);
      expect(find.text('No orders yet'), findsNothing);
      firstRead.completeError(StateError('Test read failure'));
      await tester.pumpAndSettle();
      expect(find.text('Could not load your orders.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('No orders yet'), findsOneWidget);
      expect(find.text('Browse shirts'), findsOneWidget);
    },
  );
}
