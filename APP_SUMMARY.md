# FitLens

## What works today

FitLens opens on the ivory **Shop** tab with five offline sample shirts. A product page has a shared **SEVN size chart** before the size choices. The chart uses centimeters, and chest width and body length are marked **Pending** until documented measurements are available. Unavailable sizes are disabled. Pick an available size to enable **Add to cart**. **My fit** and **Orders** are work-in-progress pages.

## How a size becomes a cart line

A cart action goes from the widget to the Riverpod controller, then through `CartRepository` to SQLite. The version 1 database stores the product ID, size, and positive quantity. On startup, the controller resolves those rows against the bundled catalog. Prices and totals come from the catalog in integer centavos. Adding the same product and size increases its quantity. [Product details](lib/features/catalog/product_detail_page.dart) · [Cart controller](lib/features/cart/cart_controller.dart) · [Cart repository](lib/features/cart/cart_repository.dart) · [SQLite schema](lib/features/cart/cart_database.dart)

The Cart tab shows only confirmed writes. A failed read offers **Retry** without deleting saved rows. A failed write keeps the last confirmed quantities and subtotal visible, and **Retry** runs the failed edit before later queued edits. A saved product or size missing from the loaded catalog is **No longer available**. It stays removable and is excluded from the item count and subtotal. [Cart screen](lib/features/cart/cart_page.dart)

## Run and verify

Run `flutter build web` and serve `build/web` to check Chrome persistence. Use the same browser profile and origin, including the port, on both launches. The app ships a SQLite WASM binary and worker and stores the web database in IndexedDB. On a connected Android device, get its ID from `flutter devices` and run `flutter run -d <android-device-id>`. [Web SQLite setup](https://pub.dev/packages/sqflite_common_ffi_web/versions/1.1.1)

Dart formatting, Flutter analysis, all 20 tests, and the release web build passed. A temporary SQLite file retained quantities and removals after reopening. Chrome at 390 × 844 restored one M, one L, and the ₱1,798.00 subtotal in a new browser process. The cart was saved in the debug build and restored in the release build at the same origin and profile. Android, iOS, and the Windows app were untested. [Repository test](test/cart_repository_test.dart) · [Widget tests](test/catalog_test.dart) · [Controller tests](test/cart_controller_test.dart)

## Review the changes

Add the black tee in **M** twice and **L** once. In Cart, reduce **M** to one. Close the app, reopen it, and check that Cart shows one **M**, one **L**, and ₱1,798.00. [Changelog](docs/CHANGELOG.md) · [Agent workflow](docs/AGENT.md)
