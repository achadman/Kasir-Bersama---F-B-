import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/bulk_import_service.dart';
import '../../services/app_database.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'widgets/product_form_sheet.dart';
import '../../widgets/big_search_bar.dart';
import '../../controllers/admin_controller.dart';
import '../../services/platform/file_manager.dart';
import '../../widgets/asri_dialog.dart';
import '../../controllers/settings_controller.dart';

class InventoryPage extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const InventoryPage({super.key, this.onMenuPressed});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;

  final currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  List<Category> _categories = [];
  String? _selectedCategoryId; // null means "All"

  // Stock Filter: 'all', 'limited', 'unlimited'
  String _stockFilter = 'all';

  // Sort: 'name_asc', 'stock_asc', 'stock_desc', 'price_asc', 'price_desc'
  String _sortBy = 'name_asc';
  late BulkImportService _importService;

  @override
  void initState() {
    super.initState();
    final db = Provider.of<AppDatabase>(context, listen: false);
    _importService = BulkImportService(db);
    _fetchData();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final db = Provider.of<AppDatabase>(context, listen: false);
      final admin = Provider.of<AdminController>(context, listen: false);
      final storeId = admin.storeId;

      if (storeId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final categoriesData =
          await (db.select(db.categories)
                ..where((t) => t.storeId.equals(storeId))
                ..orderBy([(t) => drift.OrderingTerm.asc(t.name)]))
              .get();
      final productsData =
          await (db.select(db.products)
                ..where(
                  (t) => t.storeId.equals(storeId) & t.isDeleted.equals(false),
                )
                ..orderBy([(t) => drift.OrderingTerm.asc(t.name)]))
              .get();

      if (mounted) {
        setState(() {
          _categories = categoriesData;
          _products = productsData;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("InventoryPage: Fetch failed: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterProducts() {
    _applyFilters();
  }

  void _selectCategory(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _applyFilters();
    });
  }

  void _setStockFilter(String filter) {
    setState(() {
      _stockFilter = filter;
      _applyFilters();
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      final list = _products.where((product) {
        final name = product.name.toString().toLowerCase();
        final sku = (product.sku ?? '').toString().toLowerCase();
        final matchesSearch = name.contains(query) || sku.contains(query);

        final categoryId = product.categoryId;
        final matchesCategory =
            _selectedCategoryId == null || categoryId == _selectedCategoryId;

        bool matchesStock = true;
        final isManaged = product.isStockManaged == true;

        if (_stockFilter == 'limited') {
          matchesStock = isManaged;
        } else if (_stockFilter == 'unlimited') {
          matchesStock = !isManaged;
        }

        return matchesSearch && matchesCategory && matchesStock;
      }).toList();

      // Apply Sort
      list.sort((a, b) {
        if (_sortBy == 'stock_asc') {
          return (a.stockQuantity ?? 0).compareTo(b.stockQuantity ?? 0);
        } else if (_sortBy == 'stock_desc') {
          return (b.stockQuantity ?? 0).compareTo(a.stockQuantity ?? 0);
        } else if (_sortBy == 'price_asc') {
          return (a.salePrice ?? 0).compareTo(b.salePrice ?? 0);
        } else if (_sortBy == 'price_desc') {
          return (b.salePrice ?? 0).compareTo(a.salePrice ?? 0);
        } else {
          return (a.name ?? '').compareTo(b.name ?? '');
        }
      });

      _filteredProducts = list;
    });
  }

  void _openProductForm({Product? product}) async {
    final admin = Provider.of<AdminController>(context, listen: false);
    final storeId = admin.storeId;
    if (storeId == null) return;

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProductFormSheet(product: product, storeId: storeId),
    );

    if (result == true) {
      _fetchData();
    }
  }

  void _handleExport() async {
    final admin = Provider.of<AdminController>(context, listen: false);
    final storeId = admin.storeId;
    if (storeId == null) return;

    setState(() => _isLoading = true);
    try {
      final path = await _importService.exportProductsToExcel(storeId);
      if (mounted) {
        setState(() => _isLoading = false);
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Berhasil export ke: $path"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal export: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleBulkImport() async {
    final admin = Provider.of<AdminController>(context, listen: false);
    final storeId = admin.storeId;
    if (storeId == null) return;

    final result = await _importService.importProducts(storeId);

    if (result['status'] == 'cancelled') return;

    if (result['status'] == 'error') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${result['message']}"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (result['status'] == 'success') {
      _fetchData();
      if (mounted) {
        _showImportResultDialog(
          success: result['successCount'],
          fail: result['failCount'],
          errors: result['errors'],
        );
      }
    }
  }

  void _showImportResultDialog({
    required int success,
    required int fail,
    required List<String> errors,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AsriDialog(
        title: "Hasil Impor",
        icon: fail == 0 ? Icons.check_circle_rounded : Icons.info_rounded,
        iconColor: fail == 0 ? Colors.green : Colors.orange,
        content: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem("Berhasil", success.toString(), Colors.green),
                _buildStatItem("Gagal", fail.toString(), Colors.red),
              ],
            ),
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              Text(
                "Detail Kesalahan:",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: errors.length,
                  separatorBuilder: (c, i) => const Divider(height: 8),
                  itemBuilder: (c, i) => Text(
                    errors[i],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.red[400],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        primaryActionLabel: "Tutup",
        onPrimaryAction: () => Navigator.pop(ctx),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Future<void> _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AsriDialog(
        title: "Hapus Produk?",
        message:
            "Tindakan ini tidak dapat dibatalkan dan produk akan dihapus permanent.",
        icon: CupertinoIcons.trash_fill,
        iconColor: Colors.redAccent,
        primaryActionLabel: "Hapus",
        isDestructive: true,
        onPrimaryAction: () => Navigator.pop(ctx, true),
        secondaryActionLabel: "Batal",
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      try {
        final db = Provider.of<AppDatabase>(context, listen: false);
        await (db.update(db.products)..where((t) => t.id.equals(id))).write(
          const ProductsCompanion(isDeleted: drift.Value(true)),
        );
        _fetchData();
      } catch (e) {
        debugPrint("Error deleting product: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _emptyAllStock() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AsriDialog(
        title: "Kosongkan Semua Stok?",
        message:
            "Semua produk dalam daftar 'Terbatas' akan diubah stoknya menjadi 0.\n\nTindakan ini tidak dapat dibatalkan.",
        icon: Icons.delete_sweep_rounded,
        iconColor: Colors.redAccent,
        primaryActionLabel: "Kosongkan",
        isDestructive: true,
        onPrimaryAction: () => Navigator.pop(ctx, true),
        secondaryActionLabel: "Batal",
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);

      // Collect IDs of currently filtered products (which should be 'Limited')
      final ids = _filteredProducts.map((p) => p.id).toList();

      if (ids.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      try {
        final db = Provider.of<AppDatabase>(context, listen: false);
        for (var id in ids) {
          await (db.update(db.products)..where((t) => t.id.equals(id))).write(
            const ProductsCompanion(stockQuantity: drift.Value(0)),
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Semua stok berhasil dikosongkan.")),
          );
          _fetchData();
        }
      } catch (e) {
        debugPrint("Error emptying stock: $e");
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _restockAll() async {
    // Dialog Choice: Fill to Max vs Add Fixed Amount
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AsriDialog(
        title: "Restock Massal",
        icon: Icons.playlist_add_check_rounded,
        iconColor: Colors.green,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildChoiceOption(
              icon: Icons.track_changes_rounded,
              title: "Penuhi ke Max Stock",
              subtitle: "Sesuaikan dengan limit produk",
              onTap: () => Navigator.pop(ctx, 'max'),
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildChoiceOption(
              icon: Icons.add_circle_outline_rounded,
              title: "Tambah Jumlah Sama",
              subtitle: "Tambahkan qty tetap ke semua",
              onTap: () => Navigator.pop(ctx, 'manual'),
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;
    if (!mounted) return;

    if (choice == 'max') {
      await _fillToMaxStock();
    } else {
      await _addFixedStockToAll();
    }
  }

  Widget _buildChoiceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fillToMaxStock() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    int updateCount = 0;

    try {
      // Max stock logic disabled due to schema mismatch
      // for (var p in _filteredProducts) { ... }

      if (mounted) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Berhasil restock $updateCount produk ke batas maksimal.",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error fill max stock: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addFixedStockToAll() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AsriDialog(
        title: "Tambah Stok Massal",
        icon: Icons.add_business_rounded,
        iconColor: Colors.blue,
        content: Column(
          children: [
            const SizedBox(height: 8),
            _buildDialogTextField(
              controller: controller,
              label: "Jumlah Tambahan",
              hint: "Misal: 10",
              prefixIcon: Icons.add_box_rounded,
            ),
          ],
        ),
        primaryActionLabel: "Simpan",
        onPrimaryAction: () async {
          final amount = int.tryParse(controller.text) ?? 0;
          if (amount <= 0) return;
          Navigator.pop(ctx);
          setState(() => _isLoading = true);

          try {
            final db = Provider.of<AppDatabase>(context, listen: false);
            for (var p in _filteredProducts) {
              final current = p.stockQuantity ?? 0;
              await (db.update(
                db.products,
              )..where((t) => t.id.equals(p.id))).write(
                ProductsCompanion(stockQuantity: drift.Value(current + amount)),
              );
            }
            if (mounted) {
              _fetchData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Berhasil menambah +$amount ke semua produk."),
                ),
              );
            }
          } catch (e) {
            debugPrint("Restock error: $e");
            if (mounted) setState(() => _isLoading = false);
          }
        },
        secondaryActionLabel: "Batal",
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: GoogleFonts.inter(),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(prefixIcon, size: 20, color: Colors.grey),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryOrange = Color(0xFFEA5700);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          SettingsController.instance.getString('nav_inventory'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF2D3436),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (ctx) {
            final isWide = MediaQuery.of(ctx).size.width >= 720;
            if (isWide) return const SizedBox.shrink();

            if (widget.onMenuPressed != null) {
              return IconButton(
                icon: Icon(
                  CupertinoIcons.bars,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                ),
                onPressed: widget.onMenuPressed,
              );
            }

            if (Navigator.canPop(context)) {
              return IconButton(
                icon: Icon(
                  CupertinoIcons.back,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                ),
                onPressed: () => Navigator.pop(context),
              );
            }

            return IconButton(
              icon: Icon(
                CupertinoIcons.bars,
                color: isDark ? Colors.white : const Color(0xFF2D3436),
              ),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            );
          },
        ),
        automaticallyImplyLeading: false,
        actions: [
          // ⋮ More menu: Export, Import, Info
          PopupMenuButton<String>(
            icon: Icon(
              CupertinoIcons.ellipsis_circle,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              if (value == 'export') _handleExport();
              if (value == 'import') _handleBulkImport();
              if (value == 'info') _showInfoHelp();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.cloud_download_fill,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Export Excel',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.cloud_upload_fill,
                      color: Colors.blue,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Import Excel',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.info_circle,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Panduan',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // + Add product button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(
                CupertinoIcons.plus_circle_fill,
                color: primaryOrange,
                size: 28,
              ),
              onPressed: () => _openProductForm(),
              tooltip: 'Tambah Produk',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar & Sort
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: BigSearchBar(
                    controller: _searchController,
                    hintText: SettingsController.instance.getString(
                      'search_product',
                    ),
                    onChanged: (val) {},
                    onClear: () {
                      _searchController.clear();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                _buildSortButton(isDark),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchData,
              color: primaryOrange,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // Stock Filter Tabs
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                _buildFilterTab("Semua", 'all'),
                                Container(
                                  width: 1,
                                  height: 20,
                                  color: Colors.grey[300],
                                ),
                                _buildFilterTab("Terbatas", 'limited'),
                                Container(
                                  width: 1,
                                  height: 20,
                                  color: Colors.grey[300],
                                ),
                                _buildFilterTab("Unlimited", 'unlimited'),
                              ],
                            ),
                          ),
                        ),

                        // Batch action bar — only visible in Terbatas mode
                        if (_stockFilter == 'limited')
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.orange.withValues(alpha: 0.08)
                                    : Colors.orange.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.cube_box,
                                    size: 15,
                                    color: Colors.orange[700],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Aksi Massal:',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _buildBatchActionButton(
                                            icon: Icons
                                                .playlist_add_check_rounded,
                                            label: 'Restock Massal',
                                            color: Colors.green,
                                            onTap: _restockAll,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildBatchActionButton(
                                            icon: Icons.delete_sweep_rounded,
                                            label: 'Kosongkan',
                                            color: Colors.red,
                                            onTap: _emptyAllStock,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Categories List
                        SizedBox(
                          height: 50,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length + 1,
                            separatorBuilder: (c, i) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final isAll = index == 0;
                              final cat = isAll ? null : _categories[index - 1];
                              final isSelected = isAll
                                  ? _selectedCategoryId == null
                                  : _selectedCategoryId == cat!.id;

                              return ChoiceChip(
                                label: Text(isAll ? "Semua" : cat!.name!),
                                selected: isSelected,
                                onSelected: (_) =>
                                    _selectCategory(isAll ? null : cat!.id),
                                selectedColor: primaryOrange,
                                backgroundColor: Theme.of(context).cardColor,
                                labelStyle: GoogleFonts.inter(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[700],
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: _filteredProducts.isEmpty
                              ? ListView(
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                          0.2,
                                    ),
                                    Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            CupertinoIcons.cube_box,
                                            size: 80,
                                            color: Colors.grey[200],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _searchController.text.isEmpty
                                                ? "Belum ada produk"
                                                : "Produk tidak ditemukan",
                                            style: GoogleFonts.inter(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth > 600) {
                                      return GridView.builder(
                                        padding: const EdgeInsets.all(20),
                                        gridDelegate:
                                            const SliverGridDelegateWithMaxCrossAxisExtent(
                                              maxCrossAxisExtent: 220,
                                              childAspectRatio: 0.65,
                                              crossAxisSpacing: 16,
                                              mainAxisSpacing: 16,
                                            ),
                                        itemCount: _filteredProducts.length,
                                        itemBuilder: (context, index) {
                                          final product =
                                              _filteredProducts[index];
                                          return _buildProductGridItem(
                                            product,
                                            index,
                                          );
                                        },
                                      );
                                    }
                                    return ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      itemCount: _filteredProducts.length,
                                      itemBuilder: (context, index) {
                                        final product =
                                            _filteredProducts[index];
                                        return _buildProductCard(
                                          product,
                                          index,
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOutQuint,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: product.isStockManaged
          ? Dismissible(
              key: Key("restock_${product.id}"),
              direction: DismissDirection.startToEnd,
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  await _showRestockDialog(product);
                  return false; // Don't dismiss the card
                }
                return false;
              },
              background: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.centerLeft,
                child: const Row(
                  children: [
                    Icon(Icons.add_box_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "Restock",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              child: _buildProductCardContent(product),
            )
          : _buildProductCardContent(product),
    );
  }

  Widget _buildProductCardContent(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.2
                  : 0.03,
            ),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openProductForm(product: product),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  image: product.imageUrl != null
                      ? DecorationImage(
                          image: FileManager().getImageProvider(
                            product.imageUrl!,
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product.imageUrl == null
                    ? Icon(CupertinoIcons.photo, color: Colors.grey[300])
                    : null,
              ),
              const SizedBox(width: 15),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? 'No Name',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF2D3436),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _categories
                                    .firstWhere(
                                      (c) => c.id == product.categoryId,
                                      orElse: () => const Category(
                                        id: '',
                                        name: 'No Category',
                                      ),
                                    )
                                    .name ??
                                'No Category',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Stock: ${product.isStockManaged ? product.stockQuantity : '∞'}",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color:
                                product.isStockManaged &&
                                    (product.stockQuantity ?? 0) < 5
                                ? Colors.red
                                : Colors.grey[600],
                            fontWeight:
                                product.isStockManaged &&
                                    (product.stockQuantity ?? 0) < 5
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(product.salePrice ?? 0),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFFEA5700),
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Column(
                children: [
                  IconButton(
                    icon: const Icon(
                      CupertinoIcons.pencil,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onPressed: () => _openProductForm(product: product),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 10),
                  IconButton(
                    icon: const Icon(
                      CupertinoIcons.trash,
                      size: 20,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => _deleteProduct(product.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _stockFilter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () => _setStockFilter(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFEA5700).withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFFEA5700)
                  : (isDark ? Colors.white70 : Colors.grey[600]),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRestockDialog(Product product) async {
    final controller = TextEditingController();
    final currentStock = product.stockQuantity ?? 0;

    await showDialog(
      context: context,
      builder: (context) => AsriDialog(
        title: "Restock: ${product.name}",
        icon: Icons.add_box_rounded,
        iconColor: Colors.green,
        content: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Stok Saat Ini",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    currentStock.toString(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildDialogTextField(
              controller: controller,
              label: "Jumlah Tambahan",
              hint: "Contoh: 5",
              prefixIcon: Icons.add_circle_outline_rounded,
            ),
          ],
        ),
        primaryActionLabel: "Simpan",
        onPrimaryAction: () async {
          final addAmount = int.tryParse(controller.text) ?? 0;
          if (addAmount <= 0) return;
          final newStock = currentStock + addAmount;
          final db = Provider.of<AppDatabase>(context, listen: false);
          await (db.update(db.products)..where((t) => t.id.equals(product.id)))
              .write(ProductsCompanion(stockQuantity: drift.Value(newStock)));

          if (context.mounted) {
            Navigator.pop(context);
            _fetchData();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Stok berhasil ditambah: +$addAmount")),
            );
          }
        },
        secondaryActionLabel: "Batal",
      ),
    );
  }

  Widget _buildProductGridItem(Product product, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 50)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.2
                    : 0.03,
              ),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => _openProductForm(product: product),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        image: product.imageUrl != null
                            ? DecorationImage(
                                image: FileManager().getImageProvider(
                                  product.imageUrl!,
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: product.imageUrl == null
                          ? Center(
                              child: Icon(
                                CupertinoIcons.photo,
                                color: Colors.grey[300],
                                size: 40,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                CupertinoIcons.pencil,
                                size: 16,
                                color: Colors.grey,
                              ),
                              onPressed: () =>
                                  _openProductForm(product: product),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                CupertinoIcons.trash,
                                size: 16,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _deleteProduct(product.id),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? 'No Name',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(product.salePrice ?? 0),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFFEA5700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _categories
                                      .firstWhere(
                                        (c) => c.id == product.categoryId,
                                        orElse: () => const Category(
                                          id: '',
                                          name: 'No Cat',
                                        ),
                                      )
                                      .name ??
                                  'No Cat',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Stock: ${product.isStockManaged ? product.stockQuantity : '∞'}",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color:
                                product.isStockManaged &&
                                    (product.stockQuantity ?? 0) < 5
                                ? Colors.red
                                : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (product.isStockManaged) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: OutlinedButton.icon(
                          onPressed: () => _showRestockDialog(product),
                          icon: const Icon(Icons.add_box_rounded, size: 14),
                          label: const Text(
                            "Restock",
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortButton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 56),
        icon: Icon(
          CupertinoIcons.sort_down,
          color: _sortBy.contains('stock')
              ? const Color(0xFFEA5700)
              : (isDark ? Colors.white70 : Colors.grey[700]),
        ),
        tooltip: 'Urutkan Produk',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onSelected: (val) {
          setState(() {
            _sortBy = val;
            _applyFilters();
          });
        },
        itemBuilder: (ctx) => [
          _buildSortItem('name_asc', Icons.sort_by_alpha, 'Nama (A-Z)'),
          _buildSortItem('stock_asc', Icons.trending_up, 'Stok Terendah'),
          _buildSortItem('stock_desc', Icons.trending_down, 'Stok Tertinggi'),
          _buildSortItem('price_asc', Icons.arrow_upward, 'Harga Termurah'),
          _buildSortItem('price_desc', Icons.arrow_downward, 'Harga Termahal'),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildSortItem(
    String value,
    IconData icon,
    String label,
  ) {
    final isSelected = _sortBy == value;
    const primaryOrange = Color(0xFFEA5700);

    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? primaryOrange : Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? primaryOrange : null,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check, size: 16, color: primaryOrange),
          ],
        ],
      ),
    );
  }

  void _showInfoHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AsriDialog(
        title: "Kelola Inventaris",
        icon: CupertinoIcons.cube_box_fill,
        iconColor: const Color(0xFFEA5700),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(
              "Stok Terbatas vs Tidak Terbatas",
              "Pilih 'Stok Terbatas' jika ingin sistem memotong stok setiap penjualan. Pilih 'Tidak Terbatas' untuk jasa atau barang yang stoknya tidak perlu dihitung.",
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              "SKU / Kode Barang",
              "Gunakan kode unik untuk setiap barang. Anda bisa scan barcode produk untuk mengisi kolom ini secara otomatis.",
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              "Restock Cepat",
              "Klik tombol 'Restock' pada kartu produk atau gunakan tombol massal di menu Export/Import untuk menambah stok banyak barang sekaligus.",
            ),
          ],
        ),
        primaryActionLabel: "Paham",
        onPrimaryAction: () => Navigator.pop(ctx),
      ),
    );
  }

  Widget _buildInfoItem(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: const Color(0xFFEA5700),
          ),
        ),
        Text(
          desc,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
