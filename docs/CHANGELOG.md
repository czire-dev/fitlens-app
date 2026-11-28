# FitLens changelog

## Starting baseline (previously reported)

FitLens had an ivory streetwear storefront and a detail page for the sample SEVN Black Graphic Tee. The offline Riverpod catalog showed one product with front/back placeholders and local M/L selection. Formatting, analysis, five widget tests, and a 390 × 844 Chrome visual check were previously reported as passing. Android, iOS, and Windows desktop were untested.

## 2026-11-27 — Five shirts and bottom navigation

Added five offline sample shirts so shoppers can compare artwork, sizes, and prices. Added Shop, My fit, Cart, and Orders tabs so switching destinations preserves your place in Shop. Added a workflow and changelog for future batches.

Formatting, Flutter analysis, and all 11 tests passed. In Chrome at 390 × 844, the last card was fully reachable above the bar, Cart showed its placeholder, and the Slate Signal detail showed the exact XL price. Both tab switching and Back preserved the Shop position. The artwork is illustrative, the three secondary tabs are placeholders, and native targets were untested.

## 2026-11-28 — Select a size and build the cart

Added a size chart and availability checks, then connected product details to an in-memory cart so shoppers can combine variants, edit quantities, and see exact totals. Formatting, analysis, and all 14 tests passed. Chrome at 390 × 844 verified the chart, adding, editing, and removing the last item. Measurements are pending, the cart resets on restart, and native targets were untested.

## 2026-11-28 — Cart layout redesign

Added product thumbnails, compact quantity controls, and a pinned subtotal so shoppers can recognize and edit items while scrolling. The empty cart now uses an illustrated prompt to return to Shop. Formatting, analysis, and all 15 tests passed, including a long product name at 2× text on a 320 × 480 viewport. Inspected empty, one-item, and multi-item carts in Chrome at 390 × 844. Native targets were untested.
