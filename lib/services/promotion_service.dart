import 'package:uuid/uuid.dart';
import 'app_database.dart';
import 'package:drift/drift.dart';

class PromotionService {
  final AppDatabase _db;

  PromotionService(this._db);

  // --- CRUD ---

  Future<List<Promotion>> getActivePromotions(String storeId) async {
    final now = DateTime.now();
    return await (_db.select(_db.promotions)
          ..where((t) => t.storeId.equals(storeId))
          ..where((t) => t.isActive.equals(true))
          ..where(
            (t) =>
                t.startDate.isNull() | t.startDate.isSmallerOrEqualValue(now),
          )
          ..where(
            (t) => t.endDate.isNull() | t.endDate.isBiggerOrEqualValue(now),
          ))
        .get();
  }

  Future<List<Promotion>> getAllPromotions(String storeId) async {
    return await (_db.select(_db.promotions)
          ..where((t) => t.storeId.equals(storeId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<void> createPromotion({
    required String name,
    required String type,
    String discountType = 'percentage',
    String? description,
    double? value,
    required String storeId,
    DateTime? startDate,
    DateTime? endDate,
    List<Map<String, dynamic>> items =
        const [], // {productId, categoryId, role, quantity}
  }) async {
    final promoId = const Uuid().v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      await _db
          .into(_db.promotions)
          .insert(
            PromotionsCompanion.insert(
              id: promoId,
              name: Value(name),
              type: type,
              discountType: Value(discountType),
              description: Value(description),
              value: Value(value),
              storeId: Value(storeId),
              startDate: Value(startDate),
              endDate: Value(endDate),
              createdAt: Value(now),
            ),
          );

      for (var item in items) {
        await _db
            .into(_db.promotionItems)
            .insert(
              PromotionItemsCompanion.insert(
                id: const Uuid().v4(),
                promotionId: Value(promoId),
                productId: Value(item['productId']),
                categoryId: Value(item['categoryId']),
                role: item['role'], // BUY, GET, TARGET
                quantity: Value(item['quantity'] ?? 1),
              ),
            );
      }
    });
  }

  Future<void> updatePromotionStatus(String id, bool isActive) async {
    await (_db.update(_db.promotions)..where((t) => t.id.equals(id))).write(
      PromotionsCompanion(isActive: Value(isActive)),
    );
  }

  Future<void> deletePromotion(String id) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.promotionItems,
      )..where((t) => t.promotionId.equals(id))).go();
      await (_db.delete(_db.promotions)..where((t) => t.id.equals(id))).go();
    });
  }

  // --- LOGIC ---

  /// Scans the cart and return a list of applied promotions and their total discount
  Future<Map<String, dynamic>> calculateDiscounts({
    required String storeId,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    // 1. Fetch active promotions
    final rawPromos = await getActivePromotions(storeId);
    double totalDiscount = 0;
    List<String> appliedPromoNames = [];

    // 2. Pair promos with their items to avoid repeated DB calls and allow sorting
    List<Map<String, dynamic>> promoWithItems = [];
    for (var promo in rawPromos) {
      final items = await (_db.select(
        _db.promotionItems,
      )..where((t) => t.promotionId.equals(promo.id))).get();
      promoWithItems.add({'promo': promo, 'items': items});
    }

    // 3. Sort: Specific (Category) first, then General (All Products)
    promoWithItems.sort((a, b) {
      final aItems = a['items'] as List<PromotionItem>;
      final bItems = b['items'] as List<PromotionItem>;

      if (aItems.isEmpty && bItems.isNotEmpty) {
        return 1; // a is general, b is specific
      }
      if (aItems.isNotEmpty && bItems.isEmpty) {
        return -1; // a is specific, b is general
      }
      return 0;
    });

    // To prevent stacking (one discount per item)
    final Set<String> globalAppliedCartIds = {};
    final Map<String, double> itemDiscounts = {};

    for (var entry in promoWithItems) {
      final promo = entry['promo'] as Promotion;
      final promoItems = entry['items'] as List<PromotionItem>;

      if (promo.type == 'discount' && promo.value != null) {
        final isPercentage = promo.discountType == 'percentage';
        final promoValue = promo.value!;

        // "Apply to All" if no targets specified
        final isApplyToAll = promoItems.isEmpty;

        if (isApplyToAll) {
          for (var cartItem in cartItems) {
            final String cartId = cartItem['cart_id'];
            if (globalAppliedCartIds.contains(cartId)) continue;

            _applyDiscount(
              cartItem,
              promoValue,
              isPercentage,
              promo.name ?? 'Promo',
              (disc) {
                if (disc > 0) {
                  globalAppliedCartIds.add(cartId);
                  itemDiscounts[cartId] = disc;
                  totalDiscount += disc;
                }
              },
              (name) {
                if (!appliedPromoNames.contains(name)) {
                  appliedPromoNames.add(name);
                }
              },
            );
          }
        } else {
          for (var pi in promoItems) {
            if (pi.role != 'TARGET') continue;

            for (var cartItem in cartItems) {
              final String cartId = cartItem['cart_id'];
              if (globalAppliedCartIds.contains(cartId)) continue;

              final Product p = cartItem['product'];
              bool match = false;

              // Check Product match
              if (pi.productId != null && pi.productId == p.id) {
                match = true;
              }
              // Check Category match
              else if (pi.categoryId != null && pi.categoryId == p.categoryId) {
                match = true;
              }

              if (match) {
                _applyDiscount(
                  cartItem,
                  promoValue,
                  isPercentage,
                  promo.name ?? 'Promo',
                  (disc) {
                    if (disc > 0) {
                      globalAppliedCartIds.add(cartId);
                      itemDiscounts[cartId] = disc;
                      totalDiscount += disc;
                    }
                  },
                  (name) {
                    if (!appliedPromoNames.contains(name)) {
                      appliedPromoNames.add(name);
                    }
                  },
                );
              }
            }
          }
        }
      }
    }

    return {
      'total_discount': totalDiscount,
      'promo_count': appliedPromoNames.length,
      'promo_names': appliedPromoNames,
      'applied_cart_ids': globalAppliedCartIds.toList(),
      'item_discounts': itemDiscounts,
    };
  }

  void _applyDiscount(
    Map<String, dynamic> cartItem,
    double promoValue,
    bool isPercentage,
    String promoName,
    Function(double) onDiscountAdded,
    Function(String) onPromoApplied,
  ) {
    final qty = cartItem['quantity'] as int;
    final price = cartItem['price'] as double;

    double itemDiscount = 0;
    if (isPercentage) {
      itemDiscount = (price * (promoValue / 100)) * qty;
    } else {
      itemDiscount = promoValue * qty;
    }

    onDiscountAdded(itemDiscount);
    onPromoApplied(promoName);
  }
}
