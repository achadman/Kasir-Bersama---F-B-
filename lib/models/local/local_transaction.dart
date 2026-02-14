import 'package:isar/isar.dart';

part 'local_transaction.g.dart';

@collection
class LocalTransaction {
  Id id = Isar.autoIncrement;

  String? supabaseId; // Null if not synced yet

  @Index()
  late String storeId;
  late String cashierId;
  late double totalAmount;
  late double cashReceived;
  late double change;
  late String paymentMethod;
  late DateTime createdAt;

  @Index()
  bool isSynced = false;

  late List<LocalTransactionItemData> items;

  // JSON stringified items or we use IsarLinks?
  // IsarLinks are better for relations, but JSON is faster for simple sync.
  // Let's use simple list if possible, or embedded.
  // Actually, Isar v3 supports Embedded objects.
}

@embedded
class LocalTransactionItemData {
  String? productId;
  String? name;
  int? quantity;
  double? unitPrice;
  double? totalPrice;
  String? notes;

  // Options as JSON string
  String? selectedOptionsJson;
}
