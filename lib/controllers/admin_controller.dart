import 'dart:async';
import 'package:flutter/material.dart';
import '../services/app_database.dart';
import 'package:drift/drift.dart';
import '../services/promotion_service.dart';

class AdminController extends ChangeNotifier {
  final AppDatabase _db;
  late final PromotionService _promotionService;

  AdminController(this._db) {
    _promotionService = PromotionService(_db);
  }

  String? _userId;
  String? _storeId;
  String? _userName;
  String? _profileUrl;
  String? _storeName;
  String? _storeLogo;
  String? _role;
  Map<String, dynamic>? _permissions;
  bool _isInitializing = true;
  double _todaySales = 0;
  int _lowStockCount = 0;
  List<Map<String, dynamic>> _lowStockItems = [];
  int _transactionCount = 0;
  Map<String, dynamic>? _userProfile;

  // Stream subscriptions for reactivity
  StreamSubscription? _salesSubscription;
  StreamSubscription? _lowStockSubscription;

  List<Category> _categories = [];
  List<Product> _products = [];

  // Getters
  String? get userId => _userId;
  String? get storeId => _storeId;
  String? get userName => _userName;
  String? get profileUrl => _profileUrl;
  String? get storeName => _storeName;
  String? get storeLogo => _storeLogo;
  String? get role => _role;
  Map<String, dynamic>? get permissions => _permissions;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isInitializing => _isInitializing;
  double get todaySales => _todaySales;
  int get lowStockCount => _lowStockCount;
  List<Map<String, dynamic>> get lowStockItems => _lowStockItems;
  int get transactionCount => _transactionCount;
  AppDatabase? get database => _db;
  PromotionService get promotionService => _promotionService;
  List<Category> get categories => _categories;
  List<Product> get products => _products;

  @override
  void dispose() {
    _salesSubscription?.cancel();
    _lowStockSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadInitialData() async {
    try {
      // 1. Load Store Info from Drift
      final stores = await (_db.select(_db.stores)..limit(1)).get();

      if (stores.isNotEmpty) {
        final store = stores.first;
        _storeId = store.id;
        _storeName = store.name;
        _storeLogo = store.logoUrl;
        _userName = store.adminName;
        _profileUrl = store.adminAvatar;
        _role = 'admin'; // Always admin in local offline mode
        _userId = 'local_admin';

        _userProfile = {
          'id': _userId,
          'full_name': _userName,
          'role': _role,
          'avatar_url': _profileUrl,
          'store_id': _storeId,
        };
      } else {
        // Create an initial default store if none exists
        const initialStoreId = 'default_store';
        await _db
            .into(_db.stores)
            .insert(
              StoresCompanion.insert(
                id: initialStoreId,
                name: const Value('Restoran Steak Asri'),
                adminName: const Value('Admin Asri'),
                createdAt: Value(DateTime.now()),
              ),
            );

        _storeId = initialStoreId;
        _storeName = 'Restoran Steak Asri';
        _userName = 'Admin Asri';
        _role = 'admin';
        _userId = 'local_admin';

        _userProfile = {
          'id': _userId,
          'full_name': _userName,
          'role': _role,
          'store_id': _storeId,
        };
      }

      if (_storeId != null) {
        _initStatsStreams();
        _categories = await (_db.select(
          _db.categories,
        )..where((t) => t.storeId.equals(_storeId!))).get();
        _products =
            await (_db.select(_db.products)
                  ..where((t) => t.storeId.equals(_storeId!))
                  ..where((t) => t.isDeleted.equals(false)))
                .get();
      }

      _isInitializing = false;
      notifyListeners();
    } catch (e) {
      debugPrint("AdminController: Error loading local data: $e");
      _isInitializing = false;
      notifyListeners();
    }
  }

  void _initStatsStreams() {
    if (_storeId == null) return;

    _salesSubscription?.cancel();
    _lowStockSubscription?.cancel();

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    // 1. Watch today's transactions
    _salesSubscription =
        (_db.select(_db.transactions)..where(
              (t) =>
                  t.storeId.equals(_storeId!) &
                  t.createdAt.isBiggerOrEqualValue(startOfToday),
            ))
            .watch()
            .listen((txs) {
              double total = 0;
              for (var tx in txs) {
                total += tx.totalAmount ?? 0;
              }
              _todaySales = total;
              _transactionCount = txs.length;
              notifyListeners();
            });

    // 2. Watch low stock products
    _lowStockSubscription =
        (_db.select(_db.products)
              ..where(
                (t) =>
                    t.storeId.equals(_storeId!) &
                    t.stockQuantity.isSmallerThanValue(5) &
                    t.isStockManaged.equals(true) &
                    t.isDeleted.equals(false),
              )
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.stockQuantity,
                  mode: OrderingMode.asc,
                ),
              ]))
            .watch()
            .listen((productsRaw) {
              _lowStockCount = productsRaw.length;
              _lowStockItems = productsRaw
                  .map(
                    (p) => {
                      'id': p.id,
                      'name': p.name,
                      'stock_quantity': p.stockQuantity,
                      'image_url': p.imageUrl,
                    },
                  )
                  .toList();
              notifyListeners();
            });
  }

  Future<void> fetchDashboardStats() async {
    // Legacy method, now handled by streams but keeping for compatibility
    _initStatsStreams();
  }

  Future<void> resetStore({bool deleteProducts = false}) async {
    if (_storeId == null) return;

    try {
      await _db.transaction(() async {
        debugPrint(
          "ResetStore: Deleting transactions for store $_storeId (DeleteProducts: $deleteProducts)",
        );

        // 1. Delete ALL Transaction Items (Foreign Key constraint should cascade, but manual for safety)
        // Ideally we should filter by transaction.store_id but for single store offline mode,
        // we can just delete all valid items or join.
        // For simplicity in this offline app, we'll delete items linked to this store's transactions.

        // Get transactions to delete first to get their IDs
        final txs = await (_db.select(
          _db.transactions,
        )..where((t) => t.storeId.equals(_storeId!))).get();
        final txIds = txs.map((t) => t.id).toList();

        if (txIds.isNotEmpty) {
          await (_db.delete(
            _db.transactionItems,
          )..where((t) => t.transactionId.isIn(txIds))).go();
        }

        // Delete Transactions
        await (_db.delete(
          _db.transactions,
        )..where((t) => t.storeId.equals(_storeId!))).go();

        // 2. Handle Products & Categories
        if (deleteProducts) {
          debugPrint("ResetStore: Deleting products and categories.");
          await (_db.delete(
            _db.products,
          )..where((t) => t.storeId.equals(_storeId!))).go();
          await (_db.delete(
            _db.categories,
          )..where((t) => t.storeId.equals(_storeId!))).go();
        } else {
          // Reset stock only
          debugPrint("ResetStore: Resetting stock to 0.");
          // Update all products for this store
          await (_db.update(_db.products)
                ..where((t) => t.storeId.equals(_storeId!)))
              .write(const ProductsCompanion(stockQuantity: Value(0)));
        }
      });

      // Force refresh of local data
      await loadInitialData();
      notifyListeners();
      debugPrint("ResetStore: Completed successfully.");
    } catch (e) {
      debugPrint("AdminController: Error resetting store: $e");
      rethrow;
    }
  }

  Future<void> updateProfile({String? name, String? avatarUrl}) async {
    if (_storeId == null) return;

    final updates = StoresCompanion(
      adminName: name != null ? Value(name) : const Value.absent(),
      adminAvatar: avatarUrl != null ? Value(avatarUrl) : const Value.absent(),
    );

    if (name != null || avatarUrl != null) {
      await (_db.update(
        _db.stores,
      )..where((t) => t.id.equals(_storeId!))).write(updates);
      await loadInitialData();
    }
  }

  Future<void> updateStoreBranding({String? name, String? logoUrl}) async {
    if (_storeId == null) return;

    final updates = StoresCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      logoUrl: logoUrl != null ? Value(logoUrl) : const Value.absent(),
    );

    if (name != null || logoUrl != null) {
      await (_db.update(
        _db.stores,
      )..where((t) => t.id.equals(_storeId!))).write(updates);
      await loadInitialData();
    }
  }

  Future<void> refreshProfile() async {
    await loadInitialData();
  }
}
