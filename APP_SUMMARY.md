# FitLens

## What works today

FitLens opens on the ivory **Shop** tab with five offline sample shirts. A product page has a shared **SEVN size chart** before the size choices. The chart uses centimeters, and chest width and body length are marked **Pending** until documented measurements are available. Unavailable sizes are disabled. Pick an available size to enable **Add to cart**. **My fit** and **Orders** are work-in-progress pages.

## How a size becomes a cart line

A size in the bundled JSON has an integer `priceCentavos`. The detail page keeps the chosen size local and sends the product ID and size to the Riverpod cart controller. The controller checks the pair against the loaded catalog and uses that variant's price. Adding the same pair increases its quantity. Other product and size pairs get separate lines. [products.json](assets/data/products.json) · [Product details](lib/features/catalog/product_detail_page.dart) · [Cart controller](lib/features/cart/cart_controller.dart)

The cart multiplies unit price by quantity and sums the line totals, all in centavos. The Cart tab shows product thumbnails, a count based on total quantity, and a subtotal pinned above the navigation bar. Rows show the unit price when quantity exceeds one. Minus stops at one, and **Remove** deletes a line. The illustrated empty state offers **Browse shirts** to return to Shop. The cart survives tab changes and resets when the app restarts. [Cart screen](lib/features/cart/cart_page.dart) · [App shell](lib/app_shell.dart)

## Run and verify

From the repo root, run `flutter run -d chrome`. On a connected Android device, get its ID from `flutter devices` and run `flutter run -d <android-device-id>`.

Dart formatting, Flutter analysis, and all 14 tests passed. Chrome at 390 × 844 showed the chart, selection gate, add feedback, quantity changes, and empty cart. Native targets were untested. [Widget tests](test/catalog_test.dart) · [Cart controller tests](test/cart_controller_test.dart)

## Review the changes

Open the black graphic tee, view the chart, and add **M** twice. Back out to **Cart** and check the ₱1,798.00 subtotal. Decrease to one, remove the line, and tap **Browse shirts**. [Changelog](docs/CHANGELOG.md) · [Agent workflow](docs/AGENT.md)
