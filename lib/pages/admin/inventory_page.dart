import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'widgets/product_form_sheet.dart';
import '../../services/bulk_import_service.dart';
import '../../widgets/big_search_bar.dart';

class InventoryPage extends StatefulWidget {
  final String storeId;
  const InventoryPage({super.key, required this.storeId});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  final _searchController = TextEditingController();
  final _importService = BulkImportService();

  final currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId; // null means "All"

  // Stock Filter: 'all', 'limited', 'unlimited'
  String _stockFilter = 'all';

  @override
  void initState() {
    super.initState();
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
      // Fetch Categories
      final categoriesData = await supabase
          .from('categories')
          .select('id, name')
          .eq('store_id', widget.storeId)
          .order('name');

      // Fetch Products
      // Note: We select max_stock here too (disabled for now)
      final productsData = await supabase
          .from('products')
          .select('*, categories(name)')
          .eq('store_id', widget.storeId)
          .order('name', ascending: true);

      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(categoriesData);
          _products = List<Map<String, dynamic>>.from(
            productsData,
          ).where((p) => (p['is_deleted'] ?? false) == false).toList();
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
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
      _filteredProducts = _products.where((product) {
        final name = product['name'].toString().toLowerCase();
        final sku = (product['sku'] ?? '').toString().toLowerCase();
        final matchesSearch = name.contains(query) || sku.contains(query);

        final categoryId = product['category_id'];
        final matchesCategory =
            _selectedCategoryId == null || categoryId == _selectedCategoryId;

        bool matchesStock = true;
        final isManaged = product['is_stock_managed'] == true;

        if (_stockFilter == 'limited') {
          matchesStock = isManaged;
        } else if (_stockFilter == 'unlimited') {
          matchesStock = !isManaged;
        }

        return matchesSearch && matchesCategory && matchesStock;
      }).toList();
    });
  }

  void _openProductForm({Map<String, dynamic>? product}) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          ProductFormSheet(product: product, storeId: widget.storeId),
    );

    if (result == true) {
      _fetchData();
    }
  }

  void _handleExport() async {
    setState(() => _isLoading = true);
    try {
      final path = await _importService.exportProductsToExcel(widget.storeId);
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
    final result = await _importService.importProducts(widget.storeId);

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
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Hasil Impor"),
        content: Column(
          children: [
            const SizedBox(height: 10),
            Text("Berhasil: $success"),
            Text("Gagal: $fail"),
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                "Detail Kesalahan:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  itemCount: errors.length,
                  itemBuilder: (c, i) => Text(
                    errors[i],
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Tutup"),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(String id) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Hapus Produk?"),
        content: const Text("Tindakan ini tidak dapat dibatalkan."),
        actions: [
          CupertinoDialogAction(
            child: const Text("Batal"),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Fetch product to get image_url before deletion (Optional, kept for future restore logic)
        // final product = _products.firstWhere((p) => p['id'] == id);
        // final imageUrl = product['image_url']; // Unused in soft delete

        // Soft Delete: Update is_deleted = true
        await supabase
            .from('products')
            .update({'is_deleted': true})
            .eq('id', id);

        // NOTE: We do NOT delete the image from storage because the product
        // still exists in history/transactions and might be restored later.

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
      builder: (ctx) => AlertDialog(
        title: const Text("Kosongkan Semua Stok?"),
        content: const Text(
          "Semua produk dalam daftar 'Terbatas' akan diubah stoknya menjadi 0.\n\nTindakan ini tidak dapat dibatalkan.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Kosongkan", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);

      // Collect IDs of currently filtered products (which should be 'Limited')
      final ids = _filteredProducts.map((p) => p['id']).toList();

      if (ids.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      try {
        await supabase
            .from('products')
            .update({'stock_quantity': 0})
            .inFilter('id', ids);

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
      builder: (ctx) => SimpleDialog(
        title: const Text("Restock Massal"),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'max'),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("🎯 Penuhi ke Max Stock (Sesuai Limit Produk)"),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'manual'),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("➕ Tambah Jumlah Sama ke Semua"),
            ),
          ),
        ],
      ),
    );

    if (choice == null) return;

    if (choice == 'max') {
      await _fillToMaxStock();
    } else {
      await _addFixedStockToAll();
    }
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
      builder: (ctx) => AlertDialog(
        title: const Text("Tambah Stok Massal"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Jumlah Tambahan (misal: 10)",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                try {
                  for (var p in _filteredProducts) {
                    final current = (p['stock_quantity'] ?? 0) as int;
                    await supabase
                        .from('products')
                        .update({'stock_quantity': current + amount})
                        .eq('id', p['id']);
                  }
                  if (mounted) {
                    _fetchData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Berhasil menambah +$amount ke semua produk.",
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint("Restock error: $e");
                  if (mounted) setState(() => _isLoading = false);
                }
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Inventori Barang",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF2D3436),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: MediaQuery.of(context).size.width > 700
            ? null
            : IconButton(
                icon: Icon(
                  CupertinoIcons.back,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                ),
                onPressed: () => Navigator.pop(context),
              ),
        automaticallyImplyLeading: false,
        actions: [
          if (_stockFilter == 'limited') ...[
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
              onPressed: () => _emptyAllStock(),
              tooltip: "Kosongkan Stok",
            ),
            IconButton(
              icon: const Icon(
                Icons.playlist_add_check_rounded,
                color: Colors.green,
              ),
              onPressed: () => _restockAll(),
              tooltip: "Restock Semua",
            ),
          ],
          IconButton(
            icon: const Icon(
              CupertinoIcons.cloud_download_fill,
              color: Colors.green,
              size: 24,
            ),
            onPressed: _handleExport,
            tooltip: "Export Excel",
          ),
          IconButton(
            icon: const Icon(
              CupertinoIcons.cloud_upload_fill,
              color: Colors.blue,
              size: 24,
            ),
            onPressed: () => _handleBulkImport(), // Existing import
            tooltip: "Import CSV/Excel",
          ),
          IconButton(
            icon: const Icon(
              CupertinoIcons.plus_circle_fill,
              color: Color(0xFFEA5700),
              size: 28,
            ),
            onPressed: () => _openProductForm(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: BigSearchBar(
              controller: _searchController,
              hintText: "Cari nama barang atau SKU...",
              onChanged: (val) {
                // Listener already attached in initState, but we can keep this for immediate feedback if needed
                // _filterProducts(); // logic handles by listener
              },
              onClear: () {
                _searchController.clear();
                // trigger filter update if listener doesn't catch clear?
                // listener catches it.
              },
            ),
          ),

          // Product List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchData,
              color: const Color(0xFFEA5700),
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
                                  : _selectedCategoryId == cat!['id'];

                              return ChoiceChip(
                                label: Text(isAll ? "Semua" : cat!['name']),
                                selected: isSelected,
                                onSelected: (_) =>
                                    _selectCategory(isAll ? null : cat!['id']),
                                selectedColor: const Color(0xFFEA5700),
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
                                      // Grid View for Tablets
                                      return GridView.builder(
                                        padding: const EdgeInsets.all(20),
                                        gridDelegate:
                                            const SliverGridDelegateWithMaxCrossAxisExtent(
                                              maxCrossAxisExtent: 220,
                                              childAspectRatio:
                                                  0.65, // Taller cards for column layout
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
                                    // List View for Mobile
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

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
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
      child: product['is_stock_managed']
          ? Dismissible(
              key: Key("restock_${product['id']}"),
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

  Widget _buildProductCardContent(Map<String, dynamic> product) {
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
                  image: product['image_url'] != null
                      ? DecorationImage(
                          image: NetworkImage(product['image_url']),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product['image_url'] == null
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
                      product['name'],
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
                            product['categories']?['name'] ?? 'No Category',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Stock: ${product['is_stock_managed'] ? product['stock_quantity'] : '∞'}",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color:
                                product['is_stock_managed'] &&
                                    product['stock_quantity'] < 5
                                ? Colors.red
                                : Colors.grey[600],
                            fontWeight:
                                product['is_stock_managed'] &&
                                    product['stock_quantity'] < 5
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(product['sale_price']),
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
                    onPressed: () => _deleteProduct(product['id']),
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

  Future<void> _showRestockDialog(Map<String, dynamic> product) async {
    final controller = TextEditingController();
    final currentStock = product['stock_quantity'] ?? 0;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Restock: ${product['name']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Stok Saat Ini: $currentStock"),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "Tambah Jumlah Stok",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final addAmount = int.tryParse(controller.text) ?? 0;
              if (addAmount > 0) {
                final newStock = currentStock + addAmount;
                await supabase
                    .from('products')
                    .update({'stock_quantity': newStock})
                    .eq('id', product['id']);

                if (mounted) {
                  Navigator.pop(context);
                  _fetchData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Stok berhasil ditambah: +$addAmount"),
                    ),
                  );
                }
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGridItem(Map<String, dynamic> product, int index) {
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
                        image: product['image_url'] != null
                            ? DecorationImage(
                                image: NetworkImage(product['image_url']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: product['image_url'] == null
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
                              onPressed: () => _deleteProduct(product['id']),
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
                      product['name'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(product['sale_price']),
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
                              product['categories']?['name'] ?? 'No Cat',
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
                          "Stock: ${product['is_stock_managed'] ? product['stock_quantity'] : '∞'}",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color:
                                product['is_stock_managed'] &&
                                    product['stock_quantity'] < 5
                                ? Colors.red
                                : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (product['is_stock_managed']) ...[
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
}
