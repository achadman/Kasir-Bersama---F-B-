import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'isar_service.dart';
import 'sync_service.dart';
import '../models/local/local_transaction.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _isarService = IsarService();

  /// Create a new transaction. Offline-first: saves to Isar first.
  Future<String> createOrder({
    required String storeId,
    required String userId,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
    bool isSync = false,
  }) async {
    debugPrint(
      "OrderService.createOrder: storeId=$storeId, userId=$userId, amount=$totalAmount, isSync=$isSync",
    );

    String txId = '';

    // 1. If this is a NEW order (not a sync operation), save to ISAR first
    if (!isSync) {
      final localTx = LocalTransaction()
        ..storeId = storeId
        ..cashierId = userId
        ..totalAmount = totalAmount
        ..cashReceived =
            0 // Needs to be passed if we want accurate cash tracking
        ..change = 0
        ..paymentMethod = 'cash'
        ..createdAt = DateTime.now()
        ..isSynced = false;

      // Map items
      localTx.items = items.map((item) {
        return LocalTransactionItemData()
          ..productId = item['product_id']
          ..name =
              item['name'] // Ensure name is passed in items
          ..quantity = item['quantity']
          ..unitPrice = item['unit_price']
          ..totalPrice = item['total_price']
          ..notes = item['notes']
          ..selectedOptionsJson = jsonEncode(item['selected_options'] ?? []);
      }).toList();

      await _isarService.isar.writeTxn(() async {
        await _isarService.isar.localTransactions.put(localTx);
      });

      txId = "local_${localTx.id}";

      // Trigger background sync
      SyncService().syncUp();

      return txId; // Return immediate local ID for UI
    }

    // 2. If isSync=true, this is being called by SyncService to push to Supabase
    final txResponse = await _supabase
        .from('transactions')
        .insert({
          'store_id': storeId,
          'cashier_id': userId,
          'total_amount': totalAmount,
          'payment_method': 'cash',
          'status': 'completed',
          'source': 'pos_mobile',
        })
        .select()
        .single();

    txId = txResponse['id'] as String;

    // Insert transaction items
    final List<Map<String, dynamic>> itemsToInsert = items.map((item) {
      return {
        'transaction_id': txId,
        'product_id': item['product_id'],
        'quantity': item['quantity'],
        'price_at_time': item['unit_price'],
        'notes': item['notes'],
        'selected_options': item['selected_options'] ?? [],
      };
    }).toList();

    await _supabase.from('transaction_items').insert(itemsToInsert);

    // Update Product Stock in Supabase
    for (var item in items) {
      final pId = item['product_id'];
      final qty = item['quantity'];

      try {
        final productData = await _supabase
            .from('products')
            .select('stock_quantity')
            .eq('id', pId)
            .single();
        final currentStock = productData['stock_quantity'] ?? 0;

        await _supabase
            .from('products')
            .update({'stock_quantity': currentStock - qty})
            .eq('id', pId);
      } catch (e) {
        debugPrint("OrderService: Stock update failed for $pId: $e");
      }
    }

    return txId;
  }

  /// Get transactions for today for a specific store
  Future<List<Map<String, dynamic>>> getTodayOrders(String storeId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

    // Fetch transactions with their items joined
    final response = await _supabase
        .from('transactions')
        .select('*, transaction_items(*, products(name))')
        .eq('store_id', storeId)
        .gte('created_at', startOfDay)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
