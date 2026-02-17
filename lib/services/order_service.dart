import 'package:flutter/foundation.dart';
import 'app_database.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

class OrderService {
  final AppDatabase db;

  OrderService(this.db);

  /// Create a new transaction.
  Future<String> createOrder({
    required String storeId,
    required String userId,
    required double totalAmount,
    required double cashReceived,
    required double change,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    debugPrint(
      "OrderService.createOrder: storeId=$storeId, userId=$userId, amount=$totalAmount",
    );

    final txId = const Uuid().v4();
    final now = DateTime.now();

    await db.transaction(() async {
      // 1. Save Transaction
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: txId,
              storeId: Value(storeId),
              cashierId: Value(userId),
              totalAmount: Value(totalAmount),
              cashReceived: Value(cashReceived),
              change: Value(change),
              paymentMethod: Value(paymentMethod),
              createdAt: Value(now),
            ),
          );

      // 2. Save Transaction Items & Update Stock
      for (var item in items) {
        final itemId = const Uuid().v4();
        final productId = item['product_id'] as String;
        final quantity = item['quantity'] as int;
        final unitPrice = (item['unit_price'] as num).toDouble();

        await db
            .into(db.transactionItems)
            .insert(
              TransactionItemsCompanion.insert(
                id: itemId,
                transactionId: Value(txId),
                productId: Value(productId),
                productName: Value(item['product_name'] as String?),
                quantity: Value(quantity),
                unitPrice: Value(unitPrice),
                totalPrice: Value((item['total_price'] as num).toDouble()),
                notes: Value(item['notes'] as String?),
              ),
            );

        // Update Local Stock using Drift's update
        final productQuery = db.select(db.products)
          ..where((t) => t.id.equals(productId));
        final product = await productQuery.getSingleOrNull();

        if (product != null && product.isStockManaged) {
          final newStock = (product.stockQuantity ?? 0) - quantity;
          await (db.update(db.products)..where((t) => t.id.equals(productId)))
              .write(ProductsCompanion(stockQuantity: Value(newStock)));
        }
      }
    });

    return txId;
  }

  /// Get transactions for today for a specific store
  Future<List<Map<String, dynamic>>> getTodayOrders(String storeId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final txResults =
        await (db.select(db.transactions)
              ..where((t) => t.storeId.equals(storeId))
              ..where((t) => t.createdAt.isBiggerOrEqualValue(startOfDay))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();

    List<Map<String, dynamic>> result = [];
    for (var tx in txResults) {
      final items = await (db.select(
        db.transactionItems,
      )..where((t) => t.transactionId.equals(tx.id))).get();

      // Convert to map-like structure if needed for legacy compatibility,
      // but ideally we should return data classes.
      // For now, let's keep it as Map<String, dynamic> to avoid breaking too much UI.
      final txMap = tx.toJson();
      txMap['transaction_items'] = items.map((e) => e.toJson()).toList();
      result.add(txMap);
    }

    return result;
  }
}
