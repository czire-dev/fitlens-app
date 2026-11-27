# FitLens

## What works today

FitLens opens on an ivory storefront with a charcoal SEVN Co. collection banner. Tap **Explore tee** or the product card to open the SEVN Black Graphic Tee. The catalog shows two labeled placeholder illustrations of the same shirt. The detail page gives the garment the most space and lets you switch between **Front** and **Back**. Pick **M** or **L** to see a charcoal chip with ivory text and a checkmark. **Find my size** and **Virtual try-on** are labeled **Coming later**.

The design follows the written spec. The HTML reference and bundled shirt photos were unavailable. The shirt name, sample ₱899 price, and sizes come from [products.json](assets/data/products.json).

## Where to read the code

- [app_theme.dart](lib/core/theme/app_theme.dart) defines the palette, type styles, button sizing, and chip appearance. [garment_preview.dart](lib/shared/widgets/garment_preview.dart) draws the two views for both screens.
- [main.dart](lib/main.dart) starts the app inside `ProviderScope`. The `FutureProvider` in [catalog_provider.dart](lib/features/catalog/catalog_provider.dart) calls `loadProducts` in [product.dart](lib/features/catalog/product.dart). [catalog_page.dart](lib/features/catalog/catalog_page.dart) watches Riverpod's loading, data, and error states and shows an empty message when the list has no products.
- Tapping the banner action or card passes a `Product` into [product_detail_page.dart](lib/features/catalog/product_detail_page.dart). That page owns `_view` and `_selectedSize`. Taps use `setState` to rebuild the page. Reopening starts on Front with neither size selected.

## Run the preview

From the repo root, run `flutter run -d chrome`. For Android, start the emulator with `flutter emulators --launch Medium_Phone_API_36.1`, get its ID from `flutter devices`, and run `flutter run -d <android-device-id>`. If the Android SDK reports pending licenses, run `flutter doctor --android-licenses`.

Dart formatting completed, analysis passed, and all five [widget tests](test/catalog_test.dart) passed, including a 320 × 568 layout at 2× text size. Both screens were visually checked on Flutter's Chrome web target at 390 × 844. No layout issue was observed at that viewport. No Android device was connected. Android, iOS, and Windows desktop were untested.

## Try it yourself

In [app_theme.dart](lib/core/theme/app_theme.dart), change `selectedChipFill` to `Color(0xFF4A3C31)` and press **r** in the Flutter terminal to hot reload. Tap **M**, then **L**. The theme sets the new fill. The detail page decides which chip gets it.
