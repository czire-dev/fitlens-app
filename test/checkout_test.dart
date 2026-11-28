import 'package:fitlens/features/cart/cart_controller.dart';
import 'package:fitlens/features/catalog/catalog_provider.dart';
import 'package:fitlens/features/catalog/product.dart';
import 'package:fitlens/features/checkout/checkout_models.dart';
import 'package:fitlens/features/checkout/order_repository.dart';
import 'package:fitlens/main.dart';
import 'package:fitlens/shared/widgets/garment_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_cart_repository.dart';

void main() {
  test('Philippine mobile formats allow spaces and hyphens', () {
    for (final value in [' 0917 123-4567 ', '+63 917-123-4567']) {
      expect(DeliveryField.mobile.validate(value), isNull);
    }
    for (final value in [
      '9171234567',
      '+63 8123456789',
      '091712345678',
      '0917A234567',
    ]) {
      expect(DeliveryField.mobile.validate(value), isNotNull);
    }
    expect(DeliveryField.postalCode.validate(' 0123 '), isNull);
    expect(DeliveryField.postalCode.validate('01 23'), isNotNull);
    expect(DeliveryField.city.validate(' 123 '), isNotNull);
    expect(DeliveryField.city.validate(' District 2, North-East '), isNull);
  });

  testWidgets('Delivery validates and restores every field after both edits', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const product = Product(
      id: 'tee',
      name: 'Sample Tee',
      description: 'Demo',
      imageAsset: 'assets/products/black-graphic-front.png',
      variants: [ProductVariant(size: 'M', priceCentavos: 89900)],
    );
    final repository = TestCartRepository({
      (productId: product.id, size: 'M'): 1,
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogProvider.overrideWith((ref) async => [product]),
          cartRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MainApp(),
      ),
    );
    await tester.pumpAndSettle();

    final cartTab = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Cart'),
    );
    await _tap(tester, cartTab);
    await _tap(tester, find.text('Checkout'));
    final fields = find.byType(EditableText);
    expect(find.byType(AutofillGroup), findsOneWidget);
    await tester.enterText(fields.at(1), '123');
    await tester.enterText(fields.at(3), '123');
    await tester.enterText(fields.at(4), '12345');
    await _tap(tester, find.widgetWithText(FilledButton, 'Review order'));
    for (final field in DeliveryField.values) {
      expect(find.text(field.error), findsOneWidget);
    }

    const values = [
      '  Mika  ',
      '+63 900-000-0000',
      ' Unit 12-A, Fictional Sample Building, 84 Test Street, Brgy. Demo Heights, near the model corner store ',
      ' Sample District 2, North-East ',
      ' 1100 ',
    ];
    for (final (index, value) in values.indexed) {
      await tester.enterText(fields.at(index), value);
    }
    await tester.enterText(fields.at(3), 'cAlO');
    tester.view.physicalSize = const Size(320, 700);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.ensureVisible(fields.at(3));
    await tester.pumpAndSettle();
    final suggestion = find.text('Caloocan City').hitTestable();
    expect(suggestion, findsOneWidget);
    expect(fields.at(3).hitTestable(), findsOneWidget);
    await tester.tap(suggestion);
    await tester.pumpAndSettle();
    final review = find.widgetWithText(FilledButton, 'Review order');
    await tester.ensureVisible(review);
    await tester.pumpAndSettle();
    expect(review.hitTestable(), findsOneWidget);
    tester.view.resetViewInsets();
    tester.view.physicalSize = const Size(390, 844);
    await _tap(tester, review);
    expect(find.text('Caloocan City 1100'), findsOneWidget);
    await _tap(tester, _edit('Edit delivery details'));
    expect(
      tester.widget<EditableText>(fields.at(3)).controller.text,
      'Caloocan City',
    );
    expect(
      tester.widget<EditableText>(fields.at(2)).controller.text,
      values[2],
    );
    expect(
      tester.widget<EditableText>(fields.at(4)).controller.text,
      values[4],
    );

    await tester.enterText(fields.at(3), 'Ma');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(fields.at(3)).controller.text,
      'Malabon City',
    );
    expect(
      tester.widget<EditableText>(fields.at(4)).focusNode.hasFocus,
      isTrue,
    );

    await tester.enterText(fields.at(3), 'Calo');
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(fields.at(3)).controller.text, 'Calo');
    expect(
      tester.widget<EditableText>(fields.at(4)).focusNode.hasFocus,
      isTrue,
    );
    await tester.enterText(fields.at(3), values[3]);

    await _tap(tester, find.widgetWithText(FilledButton, 'Review order'));
    expect(find.text('Mika'), findsOneWidget);
    expect(find.text('+639000000000'), findsOneWidget);
    expect(find.text(values[2].trim()), findsOneWidget);
    expect(find.text('Sample District 2, North-East 1100'), findsOneWidget);
    expect(_amount('Delivery', '₱0.00'), findsOneWidget);
    expect(_amount('Total', '₱899.00'), findsOneWidget);
    expect(find.byType(GarmentPreview), findsOneWidget);
    expect(find.text('₱899.00 each'), findsNothing);
    await _tap(tester, _edit('Edit delivery details'));
    void expectDraft() {
      for (final (index, value) in values.indexed) {
        expect(
          tester.widget<EditableText>(fields.at(index)).controller.text,
          value,
        );
      }
    }

    expectDraft();

    await _tap(tester, find.widgetWithText(FilledButton, 'Review order'));
    await _tap(tester, _edit('Edit cart items'));
    await _tap(
      tester,
      find.byTooltip('Increase quantity for Sample Tee, size M'),
    );
    await _tap(tester, find.text('Checkout'));
    expectDraft();
    await _tap(tester, find.widgetWithText(FilledButton, 'Review order'));
    expect(find.text('Size M · Quantity 2'), findsOneWidget);
    expect(_amount('Total', '₱1,798.00'), findsOneWidget);
    expect(find.text('₱899.00 each'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MainApp)),
    );
    await container.read(cartProvider.notifier).add(product.id, 'M');
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, 'Save demo order');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await _tap(tester, find.text('Review updated items'));
    expect(find.text('Size M · Quantity 3'), findsOneWidget);
    expect(_amount('Total', '₱2,697.00'), findsOneWidget);
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
  });

  testWidgets('Receipt copies the reference and exits the submitted checkout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    const key = (productId: 'tee', size: 'M');
    final cart = TestCartRepository({key: 2});
    final orders = _ConfirmationRepository(cart);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogProvider.overrideWith(
            (ref) async => const [
              Product(
                id: 'tee',
                name: 'Sample Tee',
                description: 'Demo',
                imageAsset: 'assets/products/black-graphic-front.png',
                variants: [ProductVariant(size: 'M', priceCentavos: 89900)],
              ),
            ],
          ),
          cartRepositoryProvider.overrideWithValue(cart),
          orderRepositoryProvider.overrideWithValue(orders),
        ],
        child: const MainApp(),
      ),
    );
    await tester.pumpAndSettle();
    await _tap(
      tester,
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Cart'),
      ),
    );

    Future<void> submit() async {
      await _tap(tester, find.text('Checkout'));
      final fields = find.byType(EditableText);
      expect(
        tester.widget<EditableText>(fields.first).controller.text,
        isEmpty,
      );
      const values = [
        'Mika',
        '0900 000-0000',
        '1 Example St., Brgy. Demo',
        'Sample Town',
        '1100',
      ];
      for (final (index, value) in values.indexed) {
        await tester.enterText(fields.at(index), value);
      }
      await _tap(tester, find.widgetWithText(FilledButton, 'Review order'));
      expect(_amount('Total', '₱1,798.00'), findsOneWidget);
      await _tap(tester, find.text('Save demo order'));
      expect(find.text('Demo order saved'), findsOneWidget);
      expect(_amount('Total', '₱1,798.00'), findsOneWidget);
      expect(find.text('Review order', skipOffstage: false), findsNothing);
    }

    await submit();
    await _tap(tester, find.text('Copy'));
    expect(copied, orders.latestReference);
    expect(find.text('Order reference copied.'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(find.text('Review order'), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MainApp)),
    );
    final controller = container.read(cartProvider.notifier);
    await controller.add(key.productId, key.size);
    await controller.add(key.productId, key.size);
    await tester.pumpAndSettle();
    await submit();
    await _tap(tester, find.text('Continue shopping'));
    expect(find.text('Explore tee').hitTestable(), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });
}

Finder _edit(String label) => find.byWidgetPredicate(
  (widget) =>
      widget is Text && widget.data == 'Edit' && widget.semanticsLabel == label,
);

Finder _amount(String label, String amount) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(Row)),
  matching: find.text(amount),
);

class _ConfirmationRepository extends OrderRepository {
  _ConfirmationRepository(this.cart) : super(() => throw UnimplementedError());

  final TestCartRepository cart;
  String? latestReference;

  @override
  Future<SavedOrder> save(
    CheckoutReview review, {
    required bool Function() reviewIsCurrent,
  }) async {
    expect(reviewIsCurrent(), isTrue);
    latestReference = review.reference;
    for (final item in review.items) {
      await cart.remove((productId: item.productId, size: item.size));
    }
    return SavedOrder(
      reference: review.reference,
      createdAt: DateTime.utc(2026),
      delivery: review.delivery,
      subtotalCentavos: review.subtotalCentavos,
      deliveryCentavos: CheckoutReview.deliveryCentavos,
      totalCentavos: review.totalCentavos,
      items: review.items.toList(),
    );
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
