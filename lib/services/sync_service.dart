import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isar/isar.dart';
import 'isar_service.dart';
import 'order_service.dart';
import '../models/local/local_product.dart';
import '../models/local/local_category.dart';
import '../models/local/local_transaction.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _supabase = Supabase.instance.client;
  final _isarService = IsarService();

  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;

  void init() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        syncUp();
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// PULL: Supabase -> Isar
  Future<void> syncDown(String storeId) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      debugPrint("SyncService: Starting SyncDown for store $storeId");

      // 1. Sync Categories
      final categoriesRes = await _supabase
          .from('categories')
          .select()
          .eq('store_id', storeId);

      final List<LocalCategory> localCategories = (categoriesRes as List).map((
        c,
      ) {
        return LocalCategory()
          ..supabaseId = c['id']
          ..name = c['name']
          ..iconUrl = c['icon_url']
          ..storeId = c['store_id']
          ..lastUpdated = DateTime.now();
      }).toList();

      // 2. Sync Products
      final productsRes = await _supabase
          .from('products')
          .select()
          .eq('store_id', storeId)
          .eq('is_deleted', false);

      final List<LocalProduct> localProducts = (productsRes as List).map((p) {
        return LocalProduct()
          ..supabaseId = p['id']
          ..name = p['name']
          ..basePrice = (p['base_price'] as num).toDouble()
          ..salePrice = (p['sale_price'] as num).toDouble()
          ..stockQuantity = (p['stock_quantity'] as num).toInt()
          ..isStockManaged = p['is_stock_managed'] ?? true
          ..isAvailable = p['is_available'] ?? true
          ..sku = p['sku']
          ..imageUrl = p['image_url']
          ..categoryId = p['category_id']
          ..storeId = p['store_id']
          ..lastUpdated = DateTime.now();
      }).toList();

      // Save to Isar
      await _isarService.isar.writeTxn(() async {
        await _isarService.isar.localCategorys.putAll(localCategories);
        await _isarService.isar.localProducts.putAll(localProducts);
      });

      debugPrint("SyncService: SyncDown Complete.");
    } catch (e) {
      debugPrint("SyncService: SyncDown Error: $e");
    } finally {
      _isSyncing = false;
    }
  }

  /// PUSH: Isar -> Supabase
  Future<void> syncUp() async {
    if (_isSyncing) return;

    try {
      final unsynced = await _isarService.isar.localTransactions
          .where()
          .isSyncedEqualTo(false)
          .findAll();

      if (unsynced.isEmpty) return;

      _isSyncing = true;
      debugPrint(
        "SyncService: SyncUp found ${unsynced.length} pending transactions",
      );

      final orderService = OrderService();

      for (var tx in unsynced) {
        try {
          // Prepare items for Supabase
          final List<Map<String, dynamic>> items = tx.items.map((item) {
            return {
              'product_id': item.productId,
              'quantity': item.quantity,
              'unit_price': item.unitPrice,
              'total_price': item.totalPrice,
              'notes': item.notes,
              'selected_options': jsonDecode(item.selectedOptionsJson ?? '[]'),
            };
          }).toList();

          await orderService.createOrder(
            storeId: tx.storeId,
            userId: tx.cashierId,
            totalAmount: tx.totalAmount,
            items: items,
            isSync: true, // Flag to prevent recursion if needed
          );

          // Mark as synced
          await _isarService.isar.writeTxn(() async {
            tx.isSynced = true;
            await _isarService.isar.localTransactions.put(tx);
          });

          debugPrint("SyncService: Transaction ${tx.id} synced successfully");
        } catch (e) {
          debugPrint("SyncService: Error syncing transaction ${tx.id}: $e");
          // Continue to next transaction
        }
      }
    } catch (e) {
      debugPrint("SyncService: Global SyncUp Error: $e");
    } finally {
      _isSyncing = false;
    }
  }
}
