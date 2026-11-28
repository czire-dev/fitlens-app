import 'package:sqflite_common/sqlite_api.dart';

import 'cart_storage_native.dart'
    if (dart.library.js_interop) 'cart_storage_web.dart'
    as storage;

Future<Database> openCartDatabase() =>
    storage.openCartStorage(cartDatabaseOptions);

final cartDatabaseOptions = OpenDatabaseOptions(
  version: 1,
  onCreate: (db, version) => db.execute('''
    CREATE TABLE cart_lines (
      product_id TEXT NOT NULL,
      size TEXT NOT NULL,
      quantity INTEGER NOT NULL CHECK (typeof(quantity) = 'integer' AND quantity > 0),
      PRIMARY KEY (product_id, size)
    )
  '''),
);
