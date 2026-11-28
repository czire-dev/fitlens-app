import 'package:sqflite_common/sqlite_api.dart';

import 'cart_storage_native.dart'
    if (dart.library.js_interop) 'cart_storage_web.dart'
    as storage;

Future<Database> openCartDatabase() =>
    storage.openCartStorage(cartDatabaseOptions);

final cartDatabaseOptions = OpenDatabaseOptions(
  version: 2,
  onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
  onCreate: (db, version) async {
    await db.execute('''
    CREATE TABLE cart_lines (
      product_id TEXT NOT NULL,
      size TEXT NOT NULL,
      quantity INTEGER NOT NULL CHECK (typeof(quantity) = 'integer' AND quantity > 0),
      PRIMARY KEY (product_id, size)
    )
  ''');
    await _createOrderTables(db);
  },
  onUpgrade: (db, oldVersion, newVersion) async {
    if (oldVersion < 2) await _createOrderTables(db);
  },
);

Future<void> _createOrderTables(Database db) async {
  await db.execute('''
    CREATE TABLE orders (
      reference TEXT PRIMARY KEY NOT NULL,
      created_at TEXT NOT NULL,
      name TEXT NOT NULL,
      mobile TEXT NOT NULL,
      address TEXT NOT NULL,
      city TEXT NOT NULL,
      postal_code TEXT NOT NULL,
      subtotal_centavos INTEGER NOT NULL,
      delivery_centavos INTEGER NOT NULL,
      total_centavos INTEGER NOT NULL
        CHECK (total_centavos = subtotal_centavos + delivery_centavos)
    )
  ''');
  await db.execute('''
    CREATE TABLE order_items (
      order_reference TEXT NOT NULL REFERENCES orders(reference),
      product_id TEXT NOT NULL,
      product_name TEXT NOT NULL,
      size TEXT NOT NULL,
      quantity INTEGER NOT NULL CHECK (quantity > 0),
      unit_price_centavos INTEGER NOT NULL CHECK (unit_price_centavos > 0),
      PRIMARY KEY (order_reference, product_id, size)
    )
  ''');
}
