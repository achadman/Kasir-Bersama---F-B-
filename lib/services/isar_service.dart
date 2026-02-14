import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/local/local_product.dart';
import '../models/local/local_category.dart';
import '../models/local/local_transaction.dart';

class IsarService {
  static final IsarService _instance = IsarService._internal();
  factory IsarService() => _instance;
  IsarService._internal();

  late Isar isar;

  Future<void> init() async {
    String directory = "";
    if (!kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      directory = dir.path;
    }

    isar = await Isar.open([
      LocalProductSchema,
      LocalCategorySchema,
      LocalTransactionSchema,
    ], directory: directory);
  }

  Future<void> clearAll() async {
    await isar.writeTxn(() async {
      await isar.localProducts.clear();
      await isar.localCategorys.clear();
      await isar.localTransactions.clear();
    });
  }
}
