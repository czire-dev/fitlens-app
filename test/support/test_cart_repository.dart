import 'package:fitlens/features/cart/cart_repository.dart';

class TestCartRepository implements CartRepository {
  TestCartRepository([CartRows initial = const {}]) : _rows = Map.of(initial);

  final CartRows _rows;
  bool failNextWrite = false;
  bool failNextRead = false;

  @override
  Future<CartRows> read() async {
    if (failNextRead) {
      failNextRead = false;
      throw StateError('Test read failure');
    }
    return Map.of(_rows);
  }

  @override
  Future<CartRows> add(CartKey key) async =>
      setQuantity(key, (_rows[key] ?? 0) + 1);

  @override
  Future<CartRows> adjustQuantity(CartKey key, int delta) async =>
      setQuantity(key, _rows[key]! + delta);

  @override
  Future<CartRows> setQuantity(CartKey key, int quantity) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('Test write failure');
    }
    _rows[key] = quantity;
    return Map.of(_rows);
  }

  @override
  Future<CartRows> remove(CartKey key) async {
    _rows.remove(key);
    return Map.of(_rows);
  }

  @override
  Future<void> close() async {}
}
