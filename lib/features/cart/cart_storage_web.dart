import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<Database> openCartStorage(OpenDatabaseOptions options) =>
    databaseFactoryFfiWeb.openDatabase('cart.sqlite', options: options);
