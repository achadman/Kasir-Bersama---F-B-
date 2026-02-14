import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Added
import '../../widgets/product_grid.dart';
import '../../widgets/kasir_drawer.dart';
import 'widgets/cart_sidebar.dart';
import '../../services/order_service.dart';
import '../../services/receipt_service.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import 'widgets/product_option_modal.dart';
import 'widgets/payment_success_dialog.dart';
import '../../widgets/big_search_bar.dart';
import 'widgets/category_icon_card.dart';
import 'widgets/kasir_side_navigation.dart';
import '../../services/isar_service.dart';
import '../../services/sync_service.dart';
import '../../models/local/local_category.dart';
import 'package:isar/isar.dart';

class KasirPage extends StatefulWidget {
  const KasirPage({super.key});

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> {
  final supabase = Supabase.instance.client;
  final _orderService = OrderService();
  final _receiptService = ReceiptService();
  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String? _storeId;
  String _selectedCategory = "Semua";
  String _searchQuery = "";
  String _selectedFilter = "Popular"; // Added: Popular or Recent
  final List<Map<String, dynamic>> _cartItems =
      []; // [{id, product, qty, options, notes, price}]
  List<String> _categories = ["Semua"];
  final Map<String, String> _categoryMap = {}; // Name -> ID

  final Color _primaryColor = const Color(0xFFFF4D4D); // Vibrant Red
  String? _storeName;
  String? _storeLogoUrl;

  // Payment Logic
  double _cashReceived = 0;
  String _selectedPaymentMethod = "Tunai";
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _searchController =
      TextEditingController(); // Added for clearing search

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminController>().loadInitialData();
    });
    _loadStoreId();
  }

  Future<void> _loadCategories() async {
    if (_storeId == null) return;

    final isar = IsarService().isar;
    final localCategories = await isar.localCategorys
        .filter()
        .storeIdEqualTo(_storeId!)
        .findAll();

    if (mounted) {
      setState(() {
        _categoryMap.clear();
        List<String> names = ["Semua"];
        for (var c in localCategories) {
          names.add(c.name);
          _categoryMap[c.name] = c.supabaseId;
        }
        _categories = names;
      });
    }

    // Also watch for changes
    isar.localCategorys.filter().storeIdEqualTo(_storeId!).watch().listen((
      data,
    ) {
      if (mounted) {
        setState(() {
          _categoryMap.clear();
          List<String> names = ["Semua"];
          for (var c in data) {
            names.add(c.name);
            _categoryMap[c.name] = c.supabaseId;
          }
          _categories = names;
        });
      }
    });
  }

  Future<void> _loadStoreId() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final profile = await supabase
          .from('profiles')
          .select('store_id')
          .eq('id', user.id)
          .maybeSingle();

      if (profile?['store_id'] != null && mounted) {
        final sId = profile!['store_id'];
        setState(() => _storeId = sId);

        // TRIGGER SYNC
        SyncService().syncDown(sId);
        _loadCategories(); // Now loads from Isar

        // Load Store Details for Receipt
        final storeData = await supabase
            .from('stores')
            .select('name, logo_url')
            .eq('id', sId)
            .maybeSingle();

        if (storeData != null && mounted) {
          setState(() {
            _storeName = storeData['name'];
            _storeLogoUrl = storeData['logo_url'];
          });
        }
      }
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
    Map<String, dynamic> product, {
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
    final response = await supabase
        .from('product_options')
        .select('id')
        .eq('product_id', product['id']);

    final count = response.length;

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
      _addToCart(product, price: (product['sale_price'] as num).toDouble());
    }
  }

  void _addToCart(
    Map<String, dynamic> product, {
    List? options,
    String? notes,
    double? price,
  }) {
    setState(() {
      // Check if exact same item (product + options + notes) already in cart
      final existingIndex = _cartItems.indexWhere((item) {
        bool sameProduct = item['product']['id'] == product['id'];
        bool sameOptions = _compareOptions(item['selected_options'], options);
        bool sameNotes = (item['notes'] ?? '') == (notes ?? '');
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
          'price': price ?? (product['sale_price'] as num).toDouble(),
        });
      }
    });
  }

  bool _compareOptions(List? a, List? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    // Sort and compare option/value IDs
    final listA = List<Map<String, dynamic>>.from(a)
      ..sort((x, y) => x['value_id'].compareTo(y['value_id']));
    final listB = List<Map<String, dynamic>>.from(b)
      ..sort((x, y) => x['value_id'].compareTo(y['value_id']));

    for (int i = 0; i < listA.length; i++) {
      if (listA[i]['value_id'] != listB[i]['value_id']) return false;
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
    });
  }

  Future<void> _processCheckout() async {
    if (_isProcessing || _cartItems.isEmpty || _storeId == null) return;

    setState(() => _isProcessing = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // 1. Fetch current product prices and details - We use cart item data directly
      double totalAmount = 0;
      List<Map<String, dynamic>> items = [];

      for (var cartItem in _cartItems) {
        final qty = cartItem['quantity'] as int;
        final price = cartItem['price'] as double;
        final total = price * qty;

        totalAmount += total;
        items.add({
          'product_id': cartItem['product']['id'],
          'quantity': qty,
          'unit_price': price,
          'total_price': total,
          'notes': cartItem['notes'],
          'selected_options': cartItem['selected_options'],
        });
      }

      // 2. Save order and get ID
      final txId = await _orderService.createOrder(
        storeId: _storeId!,
        userId: user.id,
        totalAmount: totalAmount,
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
        receiptItems.add({
          'name': cartItem['product']['name'],
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
        totalAmount: totalAmount,
        cashReceived: finalCash,
        change: finalChange,
        paymentMethod: _selectedPaymentMethod,
      );

      // 4. Success and Show Receipt
      if (mounted) {
        setState(() {
          _cartItems.clear();
          _cashReceived = 0;
          _cashController.clear();
        });

        Navigator.pop(context); // Close cart sheet

        // Show Success Dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => PaymentSuccessDialog(
            pdfData: pdfData,
            transactionId: txId.substring(0, 8).toUpperCase(),
            totalAmount: totalAmount,
            cashReceived: finalCash,
            change: finalChange,
            storeName: currentStoreName,
            createdAt: now,
            items: receiptItems,
            paymentMethod: _selectedPaymentMethod,
            onNewTransaction: () {
              // Cart is already cleared above
              setState(() {
                _cartItems.clear();
                _cashReceived = 0;
                _cashController.clear();
              });
            },
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

  bool _isProcessing = false;

  @override
  void dispose() {
    _searchController.dispose();
    _cashController.dispose();
    super.dispose();
  }

  Future<void> _searchAndAddBySku(String sku) async {
    if (sku.isEmpty || _storeId == null) return;

    // 1. Search for product with exact SKU
    final res = await supabase
        .from('products')
        .select()
        .eq('store_id', _storeId!)
        .eq('sku', sku) // Exact match for scanning
        .maybeSingle();

    if (res != null) {
      // Product found!
      final product = res;

      // check if deleted
      if (product['is_deleted'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Produk ini sudah dihapus.")),
          );
        }
        return;
      }

      // Add to cart
      _handleProductSelection(product);

      // Clear search field after successful scan
      setState(() {
        _searchController.clear();
        _searchQuery = "";
      });
    } else {
      // Not found by SKU, maybe keep the search query for the grid filter?
      // But if it was a scan (enter pressed), usually we want to clear or notify.
      // Let's just keep the filter active so the user sees "No product found" in the grid.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      drawer: const KasirDrawer(currentRoute: '/kasir'),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            toolbarHeight: 74, // Increased to fit BigSearchBar
            expandedHeight:
                74, // Match toolbar height for simple fixed header, or keep expandable if needed
            floating: true,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1A1C1E) : Colors.white,
            elevation: 0,
            leading: Builder(
              builder: (context) {
                final isWide = MediaQuery.of(context).size.width > 900;
                if (isWide) return const SizedBox.shrink();
                return IconButton(
                  icon: Icon(
                    CupertinoIcons.bars,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                );
              },
            ),
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: BigSearchBar(
                controller: _searchController,
                hintText: "Cari menu atau Scan SKU...",
                onChanged: (val) =>
                    setState(() => _searchQuery = val.toLowerCase()),
                onSubmitted: (val) => _searchAndAddBySku(val),
                onClear: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = "";
                  });
                },
              ),
            ),
            actions: [
              IconButton(
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
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
        body: _storeId == null
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isWideScreen = constraints.maxWidth > 900;
                  final adminCtrl = context.watch<AdminController>();
                  final userProfile = adminCtrl.userProfile;

                  if (isWideScreen) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Persistent Side Navigation
                        const KasirSideNavigation(currentRoute: '/kasir'),

                        // Main Content
                        Expanded(
                          flex: 7,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Redesigned Header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  24,
                                  24,
                                  8,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: BigSearchBar(
                                        controller: _searchController,
                                        hintText: "Search food or menu...",
                                        onChanged: (val) => setState(
                                          () =>
                                              _searchQuery = val.toLowerCase(),
                                        ),
                                        onSubmitted: (val) =>
                                            _searchAndAddBySku(val),
                                        onClear: () {
                                          setState(() {
                                            _searchController.clear();
                                            _searchQuery = "";
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    // Profile Info (Mock for David Brown in image)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF2C2C2E)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: _primaryColor,
                                            backgroundImage:
                                                userProfile?['avatar_url'] !=
                                                    null
                                                ? NetworkImage(
                                                    userProfile!['avatar_url'],
                                                  )
                                                : null,
                                            child:
                                                userProfile?['avatar_url'] ==
                                                    null
                                                ? const Icon(
                                                    Icons.person,
                                                    size: 20,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            userProfile?['full_name'] ??
                                                "David Brown",
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.keyboard_arrow_down,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Explore Categories
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  20,
                                  24,
                                  12,
                                ),
                                child: Text(
                                  "Explore Categories",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF2D3436),
                                  ),
                                ),
                              ),
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
                                  onItemTap: (product) {
                                    _handleProductSelection(product);
                                    setState(() {});
                                  },
                                  actionBuilder: (context, p) =>
                                      _buildActionIcon(p),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Right Side (Invoice Sidebar - Smoother)
                        Expanded(
                          flex: 3,
                          child: CartSidebar(
                            cartItems: _cartItems,
                            isProcessing: _isProcessing,
                            onRemoveItem: (cartId) {
                              _removeFromCart(cartId);
                              setState(() {});
                            },
                            onAddItem: (product, {options, notes, price}) {
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
                      ],
                    );
                  }

                  // Mobile Layout
                  return Stack(
                    children: [
                      Column(
                        children: [
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
                              onItemTap: (product) {
                                _handleProductSelection(product);
                                setState(() {});
                              },
                              actionBuilder: (context, p) =>
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
                                    color: _primaryColor.withOpacity(0.4),
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
                                      color: Colors.white.withOpacity(0.2),
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

  Widget _buildActionIcon(Map<String, dynamic> p) {
    final isStockManaged = p['is_stock_managed'] ?? true;
    final stockQty = (p['stock_quantity'] ?? 0) as int;
    final isOutOfStock = isStockManaged && stockQty <= 0;

    final inCartItems = _cartItems.where(
      (item) => item['product']['id'] == p['id'],
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
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: CartSidebar(
                cartItems: _cartItems,
                isProcessing: _isProcessing,
                onRemoveItem: (cartId) {
                  _removeFromCart(cartId);
                  setSheetState(() {});
                  setState(() {});
                },
                onAddItem: (product, {options, notes, price}) {
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
