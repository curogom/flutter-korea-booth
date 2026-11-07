import 'package:sembast_web/sembast_web.dart';

Future<Database> openBoothDatabase(String name) =>
    databaseFactoryWeb.openDatabase(name);
