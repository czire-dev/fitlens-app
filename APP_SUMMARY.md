# FitLens

## What works today

FitLens opens on the ivory **Shop** tab with five offline sample shirts. Product pages show a shared **SEVN size chart** and disable unavailable sizes. Cart persists across restarts. An available cart can proceed to guest delivery details, review, and **Save demo order**. The demo saves locally and initiates no payment or delivery. **My fit** and **Orders** remain work-in-progress pages.

## How a size becomes a cart line

A cart action goes from the widget to the Riverpod controller, then through `CartRepository` to SQLite. Cart rows store product ID, size, and quantity. On startup, the controller resolves those rows against the bundled catalog. Cart prices use integer centavos, and adding the same product and size increases its quantity. [Cart controller](lib/features/cart/cart_controller.dart) · [Cart repository](lib/features/cart/cart_repository.dart)

The Cart tab shows only confirmed writes. A failed read offers **Retry** without deleting saved rows. A failed write keeps the last confirmed quantities and subtotal visible, and **Retry** runs the failed edit before later queued edits. A saved product or size missing from the loaded catalog is **No longer available**. It stays removable and is excluded from the item count and subtotal. [Cart screen](lib/features/cart/cart_page.dart)

## How a draft becomes a saved order

Delivery details group contact and address fields and offer device autofill hints. City suggestions work offline using a small Metro Manila list, and shoppers can also type a valid locality manually. Changing the city leaves the street and postal code alone. The draft stays in memory through either Edit action. [Delivery form](lib/features/checkout/delivery_form.dart) · [Philippine Statistics Authority locality list](https://psa.gov.ph/classification/psgc/citimuni/1300000000)

Review shows thumbnails, a wrapped address, and the final total. If the cart or catalog changes, the shopper must review the updated items. The version 2 migration preserves cart rows and adds `orders` and `order_items`. One transaction saves the reviewed snapshot and clears the checked-out cart. Retry uses the same reference, and the saved order keeps its own product names and prices. After commit, the draft clears and the receipt offers **Copy** and **Continue shopping**. [Checkout screens](lib/features/checkout/checkout_page.dart) · [Order repository](lib/features/checkout/order_repository.dart) · [SQLite schema](lib/features/cart/cart_database.dart)

## Run and verify

Run `flutter build web` and serve `build/web` to check Chrome persistence. Use the same browser profile and origin, including the port, on both launches. The app ships a SQLite WASM binary and worker and stores the web database in IndexedDB. On a connected Android device, get its ID from `flutter devices` and run `flutter run -d <android-device-id>`. [Web SQLite setup](https://pub.dev/packages/sqflite_common_ffi_web/versions/1.1.1)

Dart formatting, Flutter analysis, and all 26 tests passed. Widget tests exercised city selection by touch and keyboard, a simulated keyboard inset at 320 pixels wide, unlisted locality entry, and receipt navigation. In Chrome at 390 and 320 pixels wide, the ₱1,798.00 review matched the saved receipt and **Continue shopping** opened Shop. Saved-profile autofill and native apps were untested. [Checkout tests](test/checkout_test.dart) · [Order repository tests](test/order_repository_test.dart)

## Review the changes

Add a shirt, open **Checkout**, and enter demo delivery details. On **Review order**, use **Edit cart items**, change the quantity, and reopen Checkout. Check that the fields are still filled and Review shows the new total. Save and confirm that a reference appears and Cart is empty. [Changelog](docs/CHANGELOG.md) · [Agent workflow](docs/AGENT.md)
