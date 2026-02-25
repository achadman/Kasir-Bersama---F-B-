import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../widgets/product_grid.dart';
import '../../widgets/kasir_drawer.dart';
import 'widgets/cart_sidebar.dart';
import '../../services/order_service.dart';
import '../../services/receipt_service.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/settings_controller.dart';
import 'widgets/product_option_modal.dart';
import 'widgets/payment_success_dialog.dart';
import '../../widgets/big_search_bar.dart';
import 'widgets/category_icon_card.dart';
import 'widgets/kasir_side_navigation.dart';
import '../../services/app_database.dart';

class KasirPage extends StatefulWidget {
  final bool showSidebar;
  final VoidCallback? onMenuPressed;
  const KasirPage({super.key, this.showSidebar = true, this.onMenuPressed});

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> {
  late OrderService _orderService;
  final _receiptService = ReceiptService();
  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String? _storeId;
  String _selectedCategory = "Semua";
  String _searchQuery = "";
  String _selectedFilter = "Popular";
  final List<Map<String, dynamic>> _cartItems = [];
  List<String> _categories = ["Semua"];
  final Map<String, String> _categoryMap = {}; // Name -> ID

  final Color _primaryColor = const Color(0xFFFF4D4D);
  String? _storeName;
  String? _storeLogoUrl;

  // Payment Logic
  double _cashReceived = 0;
  String _selectedPaymentMethod = "Tunai";
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isGridView = true;
  Map<String, dynamic> _discountData = {
    'total_discount': 0.0,
    'promo_names': [],
  };
  bool _isPaymentFullscreen = false;

  Future<void> _recalculateDiscounts() async {
    if (_storeId == null) return;

    final adminCtrl = context.read<AdminController>();
    final result = await adminCtrl.promotionService.calculateDiscounts(
      storeId: _storeId!,
      cartItems: _cartItems,
    );

    if (mounted) {
      setState(() {
        _discountData = result;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _isGridView = SettingsController.instance.isGridView.value;
    // Use post frame callback to safely access context providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = context.read<AppDatabase>();
      _orderService = OrderService(db);
      _initData();
    });
  }

  Future<void> _initData() async {
    await context.read<AdminController>().loadInitialData();
    if (mounted) {
      _loadStoreId();
    }
  }

  Future<void> _loadCategories() async {
    if (_storeId == null) return;

    final db = context.read<AppDatabase>();
    final localCategories = await (db.select(
      db.categories,
    )..where((t) => t.storeId.equals(_storeId!))).get();

    if (mounted) {
      setState(() {
        _categoryMap.clear();
        List<String> names = ["Semua"];
        for (var c in localCategories) {
          final name = c.name ?? "Unnamed";
          names.add(name);
          _categoryMap[name] = c.id;
        }
        _categories = names;
      });
    }
  }

  Future<void> _loadStoreId() async {
    final adminCtrl = context.read<AdminController>();
    if (adminCtrl.storeId != null) {
      setState(() {
        _storeId = adminCtrl.storeId;
        _storeName = adminCtrl.storeName;
        _storeLogoUrl = adminCtrl.storeLogo;
      });
      _loadCategories();
    }
  }

  int _getCartTotalCount() {
    return _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int));
  }

  double _getCartTotal() {
    return _cartItems.fold(0, (sum, item) {
      return sum +
          ((item['price'] as num).toDouble() * (item['quantity'] as int));
    });
  }

  Future<void> _handleProductSelection(
    Product product, {
    List? options,
    String? notes,
    double? price,
  }) async {
    // If options/notes are already provided (e.g. from re-adding), bypass modal
    if (options != null || notes != null || price != null) {
      _addToCart(product, options: options, notes: notes, price: price);
      return;
    }

    // 1. Check if product has options
    final db = context.read<AppDatabase>();
    final optionsRes = await (db.select(
      db.productOptions,
    )..where((t) => t.productId.equals(product.id))).get();

    final count = optionsRes.length;

    if (count > 0 && mounted) {
      // Show Customization Modal
      final result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => ProductOptionModal(product: product),
      );

      if (result != null) {
        _addToCart(
          product,
          options: result['choices'],
          notes: result['notes'],
          price: result['total_price'],
        );
      }
    } else {
      // Add directly
      _addToCart(product, price: product.salePrice ?? 0);
    }
  }

  void _addToCart(
    Product product, {
    List? options,
    String? notes,
    double? price,
  }) {
    setState(() {
      // Check if exact same item (product + options + notes) already in cart
      final existingIndex = _cartItems.indexWhere((item) {
        bool sameProduct = (item['product'] as Product).id == product.id;
        // Treat null and empty list as same
        final currentOptions = item['selected_options'] as List?;
        bool sameOptions = _compareOptions(currentOptions, options);
        bool sameNotes = (item['notes'] ?? '').trim() == (notes ?? '').trim();
        return sameProduct && sameOptions && sameNotes;
      });

      if (existingIndex != -1) {
        _cartItems[existingIndex]['quantity']++;
      } else {
        _cartItems.add({
          'cart_id': DateTime.now().microsecondsSinceEpoch.toString(),
          'product': product,
          'quantity': 1,
          'selected_options': options ?? [],
          'notes': notes ?? '',
          'price': price ?? product.salePrice ?? 0,
        });
      }
      _recalculateDiscounts();
    });
  }

  bool _compareOptions(List? a, List? b) {
    // Treat null and empty as same
    final listA = a ?? [];
    final listB = b ?? [];
    
    if (listA.isEmpty && listB.isEmpty) return true;
    if (listA.length != listB.length) return false;
    
    // Sort and compare option/value IDs to ensure order doesn't matter
    final sortedA = List<Map<String, dynamic>>.from(listA)
      ..sort((x, y) => x['value_id'].compareTo(y['value_id']));
    final sortedB = List<Map<String, dynamic>>.from(listB)
      ..sort((x, y) => x['value_id'].compareTo(y['value_id']));

    for (int i = 0; i < sortedA.length; i++) {
      if (sortedA[i]['value_id'] != sortedB[i]['value_id']) return false;
    }
    return true;
  }

  void _removeFromCart(String cartId) {
    setState(() {
      final index = _cartItems.indexWhere((item) => item['cart_id'] == cartId);
      if (index != -1) {
        if (_cartItems[index]['quantity'] > 1) {
          _cartItems[index]['quantity']--;
        } else {
          _cartItems.removeAt(index);
        }
      }
      _recalculateDiscounts();
    });
  }

  Future<void> _processCheckout() async {
    if (_isProcessing || _cartItems.isEmpty || _storeId == null) return;

    setState(() => _isProcessing = true);
    try {
      final adminCtrl = context.read<AdminController>();
      final uId = adminCtrl.userId;
      if (uId == null) return;

      // 1. Fetch current product prices and details - We use cart item data directly
      double totalAmount = 0;
      List<Map<String, dynamic>> items = [];

      for (var cartItem in _cartItems) {
        final Product p = cartItem['product'];
        final qty = cartItem['quantity'] as int;
        final price = cartItem['price'] as double;
        final total = price * qty;

        totalAmount += total;
        items.add({
          'id': "${DateTime.now().microsecondsSinceEpoch}_${p.id}",
          'product_id': p.id,
          'product_name': p.name,
          'quantity': qty,
          'unit_price': price,
          'total_price': total,
          'notes': cartItem['notes'],
          'selected_options': cartItem['selected_options'],
        });
      }

      // 2. Subtract Discount
      final discount = _discountData['total_discount'] as double;
      final finalTotal = (totalAmount - discount).clamp(0.0, double.infinity);

      // 3. Save order and get ID
      final txId = await _orderService.createOrder(
        storeId: _storeId!,
        userId: uId,
        totalAmount: finalTotal,
        cashReceived: _cashReceived,
        change: _cashReceived - finalTotal,
        paymentMethod: _selectedPaymentMethod,
        items: items,
      );

      // 3. Generate Receipt Data
      final now = DateTime.now();
      final double finalCash = _cashReceived;
      final double finalChange = _cashReceived - totalAmount;
      final currentStoreName = _storeName ?? "Toko Kasir Asri";
      final currentStoreLogo = _storeLogoUrl;

      // Prepare items for receipt with their names (from cart)
      final List<Map<String, dynamic>> receiptItems = [];
      for (var cartItem in _cartItems) {
        final Product p = cartItem['product'];
        receiptItems.add({
          'name': p.name,
          'quantity': cartItem['quantity'],
          'unit_price': cartItem['price'],
          'total_price':
              (cartItem['price'] as double) * (cartItem['quantity'] as int),
          'notes': cartItem['notes'],
        });
      }

      final pdfData = await _receiptService.generateReceiptPdf(
        storeName: currentStoreName,
        storeLogoUrl: currentStoreLogo,
        transactionId: txId
            .substring(0, 8)
            .toUpperCase(), // Shorten for receipt
        createdAt: now,
        items: receiptItems,
        totalAmount: finalTotal,
        cashReceived: finalCash,
        change: finalChange,
        paymentMethod: _selectedPaymentMethod,
      );

      // 4. Success and Show Receipt
      if (mounted) {
        _resetPOS();

        Navigator.of(context).maybePop(); // Close cart sheet

        // Show Success Dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => PaymentSuccessDialog(
            pdfData: pdfData,
            transactionId: txId.substring(0, 8).toUpperCase(),
            totalAmount: finalTotal,
            cashReceived: finalCash,
            change: finalChange,
            storeName: currentStoreName,
            createdAt: now,
            items: receiptItems,
            paymentMethod: _selectedPaymentMethod,
            onNewTransaction: _resetPOS,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Checkout Gagal: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _resetPOS() {
    setState(() {
      _cartItems.clear();
      _cashReceived = 0;
      _cashController.clear();
      _isPaymentFullscreen = false;
      _discountData = {
        'total_discount': 0.0,
        'promo_count': 0,
        'promo_names': [],
      };
    });
  }

  bool _isProcessing = false;

  @override
  void dispose() {
    _searchController.dispose();
    _cashController.dispose();
    super.dispose();
  }

  Future<void> _searchAndAddBySku(String sku) async {
    if (sku.isEmpty || _storeId == null) return;

    final db = context.read<AppDatabase>();
    final res =
        await (db.select(db.products)
              ..where((t) => t.storeId.equals(_storeId!))
              ..where((t) => t.sku.equals(sku))
              ..where((t) => t.isDeleted.equals(false)))
            .get();

    if (res.isNotEmpty) {
      // Product found!
      final product = res.first;

      // Add to cart
      _handleProductSelection(product);

      // Clear search field after successful scan
      setState(() {
        _searchController.clear();
        _searchQuery = "";
      });
    } else {
      // Not found by SKU
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      drawer: widget.showSidebar
          ? const KasirDrawer(currentRoute: '/kasir')
          : null,
      appBar: isWide 
        ? null 
        : AppBar(
            toolbarHeight: 74,
            backgroundColor: isDark ? const Color(0xFF1A1C1E) : Colors.white,
            elevation: 0,
            leading: Builder(
              builder: (ctx) {
                return IconButton(
                  icon: Icon(
                    CupertinoIcons.bars,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onPressed: () {
                    if (widget.onMenuPressed != null) {
                      widget.onMenuPressed!();
                    } else {
                      // Fallback for standalone usage
                      Scaffold.of(ctx).openDrawer();
                    }
                  },
                );
              },
            ),
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                _storeName ?? "Toko Kasir Asri",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            actions: [
              // Only show cart icon on mobile
              Builder(builder: (ctx) {
                return IconButton(
                  icon: Stack(
                    children: [
                      Icon(
                        CupertinoIcons.cart,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      if (_getCartTotalCount() > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 8,
                              minHeight: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: _getCartTotalCount() > 0 ? _showCartSheet : null,
                );
              }),
              const SizedBox(width: 8),
            ],
          ),
      body: _storeId == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth >= 720;

                if (isWideScreen) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Persistent Side Navigation - Only if standalone
                      if (widget.showSidebar && !_isPaymentFullscreen)
                        const KasirSideNavigation(currentRoute: '/kasir'),

                      // Main Content
                      if (!_isPaymentFullscreen)
                        Expanded(
                          flex: 7,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Search and Toggle Row
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: BigSearchBar(
                                        controller: _searchController,
                                        hintText: "Cari menu atau Scan SKU...",
                                        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                                        onSubmitted: (val) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Mari cari produk...')),
                                          );
                                        },
                                        onClear: () {
                                          setState(() {
                                            _searchController.clear();
                                            _searchQuery = "";
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white10 : Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: isDark ? Colors.white10 : Colors.grey[200]!,
                                        ),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                        onPressed: () {
                                          final newValue = !_isGridView;
                                          setState(() => _isGridView = newValue);
                                          SettingsController.instance.setGridView(newValue);
                                        },
                                        tooltip: _isGridView ? "Tampilan List" : "Tampilan Grid",
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Products Filter and Categories logic
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  itemCount: _categories.length,
                                  itemBuilder: (context, index) {
                                    final cat = _categories[index];
                                    final isSelected = _selectedCategory == cat;
                                    return CategoryIconCard(
                                      label: cat,
                                      isSelected: isSelected,
                                      onTap: () {
                                        setState(
                                          () => _selectedCategory = isSelected
                                              ? "Semua"
                                              : cat,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),

                              // Product Filter Tabs (Popular/Recent)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  24,
                                  24,
                                  8,
                                ),
                                child: Row(
                                  children: [
                                    _buildFilterTab(
                                      "Popular",
                                      _selectedFilter == "Popular",
                                    ),
                                    const SizedBox(width: 24),
                                    _buildFilterTab(
                                      "Recent",
                                      _selectedFilter == "Recent",
                                    ),
                                  ],
                                ),
                              ),

                              Expanded(
                                child: ProductGrid(
                                  storeId: _storeId!,
                                  searchQuery: _searchQuery,
                                  categoryFilter: _selectedCategory == "Semua"
                                      ? "Semua"
                                      : _categoryMap[_selectedCategory],
                                  filterType:
                                      _selectedFilter, // Need to implement this in ProductGrid
                                  isGridView: _isGridView,
                                  onItemTap: (Product product) {
                                    _handleProductSelection(product);
                                    setState(() {});
                                  },
                                  actionBuilder: (context, Product p) =>
                                      _buildActionIcon(p),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Right Side (Invoice Sidebar - Smoother)
                      Expanded(
                        flex: _isPaymentFullscreen ? 1 : 3,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: isDark ? Colors.white10 : Colors.grey[200]!,
                              ),
                            ),
                          ),
                          child: CartSidebar(
                            searchController: _searchController,
                            onSearchChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                            onSearchSubmitted: _searchAndAddBySku,
                            onSearchClear: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = "";
                              });
                            },
                            cartItems: _cartItems,
                            isProcessing: _isProcessing,
                            discountData: _discountData,
                            isGridView: _isGridView,
                            onToggleGrid: () {
                              final newValue = !_isGridView;
                              setState(() => _isGridView = newValue);
                              SettingsController.instance.setGridView(newValue);
                            },
                            onModeChanged: (isPayment) {
                              setState(() => _isPaymentFullscreen = isPayment);
                            },
                            onRemoveItem: (cartId) {
                              _removeFromCart(cartId);
                              setState(() {});
                            },
                            onAddItem:
                                (Product product, {options, notes, price}) {
                                  _handleProductSelection(
                                    product,
                                    options: options,
                                    notes: notes,
                                    price: price,
                                  );
                                  setState(() {});
                                },
                            onCheckout: (cash, method) {
                              setState(() {
                                _cashReceived = cash;
                                _selectedPaymentMethod = method;
                              });
                              _processCheckout();
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                }

                  // Mobile Layout
                  return Stack(
                    children: [
                      Column(
                        children: [
                          // Search and Toggle (Mobile)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: BigSearchBar(
                                    controller: _searchController,
                                    hintText: "Cari menu...",
                                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                                    onClear: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = "";
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                                      color: isDark ? Colors.white : Colors.black87,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      final newValue = !_isGridView;
                                      setState(() => _isGridView = newValue);
                                      SettingsController.instance.setGridView(newValue);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Categories
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final cat = _categories[index];
                                final isSelected = _selectedCategory == cat;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: ChoiceChip(
                                    label: Text(cat),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedCategory = selected
                                            ? cat
                                            : "Semua";
                                      });
                                    },
                                    selectedColor: _primaryColor,
                                    labelStyle: GoogleFonts.inter(
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.white70
                                                : Colors.black),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    backgroundColor: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[100],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide.none,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: ProductGrid(
                              storeId: _storeId!,
                              searchQuery: _searchQuery,
                              categoryFilter: _selectedCategory == "Semua"
                                  ? "Semua"
                                  : _categoryMap[_selectedCategory],
                              isGridView: _isGridView,
                              onItemTap: (Product product) {
                                _handleProductSelection(product);
                                setState(() {});
                              },
                              actionBuilder: (context, Product p) =>
                                  _buildActionIcon(p),
                            ),
                          ),
                        ],
                      ),
                      if (_cartItems.isNotEmpty)
                        Positioned(
                          bottom: 30,
                          left: 20,
                          right: 20,
                          child: GestureDetector(
                            onTap: _showCartSheet,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryColor.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      "${_getCartTotalCount()}",
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Total",
                                        style: GoogleFonts.inter(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        _currencyFormat.format(_getCartTotal()),
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.shopping_bag_outlined,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
            ),
    );
  }

  Widget _buildFilterTab(String label, bool isActive) {
    const primaryColor = Color(0xFFEA5700);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive
                  ? (isDark ? Colors.white : Colors.black)
                  : Colors.grey,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 3,
              width: 24,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(Product p) {
    final isStockManaged = p.isStockManaged;
    final stockQty = p.stockQuantity ?? 0;
    final isOutOfStock = isStockManaged && stockQty <= 0;

    final inCartItems = _cartItems.where(
      (item) => (item['product'] as Product).id == p.id,
    );
    int qty = inCartItems.fold(
      0,
      (sum, item) => sum + (item['quantity'] as int),
    );

    if (isOutOfStock) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.block_rounded, color: Colors.white, size: 18),
      );
    }

    return qty == 0
        ? Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
          )
        : Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                qty.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          );
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false, // Disable drag for full screen experience
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SizedBox(
            height: MediaQuery.of(context).size.height,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: CartSidebar(
                searchController: _searchController,
                onSearchChanged: (val) => setState(() {
                  _searchQuery = val.toLowerCase();
                  setSheetState(() {});
                }),
                onSearchSubmitted: (val) {
                  _searchAndAddBySku(val);
                  setSheetState(() {});
                },
                onSearchClear: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = "";
                  });
                  setSheetState(() {});
                },
                cartItems: _cartItems,
                isProcessing: _isProcessing,
                discountData: _discountData,
                onRemoveItem: (cartId) {
                  _removeFromCart(cartId);
                  setSheetState(() {});
                  setState(() {});
                },
                onAddItem: (Product product, {options, notes, price}) {
                  _handleProductSelection(
                    product,
                    options: options,
                    notes: notes,
                    price: price,
                  );
                  setSheetState(() {});
                  setState(() {});
                },
                onCheckout: (cash, method) {
                  setState(() {
                    _cashReceived = cash;
                    _selectedPaymentMethod = method;
                  });
                  Navigator.pop(context);
                  _processCheckout();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
