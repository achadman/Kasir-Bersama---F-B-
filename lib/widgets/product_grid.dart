import 'package:flutter/material.dart';
import '../services/platform/file_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_database.dart';

class ProductGrid extends StatelessWidget {
  final String storeId;
  final String searchQuery;
  final String? categoryFilter;
  final String filterType; // "All", "Popular", "Recent"
  final bool isGridView;
  final Function(Product) onItemTap;
  final Widget Function(BuildContext, Product)? extraInfoBuilder;
  final Widget Function(BuildContext, Product)? actionBuilder;

  const ProductGrid({
    super.key,
    required this.storeId,
    this.searchQuery = "",
    this.categoryFilter,
    this.filterType = "All",
    this.isGridView = true,
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

    final db = Provider.of<AppDatabase>(context);

    // Filter using Drift Query DSL
    final query = db.select(db.products)
      ..where((t) => t.storeId.equals(storeId))
      ..where((t) => t.isDeleted.equals(false));

    if (categoryFilter != null && categoryFilter != "Semua") {
      query.where((t) => t.categoryId.equals(categoryFilter!));
    }

    return StreamBuilder<List<Product>>(
      stream: query.watch(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        var localProducts = snapshot.data!;

        // 1. Client-side search (Drift can do this too, but let's keep logic similar for now)
        var filteredProducts = localProducts.where((p) {
          if (searchQuery.isNotEmpty) {
            final q = searchQuery.toLowerCase();
            final name = (p.name ?? '').toLowerCase();
            final sku = (p.sku ?? '').toLowerCase();
            if (!name.contains(q) && !sku.contains(q)) {
              return false;
            }
          }
          return true;
        }).toList();

        // 2. Sort
        if (filterType == "Recent") {
          filteredProducts.sort((a, b) {
            final da = a.lastUpdated ?? DateTime(2000);
            final db = b.lastUpdated ?? DateTime(2000);
            return db.compareTo(da);
          });
        } else if (filterType == "Popular") {
          filteredProducts.sort(
            (a, b) => (b.stockQuantity ?? 0).compareTo(a.stockQuantity ?? 0),
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

        final products = filteredProducts;

        if (isGridView) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: isWide ? 160 : 200,
                  childAspectRatio: isWide ? 0.7 : 0.6,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: products.length,
                itemBuilder: (context, i) {
                  final p = products[i];
                  return _buildGridItem(context, p, isDark, textHeading, primaryColor, isWide);
                },
              );
            },
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            itemCount: products.length,
            itemBuilder: (context, i) {
              final p = products[i];
              return _buildListItem(context, p, isDark, textHeading, primaryColor);
            },
          );
        }
      },
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    Product p,
    bool isDark,
    Color textHeading,
    Color primaryColor,
    bool isWide,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Stock Logic
    final bool isStockManaged = p.isStockManaged;
    final int stockQty = p.stockQuantity ?? 0;
    final bool isOutOfStock = isStockManaged && stockQty <= 0;

    return Opacity(
      opacity: isOutOfStock ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(isWide ? 12 : 20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: isOutOfStock ? null : () => onItemTap(p),
          borderRadius: BorderRadius.circular(isWide ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    _buildImage(p, isDark, isWide),
                    _buildPromoBadge(context, p, p.id),
                  ],
                ),
              ),

              // Info Section
              Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsets.all(isWide ? 8 : 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name ?? 'Tanpa Nama',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: isWide ? 12 : 14,
                              fontWeight: FontWeight.w600,
                              color: textHeading,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormat.format(p.salePrice ?? 0),
                            style: GoogleFonts.inter(
                              fontSize: isWide ? 12 : 14,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (isStockManaged)
                            Text(
                              isOutOfStock ? "Habis" : "Stok: $stockQty",
                              style: GoogleFonts.inter(
                                fontSize: isWide ? 9 : 10,
                                color: isOutOfStock ? Colors.red : Colors.grey[600],
                                fontWeight: isOutOfStock
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            )
                          else
                            const SizedBox(),
                          _buildActionButton(context, p, isOutOfStock, primaryColor, isWide),
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
  }

  Widget _buildListItem(
    BuildContext context,
    Product p,
    bool isDark,
    Color textHeading,
    Color primaryColor,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final bool isStockManaged = p.isStockManaged;
    final int stockQty = p.stockQuantity ?? 0;
    final bool isOutOfStock = isStockManaged && stockQty <= 0;

    return Opacity(
      opacity: isOutOfStock ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: isOutOfStock ? null : () => onItemTap(p),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Image
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark ? Colors.grey[800] : Colors.grey[50],
                    image: p.imageUrl != null
                        ? DecorationImage(
                            image: FileManager().getImageProvider(p.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: p.imageUrl == null
                      ? Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey[400],
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name ?? 'Tanpa Nama',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textHeading,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            currencyFormat.format(p.salePrice ?? 0),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          if (isStockManaged) ...[
                            const SizedBox(width: 12),
                            Text(
                              isOutOfStock ? "Habis" : "Stok: $stockQty",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isOutOfStock ? Colors.red : Colors.grey[600],
                                fontWeight: isOutOfStock
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Action
                _buildActionButton(context, p, isOutOfStock, primaryColor, false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(Product p, bool isDark, bool isWide) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(isWide ? 12 : 20)),
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        image: p.imageUrl != null
            ? DecorationImage(
                image: FileManager().getImageProvider(p.imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
    );
  }

  Widget _buildPromoBadge(
    BuildContext context,
    Product p,
    String productId,
  ) {
    final db = Provider.of<AppDatabase>(context);
    return Positioned(
      top: 10,
      left: 10,
      child: StreamBuilder<List<PromotionItem>>(
        stream: (db.select(db.promotionItems)..where((t) => t.productId.equals(productId))).watch(),
        builder: (context, promoSnapshot) {
          if (promoSnapshot.hasData && promoSnapshot.data!.isNotEmpty) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                ],
              ),
              child: Text(
                "PROMO",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    Product p,
    bool isOutOfStock,
    Color primaryColor,
    bool isWide,
  ) {
    if (actionBuilder != null) return actionBuilder!(context, p);

    return Container(
      width: isWide ? 26 : 32,
      height: isWide ? 26 : 32,
      decoration: BoxDecoration(
        color: isOutOfStock ? Colors.grey[300] : primaryColor,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.add_rounded, color: Colors.white, size: isWide ? 16 : 20),
    );
  }
}
