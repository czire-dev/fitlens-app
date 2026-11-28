import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> openCartStorage(OpenDatabaseOptions options) async {
  sqfliteFfiInit();
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  return databaseFactoryFfi.openDatabase(
    path.join(directory.path, 'cart.sqlite'),
    options: options,
  );
}
