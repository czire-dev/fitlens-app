import 'dart:io';

import 'package:fitlens/features/cart/cart_database.dart';
import 'package:fitlens/features/cart/cart_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test(
    'SQLite keeps quantities and deletions after closing and reopening',
    () async {
      sqfliteFfiInit();
      final directory = await Directory.systemTemp.createTemp(
        'fitlens-cart-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = path.join(directory.path, 'cart.sqlite');
      CartRepository open() => CartRepository(
        () =>
            databaseFactoryFfi.openDatabase(file, options: cartDatabaseOptions),
      );

      const medium = (productId: 'black', size: 'M');
      const large = (productId: 'black', size: 'L');
      const removed = (productId: 'slate', size: 'XL');
      final first = open();
      addTearDown(first.close);
      await first.add(medium);
      await first.add(medium);
      await first.add(large);
      await first.add(removed);
      await first.remove(removed);
      await expectLater(
        first.setQuantity(medium, 0),
        throwsA(isA<DatabaseException>()),
      );
      await first.close();

      final reopened = open();
      addTearDown(reopened.close);
      expect(await reopened.read(), {medium: 2, large: 1});
    },
  );
}
