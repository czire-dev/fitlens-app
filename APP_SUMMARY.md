# FitLens

## What works today

FitLens opens on the ivory **Shop** tab with a charcoal collection banner and five offline sample shirts. **Explore tee** opens the featured SEVN Black Graphic Tee, which has front and back artwork. The other shirts show their front artwork. Each card opens its own description, sizes, and price. The **My fit**, **Cart**, and **Orders** tabs show work-in-progress pages.

## How prices and navigation work

A size in the bundled JSON has an integer `priceCentavos`. For example, `94950` becomes `₱949.50` when `ProductVariant.priceLabel` divides it into whole pesos and centavos for display. Shop shows one price if all sizes cost the same and **From** followed by the lowest price when they differ. Picking a size on the detail page replaces that label with the exact price for the chosen size. The detail page owns the selection and clears it when you leave. [products.json](assets/data/products.json) · [product.dart](lib/features/catalog/product.dart) · [product_detail_page.dart](lib/features/catalog/product_detail_page.dart)

Riverpod loads the catalog and exposes loading, data, and error states. `AppShell` owns the selected tab and uses an `IndexedStack` to keep Shop mounted, so its scroll position survives tab changes. Details open above the shell. [catalog_provider.dart](lib/features/catalog/catalog_provider.dart) · [app_shell.dart](lib/app_shell.dart)

## Run and verify

From the repo root, run `flutter run -d chrome`. On a connected Android device, get its ID from `flutter devices` and run `flutter run -d <android-device-id>`.

Dart formatting, Flutter analysis, and all 11 tests passed. I checked the storefront, the last card, its detail page, and the Cart placeholder in Chrome at 390 × 844. Native targets were untested. [Catalog tests](test/catalog_test.dart) · [Product and asset tests](test/product_test.dart)

## Review the changes

Scroll to **SEVN Slate Signal Tee**, switch to **Cart**, and return to **Shop**. Open the tee, tap **XL**, and check that the price changes from **From ₱949.50** to **₱999.00**. Tap Back to return to the same spot. [Changelog](docs/CHANGELOG.md) · [Agent workflow](docs/AGENT.md)
