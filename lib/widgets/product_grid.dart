import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import '../services/isar_service.dart';
import '../models/local/local_product.dart';

class ProductGrid extends StatelessWidget {
  final String storeId;
  final String searchQuery;
  final String? categoryFilter;
  final String filterType; // "All", "Popular", "Recent"
  final Function(Map<String, dynamic>) onItemTap;
  final Widget Function(BuildContext, Map<String, dynamic>)? extraInfoBuilder;
  final Widget Function(BuildContext, Map<String, dynamic>)? actionBuilder;

  const ProductGrid({
    super.key,
    required this.storeId,
    this.searchQuery = "",
    this.categoryFilter,
    this.filterType = "All",
    required this.onItemTap,
    this.extraInfoBuilder,
    this.actionBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if Dark Mode
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final textHeading = isDark ? Colors.white : const Color(0xFF2D3436);

    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final isar = IsarService().isar;

    return StreamBuilder<List<LocalProduct>>(
      stream: isar.localProducts
          .filter()
          .storeIdEqualTo(storeId)
          .watch(fireImmediately: true),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        var localProducts = snapshot.data!;

        // 1. Filter localProducts
        var filteredProducts = localProducts.where((p) {
          // Categories
          if (categoryFilter != null && categoryFilter != "Semua") {
            if (p.categoryId != categoryFilter) return false;
          }

          // Search
          if (searchQuery.isNotEmpty) {
            final query = searchQuery.toLowerCase();
            if (!p.name.toLowerCase().contains(query) &&
                !(p.sku ?? '').toLowerCase().contains(query)) {
              return false;
            }
          }

          return true;
        }).toList();

        // 2. Sort
        if (filterType == "Recent") {
          filteredProducts.sort(
            (a, b) => (b.lastUpdated ?? DateTime(2000)).compareTo(
              a.lastUpdated ?? DateTime(2000),
            ),
          );
        } else if (filterType == "Popular") {
          filteredProducts.sort(
            (a, b) => b.stockQuantity.compareTo(a.stockQuantity),
          );
        }

        if (filteredProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 60,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 10),
                Text(
                  searchQuery.isEmpty
                      ? "Belum ada produk."
                      : "Produk tidak ditemukan.",
                  style: GoogleFonts.inter(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        // 3. Convert back to Map for the UI
        final products = filteredProducts.map((p) {
          return {
                'id': p.supabaseId,
                'name': p.name,
                'sale_price': p.salePrice,
                'buy_price': p
                    .basePrice, // Use basePrice as original buy price for discount calculation
                'stock_quantity': p.stockQuantity,
                'is_stock_managed': p.isStockManaged,
                'image_url': p.imageUrl,
                'sku': p.sku,
                'category_id': p.categoryId,
                'store_id': p.storeId,
              }
              as Map<String, dynamic>;
        }).toList();

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            childAspectRatio: 0.6,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: products.length,
          itemBuilder: (context, i) {
            final p = products[i];

            // Stock Logic
            final bool isStockManaged = p['is_stock_managed'] as bool? ?? true;
            final int stockQty = p['stock_quantity'] as int? ?? 0;
            final bool isOutOfStock = isStockManaged && stockQty <= 0;

            final num originalPrice = p['buy_price'] as num? ?? 0;
            final num salePrice = p['sale_price'] as num? ?? 0;
            final bool hasDiscount = originalPrice > salePrice;

            return Opacity(
              opacity: isOutOfStock ? 0.6 : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: isOutOfStock ? null : () => onItemTap(p),
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Section
                      Expanded(
                        flex: 4,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                                color: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[50],
                                image: p['image_url'] != null
                                    ? DecorationImage(
                                        image: NetworkImage(
                                          p['image_url'] as String,
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: p['image_url'] == null
                                  ? Center(
                                      child: Icon(
                                        Icons.fastfood_rounded,
                                        size: 40,
                                        color: isDark
                                            ? Colors.grey[600]
                                            : Colors.orange[100],
                                      ),
                                    )
                                  : null,
                            ),
                            if (hasDiscount)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${((originalPrice - salePrice) / originalPrice * 100).toInt()}%",
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Info Section
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (p['name'] as String?) ?? 'Tanpa Nama',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textHeading,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currencyFormat.format(salePrice),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  if (hasDiscount)
                                    Text(
                                      currencyFormat.format(originalPrice),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                ],
                              ),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (isStockManaged)
                                    Text(
                                      isOutOfStock
                                          ? "Habis"
                                          : "Stok: $stockQty",
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: isOutOfStock
                                            ? Colors.red
                                            : Colors.grey[600],
                                        fontWeight: isOutOfStock
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    )
                                  else
                                    const SizedBox(),
                                  if (actionBuilder != null)
                                    actionBuilder!(context, p)
                                  else
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: isOutOfStock
                                            ? Colors.grey[300]
                                            : primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
