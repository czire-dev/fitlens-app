import 'package:sqflite_common/sqlite_api.dart';

typedef CartKey = ({String productId, String size});
typedef CartRows = Map<CartKey, int>;

class CartRepository {
  CartRepository(this._open);

  final Future<Database> Function() _open;
  Future<Database>? _opening;

  Future<Database> database() async {
    final opening = _opening ??= _open();
    try {
      return await opening;
    } catch (_) {
      if (identical(_opening, opening)) _opening = null;
      rethrow;
    }
  }

  Future<CartRows> read() async => readCartRows(await database());

  Future<CartRows> add(CartKey key) => _write(
    (txn) => txn.execute(
      'INSERT INTO cart_lines (product_id, size, quantity) VALUES (?, ?, 1) '
      'ON CONFLICT (product_id, size) DO UPDATE SET quantity = quantity + 1',
      [key.productId, key.size],
    ),
  );

  Future<CartRows> setQuantity(CartKey key, int quantity) => _write(
    (txn) => txn.rawUpdate(
      'UPDATE cart_lines SET quantity = ? WHERE product_id = ? AND size = ?',
      [quantity, key.productId, key.size],
    ),
  );

  Future<CartRows> adjustQuantity(CartKey key, int delta) => _write(
    (txn) => txn.rawUpdate(
      'UPDATE cart_lines SET quantity = quantity + ? '
      'WHERE product_id = ? AND size = ? AND quantity + ? > 0',
      [delta, key.productId, key.size, delta],
    ),
  );

  Future<CartRows> remove(CartKey key) => _write(
    (txn) => txn.rawDelete(
      'DELETE FROM cart_lines WHERE product_id = ? AND size = ?',
      [key.productId, key.size],
    ),
  );

  Future<CartRows> _write(Future<void> Function(Transaction txn) change) async {
    final db = await database();
    return db.transaction((txn) async {
      await change(txn);
      return readCartRows(txn);
    });
  }

  Future<void> close() async {
    final opening = _opening;
    _opening = null;
    if (opening == null) return;
    final Database db;
    try {
      db = await opening;
    } catch (_) {
      return;
    }
    await db.close();
  }
}

Future<CartRows> readCartRows(DatabaseExecutor db) async {
  final rows = await db.query('cart_lines', orderBy: 'rowid');
  return {
    for (final row in rows)
      (productId: row['product_id'] as String, size: row['size'] as String):
          row['quantity'] as int,
  };
}
