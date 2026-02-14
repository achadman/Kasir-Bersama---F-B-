import 'package:isar/isar.dart';

part 'local_product.g.dart';

@collection
class LocalProduct {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String supabaseId;

  late String name;
  late double basePrice;
  late double salePrice;
  late int stockQuantity;
  late bool isStockManaged;
  late bool isAvailable;
  String? imageUrl;
  String? sku;
  String? categoryId;
  @Index()
  String? storeId;

  DateTime? lastUpdated;
}
