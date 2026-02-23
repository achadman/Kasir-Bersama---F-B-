import 'package:flutter/material.dart';
import '../services/platform/file_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_database.dart';

class ProductGrid extends StatefulWidget {
  final String storeId;
  final String searchQuery;
  final String? categoryFilter;
  final String filterType; // "All", "Popular", "Recent"
  final Function(Product) onItemTap;
  final Widget Function(BuildContext, Product)? extraInfoBuilder;
  final Widget Function(BuildContext, Product)? actionBuilder;

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
  State<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  List<Product>? _previousProducts;

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
      ..where((t) => t.storeId.equals(widget.storeId))
      ..where((t) => t.isDeleted.equals(false));

    if (widget.categoryFilter != null && widget.categoryFilter != "Semua") {
      query.where((t) => t.categoryId.equals(widget.categoryFilter!));
    }

    return StreamBuilder<List<Product>>(
      stream: query.watch(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (snapshot.hasData) {
          _previousProducts = snapshot.data;
        }

        // Use cached products if snapshot is still loading
        var localProducts = snapshot.data ?? _previousProducts;

        if (localProducts == null) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        // 1. Client-side search
        var filteredProducts = localProducts.where((p) {
          if (widget.searchQuery.isNotEmpty) {
            final q = widget.searchQuery.toLowerCase();
            final name = (p.name ?? '').toLowerCase();
            final sku = (p.sku ?? '').toLowerCase();
            if (!name.contains(q) && !sku.contains(q)) {
              return false;
            }
          }
          return true;
        }).toList();

        // 2. Sort
        if (widget.filterType == "Recent") {
          filteredProducts.sort((a, b) {
            final da = a.lastUpdated ?? DateTime(2000);
            final db = b.lastUpdated ?? DateTime(2000);
            return db.compareTo(da);
          });
        } else if (widget.filterType == "Popular") {
          filteredProducts.sort(
            (a, b) => (b.stockQuantity ?? 0).compareTo(a.stockQuantity ?? 0),
          );
        }

        if (filteredProducts.isEmpty && widget.searchQuery.isNotEmpty) {
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
                  "Produk tidak ditemukan.",
                  style: GoogleFonts.inter(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final products = filteredProducts;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: GridView.builder(
            key: ValueKey("${widget.categoryFilter}_${widget.searchQuery}"),
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
              final bool isStockManaged = p.isStockManaged;
              final int stockQty = p.stockQuantity ?? 0;
              final bool isOutOfStock = isStockManaged && stockQty <= 0;

              // Base price for discount display
              final double salePrice = p.salePrice ?? 0;

              return Opacity(
                opacity: isOutOfStock ? 0.6 : 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: isOutOfStock ? null : () => widget.onItemTap(p),
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
                                  image: p.imageUrl != null
                                      ? DecorationImage(
                                          image: FileManager().getImageProvider(
                                            p.imageUrl!,
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                              ),
                              // Promo Badge
                              StreamBuilder<List<PromotionItem>>(
                                stream:
                                    (db.select(db.promotionItems)..where(
                                          (t) => t.productId.equals(p.id),
                                        ))
                                        .watch(),
                                builder: (context, promoSnapshot) {
                                  if (promoSnapshot.hasData &&
                                      promoSnapshot.data!.isNotEmpty) {
                                    return Positioned(
                                      top: 10,
                                      left: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.2,
                                              ),
                                              blurRadius: 4,
                                            ),
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
                                      ),
                                    );
                                  }
                                  return const SizedBox();
                                },
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
                                      p.name ?? 'Tanpa Nama',
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
                                    if (widget.actionBuilder != null)
                                      widget.actionBuilder!(context, p)
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
          ),
        );
      },
    );
  }
}
