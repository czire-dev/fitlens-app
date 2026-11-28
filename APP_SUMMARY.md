# FitLens

## What works today

FitLens opens on the ivory **Shop** tab with five offline sample shirts. Product pages show a shared **SEVN size chart** and disable unavailable sizes. Cart persists across restarts. An available cart can proceed to guest delivery details, review, and **Save demo order**. The demo saves locally and initiates no payment or delivery. **Orders** lists saved demo orders and opens their read-only receipts. **My fit** remains a work-in-progress page.

## How a size becomes a cart line

A cart action goes from the widget to the Riverpod controller, then through `CartRepository` to SQLite. Cart rows store product ID, size, and quantity. On startup, the controller resolves those rows against the bundled catalog. Cart prices use integer centavos, and adding the same product and size increases its quantity. [Cart controller](lib/features/cart/cart_controller.dart) · [Cart repository](lib/features/cart/cart_repository.dart)

The Cart tab shows only confirmed writes. A failed read offers **Retry** without deleting saved rows. A failed write keeps the last confirmed quantities and subtotal visible, and **Retry** runs the failed edit before later queued edits. A saved product or size missing from the loaded catalog is **No longer available**. It stays removable and is excluded from the item count and subtotal. [Cart screen](lib/features/cart/cart_page.dart)

## How a draft becomes a saved order

Delivery details group contact and address fields and offer device autofill hints. City suggestions work offline using a small Metro Manila list, and shoppers can also type a valid locality manually. Changing the city leaves the street and postal code alone. The draft stays in memory through either Edit action. [Delivery form](lib/features/checkout/delivery_form.dart) · [Philippine Statistics Authority locality list](https://psa.gov.ph/classification/psgc/citimuni/1300000000)

Review shows thumbnails, a wrapped address, and the final total. If the cart or catalog changes, the shopper must review the updated items. The version 2 migration preserves cart rows and adds `orders` and `order_items`. One transaction saves the reviewed snapshot and clears the checked-out cart. Retry uses the same reference, and the saved order keeps its own product names and prices. After commit, the draft clears and the receipt offers **Copy** and **Continue shopping**. [Checkout screens](lib/features/checkout/checkout_page.dart) · [Order repository](lib/features/checkout/order_repository.dart) · [SQLite schema](lib/features/cart/cart_database.dart)

Orders refreshes after checkout and lists saved orders newest first, using the reference to break timestamp ties. Opening a row reads the saved snapshot by reference. The local date, items, prices, delivery details, and total come from that snapshot, so renaming or repricing a shirt in Shop leaves the receipt intact. [Orders screens](lib/features/orders/orders_page.dart) · [Order repository](lib/features/checkout/order_repository.dart)

## Run and verify

Run `flutter build web` and serve `build/web` to check Chrome persistence. Use the same browser profile and origin, including the port, on both launches. The app ships a SQLite WASM binary and worker and stores the web database in IndexedDB. On a connected Android device, get its ID from `flutter devices` and run `flutter run -d <android-device-id>`. [Web SQLite setup](https://pub.dev/packages/sqflite_common_ffi_web/versions/1.1.1)

Dart formatting, Flutter analysis, and all 28 tests passed. A reopened SQLite test showed two orders newest first and confirmed the older receipt still showed ₱899.00 each and ₱1,798.00 total after the fixture catalog price changed to ₱949.00. Tests also covered first-launch empty history, Retry, and a saved order appearing after checkout. [Orders tests](test/order_history_test.dart) · [Checkout tests](test/checkout_test.dart)

## Review the changes

Open **Orders**, then save a demo order through **Checkout**. Return to **Orders**, tap the new reference, and compare the saved receipt to the checkout total. Use Back to return to the list. [Changelog](docs/CHANGELOG.md) · [Agent workflow](docs/AGENT.md)
