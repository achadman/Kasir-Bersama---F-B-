import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../services/app_database.dart';
import '../../../widgets/order_numpad.dart';
import 'package:provider/provider.dart';
import '../../../controllers/admin_controller.dart';
import '../../../services/platform/file_manager.dart';

class CartSidebar extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Map<String, dynamic>? discountData;
  final Function(String cartId) onRemoveItem;
  final Function(Product product, {List? options, String? notes, double? price})
  onAddItem;
  final Function(double cashReceived, String paymentMethod) onCheckout;
  final VoidCallback? onAbortTransaction;
  final Function(bool isPaymentMode)? onModeChanged;
  final bool isProcessing;
  final TextEditingController? searchController;
  final Function(String)? onSearchChanged;
  final Function(String)? onSearchSubmitted;
  final VoidCallback? onSearchClear;
  final bool isGridView;
  final VoidCallback? onToggleGrid;
  final Customer? selectedCustomer;
  final Function(Customer?)? onCustomerSelected;
  final String? lastModifiedCartId;
  final VoidCallback? onClose;

  const CartSidebar({
    super.key,
    this.searchController,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onSearchClear,
    required this.cartItems,
    required this.isProcessing,
    this.discountData,
    this.onModeChanged,
    required this.onRemoveItem,
    required this.onAddItem,
    required this.onCheckout,
    this.onAbortTransaction,
    this.isGridView = true,
    this.onToggleGrid,
    this.selectedCustomer,
    this.onCustomerSelected,
    this.lastModifiedCartId,
    this.onClose,
  });

  @override
  State<CartSidebar> createState() => _CartSidebarState();
}

class _CartSidebarState extends State<CartSidebar> {
  final TextEditingController _cashController = TextEditingController();
  double _cashReceived = 0;
  String _selectedPaymentMethod = "Tunai";
  bool _isPaymentMode = false; // Toggle between Cart Review and Payment
  int _selectedItemIndex = -1; // Added for Odoo selection
  OrderNumpadMode _numpadMode = OrderNumpadMode.qty;
  String _numpadBuffer = "";
  bool _isFirstInput =
      true; // Flag for flexible "overwrite on first digit" logic
  final ScrollController _scrollController = ScrollController();

  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _cashController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleNumpadTap(String val) {
    // Strip dots (thousands separator in 'id' locale)
    String rawValue = _cashController.text.replaceAll('.', '');

    if (val == "C") {
      rawValue = "";
    } else if (val == "backspace") {
      if (rawValue.isNotEmpty) {
        rawValue = rawValue.substring(0, rawValue.length - 1);
      }
    } else if (val == "000") {
      if (rawValue.length < 10 && rawValue.isNotEmpty) {
        rawValue += "000";
      }
    } else if (val == ".") {
      // Decimal support if needed, though rare for IDR cash
      if (!rawValue.contains(".") &&
          rawValue.length < 11 &&
          rawValue.isNotEmpty) {
        rawValue += ".";
      }
    } else {
      if (rawValue.length < 12) {
        rawValue += val;
      }
    }

    if (rawValue.isEmpty) {
      _cashReceived = 0;
      _cashController.text = "";
    } else {
      _cashReceived = double.tryParse(rawValue) ?? 0;
      _cashController.text = NumberFormat.decimalPattern(
        'id',
      ).format(_cashReceived);
    }
    setState(() {});
  }

  void _handleOrderNumpadTap(String val) {
    if (_selectedItemIndex == -1 ||
        _selectedItemIndex >= widget.cartItems.length) {
      return;
    }

    if (val == "C") {
      _numpadBuffer = "";
      _isFirstInput = true;
    } else if (val == "000") {
      if (_isFirstInput) {
        _numpadBuffer = "0";
        _isFirstInput = false;
      } else {
        _numpadBuffer += "000";
      }
    } else if (val == ".") {
      if (_isFirstInput) {
        _numpadBuffer = "0.";
        _isFirstInput = false;
      } else if (!_numpadBuffer.contains(".")) {
        _numpadBuffer += ".";
      }
    } else {
      if (_isFirstInput) {
        _numpadBuffer = val;
        _isFirstInput = false;
      } else {
        _numpadBuffer += val;
      }
    }

    _applyNumpadValue();
  }

  void _handleOrderNumpadBackspace() {
    if (_selectedItemIndex == -1 ||
        _selectedItemIndex >= widget.cartItems.length) {
      return;
    }

    if (_numpadBuffer.isNotEmpty) {
      // Remove last digit from buffer as usual
      _numpadBuffer = _numpadBuffer.substring(0, _numpadBuffer.length - 1);
      if (_numpadBuffer.isEmpty) {
        _isFirstInput = true;
      }
      _applyNumpadValue();
    } else {
      // Buffer is empty - Determine behavior based on mode
      final item = widget.cartItems[_selectedItemIndex];

      if (_numpadMode == OrderNumpadMode.qty) {
        // User wants to "delete just one qty" - handle as decrement
        int currentQty = item['quantity'] as int;
        if (currentQty > 0) {
          final newQty = currentQty - 1;
          setState(() {
            item['quantity'] = newQty;
          });

          if (newQty == 0) {
            widget.onRemoveItem(item['cart_id']);
            setState(() {
              _selectedItemIndex = -1;
              _isFirstInput = true;
              _numpadBuffer = "";
            });
          }
        }
      } else {
        // For Price or Discount, keep the "erasing digit" behavior
        String currentValStr;
        if (_numpadMode == OrderNumpadMode.price) {
          currentValStr = (item['price'] as double).toInt().toString();
        } else {
          return;
        }

        if (currentValStr.length > 1) {
          _numpadBuffer = currentValStr.substring(0, currentValStr.length - 1);
          _isFirstInput = false;
          _applyNumpadValue();
          _numpadBuffer =
              ""; // Clear buffer so next click starts fresh from new state
        } else {
          _numpadBuffer = "0";
          _isFirstInput = true;
          _applyNumpadValue();
          _numpadBuffer = "";
        }
      }
    }
  }

  void _handleOrderNumpadToggleSign() {
    if (_numpadBuffer.startsWith("-")) {
      _numpadBuffer = _numpadBuffer.substring(1);
    } else if (_numpadBuffer.isNotEmpty) {
      _numpadBuffer = "-$_numpadBuffer";
    }
    _applyNumpadValue();
  }

  void _applyNumpadValue() {
    if (_selectedItemIndex == -1) {
      return;
    }

    final item = widget.cartItems[_selectedItemIndex];
    double val = double.tryParse(_numpadBuffer) ?? 0;

    if (_numpadMode == OrderNumpadMode.qty) {
      final newQty = val.toInt().clamp(0, 999);
      setState(() {
        item['quantity'] = newQty;
      });

      // Remove items with qty = 0
      if (newQty == 0) {
        widget.onRemoveItem(item['cart_id']);
        setState(() {
          _selectedItemIndex = -1;
          _numpadBuffer = '';
          _isFirstInput = true;
        });
      }
    } else if (_numpadMode == OrderNumpadMode.disc) {
      // Handle discount if field exists
    } else if (_numpadMode == OrderNumpadMode.price) {
      setState(() {
        item['price'] = val;
      });
    }

    // If cart is now empty, close the sheet if it's a popable route
    if (widget.cartItems.isEmpty && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Only pop if we are in a modal context (like bottom sheet on mobile)
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      });
    }
  }

  void _incrementQty(int index) {
    setState(() {
      final item = widget.cartItems[index];
      final currentQty = item['quantity'] as int;
      item['quantity'] = (currentQty + 1).clamp(1, 999);
    });
  }

  void _decrementQty(int index) {
    final item = widget.cartItems[index];
    final currentQty = item['quantity'] as int;
    if (currentQty > 1) {
      setState(() {
        item['quantity'] = currentQty - 1;
      });
    } else {
      widget.onRemoveItem(item['cart_id']);
    }
  }

  int _getCartTotalCount() {
    return widget.cartItems.fold(
      0,
      (sum, item) => sum + (item['quantity'] as int),
    );
  }

  @override
  void didUpdateWidget(covariant CartSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Smart auto-selection: Follow the last addition or increment only if it changed
    if (widget.cartItems.isNotEmpty) {
      // ONLY trigger auto-select/scroll if the parent explicitly modified a NEW item
      bool idChanged =
          widget.lastModifiedCartId != null &&
          widget.lastModifiedCartId != oldWidget.lastModifiedCartId;

      if (idChanged) {
        int targetSelection = widget.cartItems.indexWhere(
          (it) => it['cart_id'] == widget.lastModifiedCartId,
        );

        if (targetSelection != -1 &&
            targetSelection < widget.cartItems.length) {
          _selectedItemIndex = targetSelection;
          _numpadBuffer = "";
          _isFirstInput = true;
        }
      } else if (_selectedItemIndex == -1) {
        // Fallback: if absolutely nothing is selected yet, pick the first one
        _selectedItemIndex = 0;
      }
    } else {
      _selectedItemIndex = -1;
    }

    // If cart is empty and we are still in payment mode, auto-reset to cart view
    if (widget.cartItems.isEmpty && _isPaymentMode) {
      // Use post-frame callback to avoid setState() during build error
      // when notifying parent about mode change
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _numpadBuffer = "";
          _isFirstInput = true;
          _selectedItemIndex = -1;
          _isPaymentMode = false;
          _cashReceived = 0;
          _cashController.clear();
        });
        // Ensure parent knows we are no longer in payment mode
        widget.onModeChanged?.call(false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = Color(0xFFFF8E53);

    double subTotal = widget.cartItems.fold(
      0,
      (sum, item) =>
          sum + ((item['price'] as double) * (item['quantity'] as int)),
    );
    double discount = widget.discountData?['total_discount'] ?? 0.0;
    double total = subTotal - discount;
    if (total < 0) total = 0;

    double change = _cashReceived - total;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop =
            constraints.maxWidth >= 600 ||
            MediaQuery.of(context).size.width >= 720;
        final isNarrow = constraints.maxWidth < 320;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
            border: Border(
              left: BorderSide(
                color: isDark ? Colors.white10 : Colors.grey[200]!,
              ),
            ),
          ),
          child: SafeArea(
            top: !isDesktop,
            bottom: !isDesktop,
            child: Column(
              children: [
                _buildHeader(isDark, primaryColor, isDesktop, isNarrow),
                Expanded(
                  child: _isPaymentMode
                      ? _buildPaymentView(
                          isDark,
                          primaryColor,
                          subTotal,
                          discount,
                          total,
                          change,
                          isDesktop,
                          isNarrow,
                        )
                      : _buildCartView(
                          isDark,
                          primaryColor,
                          total,
                          isDesktop,
                          isNarrow,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    bool isDark,
    Color primaryColor,
    bool isDesktop,
    bool isNarrow,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isNarrow ? 12 : 24,
        isDesktop ? 24 : 16,
        isNarrow ? 12 : 16,
        16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (_isPaymentMode)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => setState(() {
                      _isPaymentMode = false;
                      _numpadBuffer = "";
                      _isFirstInput = true;
                    }),
                  ),
                if (isDesktop && widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close_fullscreen_rounded, size: 20),
                    onPressed: widget.onClose,
                    tooltip: "Sembunyikan",
                    color: Colors.grey,
                  ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _isPaymentMode
                        ? "Pembayaran"
                        : (isDesktop ? "Detail Pesanan" : "Keranjang"),
                    style: GoogleFonts.poppins(
                      fontSize: isNarrow ? 16 : (isDesktop ? 22 : 20),
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF2D3436),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isDesktop && !_isPaymentMode && widget.cartItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Text(
                              "Batalkan Transaksi?",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: Text(
                              "Semua item dalam keranjang akan dihapus. Lanjutkan?",
                              style: GoogleFonts.inter(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(
                                  "Tidak",
                                  style: GoogleFonts.inter(color: Colors.grey),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  widget.onAbortTransaction?.call();
                                },
                                child: Text(
                                  "Ya, Batal",
                                  style: GoogleFonts.inter(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.grey,
                        size: 20,
                      ),
                      tooltip: "Batalkan Pesanan",
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              if (!isDesktop && !_isPaymentMode && widget.cartItems.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    widget.onAbortTransaction?.call();
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  label: Text(
                    "Batal",
                    style: GoogleFonts.inter(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (widget.cartItems.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${_getCartTotalCount()} Item",
                    style: GoogleFonts.inter(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartView(
    bool isDark,
    Color primaryColor,
    double total,
    bool isDesktop,
    bool isNarrow,
  ) {
    if (widget.cartItems.isEmpty && !isDesktop) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.cart,
              size: 80,
              color: isDark ? Colors.white10 : Colors.grey[200],
            ),
            const SizedBox(height: 16),
            Text(
              "Keranjang kosong",
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: widget.cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.cart,
                        size: 80,
                        color: isDark ? Colors.white10 : Colors.grey[200],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Keranjang kosong",
                        style: GoogleFonts.inter(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(
                    isNarrow ? 12 : 24,
                    16,
                    isNarrow ? 12 : 24,
                    24,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.cartItems.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = widget.cartItems[i];
                    final Product p = item['product'];
                    final qty = item['quantity'] as int;
                    final price = item['price'] as double;
                    final isSelected = _selectedItemIndex == i;

                    final appliedIds =
                        widget.discountData?['applied_cart_ids'] as List? ?? [];
                    final itemDiscounts =
                        widget.discountData?['item_discounts'] as Map? ?? {};
                    final isPromo = appliedIds.contains(item['cart_id']);
                    final itemDiscount =
                        itemDiscounts[item['cart_id']] as double? ?? 0.0;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedItemIndex = i;
                          _numpadBuffer = "";
                          _isFirstInput = true;
                        });
                      },
                      borderRadius: BorderRadius.circular(isDesktop ? 12 : 20),
                      child: Container(
                        padding: EdgeInsets.all(
                          isNarrow ? 8 : (isDesktop ? 10 : 16),
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(
                            isDesktop || isNarrow ? 12 : 20,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name ?? "Unknown",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isNarrow
                                          ? 13
                                          : (isDesktop ? 14 : 16),
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currencyFormat.format(price),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.grey[600]!,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (isPromo)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          itemDiscount > 0
                                              ? "PROMO -${_currencyFormat.format(itemDiscount)}"
                                              : "PROMO",
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (true) ...[
                                    // Qty Controls
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildQtyBtn(
                                          Icons.remove,
                                          () => _decrementQty(i),
                                          isDark,
                                          primaryColor,
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isNarrow ? 8 : 12,
                                          ),
                                          child: Text(
                                            "$qty",
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              fontSize: isNarrow ? 14 : 16,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        _buildQtyBtn(
                                          Icons.add,
                                          () => _incrementQty(i),
                                          isDark,
                                          primaryColor,
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _currencyFormat.format(price * qty),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isNarrow
                                          ? 13
                                          : (isDesktop ? 16 : 15),
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                IconButton(
                                  onPressed: () =>
                                      widget.onRemoveItem(item['cart_id']),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        _buildSummaryAndNumpad(isDark, primaryColor, total, isDesktop),
      ],
    );
  }

  Widget _buildQtyBtn(
    IconData icon,
    VoidCallback onTap,
    bool isDark,
    Color primaryColor,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: primaryColor),
      ),
    );
  }

  Widget _buildSummaryAndNumpad(
    bool isDark,
    Color primaryColor,
    double total,
    bool isDesktop,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        _buildOdooSummary(isDark, primaryColor),
        SizedBox(
          height: 200,
          child: OrderNumpad(
            mode: _numpadMode,
            onModeChanged: (m) => setState(() {
              _numpadMode = m;
              _isFirstInput = true;
            }),
            onTap: _handleOrderNumpadTap,
            onBackspace: _handleOrderNumpadBackspace,
            onToggleSign: _handleOrderNumpadToggleSign,
          ),
        ),
        _buildCartActionButton(primaryColor, total, isDesktop),
      ],
    );
  }

  Widget _buildCartActionButton(
    Color primaryColor,
    double total,
    bool isDesktop,
  ) {
    final totalQty = _getCartTotalCount();
    final hasItems = widget.cartItems.isNotEmpty && totalQty > 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, isDesktop ? 16 : 8),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: isDesktop ? 52 : 56,
            child: ElevatedButton(
              onPressed: hasItems
                  ? () => setState(() {
                      _isPaymentMode = true;
                      _selectedPaymentMethod = "Tunai"; // Default for mobile
                    })
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Pilih Pembayaran",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOdooSummary(bool isDark, Color primaryColor) {
    double subTotal = widget.cartItems.fold(
      0,
      (sum, item) =>
          sum + ((item['price'] as double) * (item['quantity'] as int)),
    );
    double discount = widget.discountData?['total_discount'] ?? 0.0;
    double total = subTotal - discount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey[50],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  "Total (${_getCartTotalCount()} Item)",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _currencyFormat.format(total),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentView(
    bool isDark,
    Color primaryColor,
    double subTotal,
    double discount,
    double total,
    double change,
    bool isDesktop,
    bool isNarrow,
  ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Pelanggan (Loyalty)",
                                style: GoogleFonts.inter(
                                  fontSize: isNarrow ? 12 : 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey[600],
                                ),
                              ),
                              if (widget.selectedCustomer != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: primaryColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          widget.selectedCustomer!.name ?? "-",
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () => widget.onCustomerSelected
                                              ?.call(null),
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 14,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Row(
                            children: [
                              // Search button
                              IconButton(
                                onPressed: () =>
                                    _showCustomerSearchDialog(isDark),
                                icon: Icon(
                                  Icons.search_rounded,
                                  size: 22,
                                  color: widget.selectedCustomer != null
                                      ? primaryColor
                                      : Colors.grey[600],
                                ),
                                tooltip: "Pilih Pelanggan",
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              // Add button
                              IconButton(
                                onPressed: () => _showAddCustomerDialog(isDark),
                                icon: Icon(
                                  Icons.person_add_alt_1_rounded,
                                  size: 22,
                                  color: primaryColor,
                                ),
                                tooltip: "Tambah Pelanggan Baru",
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              "Metode Pembayaran",
                              style: GoogleFonts.inter(
                                fontSize: isNarrow ? 12 : 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          FutureBuilder<List<PaymentMethod>>(
                            future: context
                                .read<AdminController>()
                                .paymentMethodService
                                .getPaymentMethods(
                                  context.read<AdminController>().storeId ?? '',
                                )
                                .then(
                                  (list) =>
                                      list.where((m) => m.isActive).toList(),
                                ),
                            builder: (context, snapshot) {
                              final customMethods = snapshot.data ?? [];
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildPaymentMethodIcon(
                                    "Tunai",
                                    Icons.payments_outlined,
                                    total,
                                    isNarrow: isNarrow,
                                  ),
                                  if (customMethods.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    _buildPaymentMethodIcon(
                                      _selectedPaymentMethod == "Tunai"
                                          ? "Digital"
                                          : _selectedPaymentMethod,
                                      Icons.account_balance_wallet_outlined,
                                      total,
                                      onTap: () => _showPaymentMethodPicker(
                                        customMethods,
                                        total,
                                        primaryColor,
                                        isDark,
                                      ),
                                      isSelected:
                                          _selectedPaymentMethod != "Tunai",
                                      isNarrow: isNarrow,
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_selectedPaymentMethod == "Tunai") ...[
                        const SizedBox(height: 24),
                        Text(
                          "Uang Diterima",
                          style: GoogleFonts.inter(
                            fontSize: isNarrow ? 12 : 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _cashController,
                          readOnly: true,
                          showCursor: true,
                          keyboardType: TextInputType.none,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                          decoration: InputDecoration(
                            hintText: "0",
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 18),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Rp",
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {
                                widget.onAbortTransaction?.call();
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildQuickCashBtn("Pas", total),
                              _buildQuickCashBtn("10rb", 10000),
                              _buildQuickCashBtn("20rb", 20000),
                              _buildQuickCashBtn("50rb", 50000),
                              _buildQuickCashBtn("100rb", 100000),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        // Fixed Summary, Numpad and Button at the bottom (Symmetrical with Cart Mode)
        const Divider(height: 1),

        // Payment Summary Section (Reusing similar style as OdooSummary)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          color: isDark
              ? Colors.white.withValues(alpha: 0.02)
              : Colors.grey[50],
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Total Bayar",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _currencyFormat.format(total),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Numpad remains at the bottom, matching Cart Mode size exactly
        SizedBox(
          height: 200,
          child: Opacity(
            opacity: _selectedPaymentMethod == "Tunai" ? 1.0 : 0.5,
            child: IgnorePointer(
              ignoring: _selectedPaymentMethod != "Tunai",
              child: OrderNumpad(
                mode: _numpadMode,
                onModeChanged:
                    (_) {}, // Mode buttons are static deco in payment
                onTap: _handleNumpadTap,
                onBackspace: () => _handleNumpadTap("backspace"),
                onToggleSign: () {},
              ),
            ),
          ),
        ),

        // Main Action Button (Symmetrical with Cart Mode)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: widget.isProcessing
                  ? null
                  : () {
                      if (_selectedPaymentMethod == "Tunai" &&
                          _cashReceived < total) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Uang kurang"),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      widget.onCheckout(_cashReceived, _selectedPaymentMethod);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: widget.isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "Konfirmasi Pembayaran",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCustomerSearchDialog(bool isDark) {
    final searchCtrl = TextEditingController();
    final db = context.read<AppDatabase>();
    List<Customer> allCustomers = [];
    List<Customer> filtered = [];
    const primaryColor = Color(0xFFEA5700);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => StatefulBuilder(
        builder: (context, ss) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handlebar
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      "Pilih Pelanggan",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey[200]!,
                    ),
                  ),
                  child: TextField(
                    controller: searchCtrl,
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: "Cari nama atau nomor HP...",
                      hintStyle: GoogleFonts.inter(color: Colors.grey),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: primaryColor,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    onChanged: (val) {
                      ss(() {
                        filtered = allCustomers
                            .where(
                              (c) =>
                                  (c.name?.toLowerCase().contains(
                                        val.toLowerCase(),
                                      ) ??
                                      false) ||
                                  (c.phoneNumber?.contains(val) ?? false),
                            )
                            .toList();
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Results List
              Expanded(
                child: FutureBuilder<List<Customer>>(
                  future: (db.select(db.customers)).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        allCustomers.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (allCustomers.isEmpty && snapshot.hasData) {
                      allCustomers = snapshot.data!;
                      filtered = allCustomers;
                    }

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_search_rounded,
                                size: 60,
                                color: primaryColor.withValues(alpha: 0.3),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Pelanggan tidak ditemukan",
                              style: GoogleFonts.inter(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Coba cari dengan kata kunci lain",
                              style: GoogleFonts.inter(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: filtered.length,
                      itemBuilder: (c, i) {
                        final cust = filtered[i];
                        final isSelected =
                            widget.selectedCustomer?.id == cust.id;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              widget.onCustomerSelected?.call(cust);
                              Navigator.pop(ctx);
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor.withValues(alpha: 0.05)
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.02)
                                          : Colors.white),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor
                                      : (isDark
                                            ? Colors.white10
                                            : Colors.grey[200]!),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: [
                                  if (!isDark && !isSelected)
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: primaryColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    child: Text(
                                      cust.name
                                              ?.substring(0, 1)
                                              .toUpperCase() ??
                                          "P",
                                      style: GoogleFonts.poppins(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cust.name ?? "-",
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.phone_iphone_rounded,
                                              size: 12,
                                              color: Colors.grey[500],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              cust.phoneNumber ??
                                                  "Tanpa nomor HP",
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          "${cust.points}",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: primaryColor,
                                          ),
                                        ),
                                        Text(
                                          "Poin",
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor.withValues(
                                              alpha: 0.7,
                                            ),
                                          ),
                                        ),
                                      ],
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCustomerDialog(bool isDark) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final admin = context.read<AdminController>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Tambah Pelanggan Baru",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: "Nama Lengkap",
                labelStyle: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: "No. HP",
                labelStyle: TextStyle(color: Colors.grey[600]),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: "Email (Opsional)",
                labelStyle: TextStyle(color: Colors.grey[600]),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final db = context.read<AppDatabase>();
                // We'll use the CustomerService logic directly or via provider if available
                // Based on imports, CustomerService is not imported here.
                // I should add the import or use the db directly.
                // Let's check imports in cart_sidebar.dart
                final id = "CUST-${DateTime.now().millisecondsSinceEpoch}";
                final customer = Customer(
                  id: id,
                  storeId: admin.storeId,
                  name: nameController.text,
                  phoneNumber: phoneController.text,
                  email: emailController.text,
                  points: 0,
                  createdAt: DateTime.now(),
                );

                await db.into(db.customers).insert(customer);

                if (!context.mounted) return;
                widget.onCustomerSelected?.call(customer);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA5700),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Simpan & Pilih"),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodIcon(
    String label,
    IconData icon,
    double total, {
    PaymentMethod? method,
    VoidCallback? onTap,
    bool? isSelected,
    bool isNarrow = false,
  }) {
    final selected = isSelected ?? (_selectedPaymentMethod == label);
    const primaryColor = Color(0xFFEA5700);
    return InkWell(
      onTap:
          onTap ??
          () {
            setState(() {
              _selectedPaymentMethod = label;
              if (label != "Tunai") {
                _cashReceived = total;
                _cashController.text = NumberFormat.decimalPattern(
                  'id',
                ).format(total);
              }
            });
          },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height: 38,
        decoration: BoxDecoration(
          color: selected
              ? primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: selected ? primaryColor : Colors.grey.withValues(alpha: 0.2),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? primaryColor : Colors.grey, size: 18),
            if (label != "Tunai") ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: isNarrow ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? primaryColor : Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPaymentMethodPicker(
    List<PaymentMethod> methods,
    double total,
    Color primaryColor,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Pilih Metode Digital",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...methods.map((m) {
              final isSelected = _selectedPaymentMethod == m.name;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = m.name;
                      _cashReceived = total;
                      _cashController.text = NumberFormat.decimalPattern(
                        'id',
                      ).format(total);
                    });
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withValues(alpha: 0.05)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? primaryColor
                            : Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          m.type == 'qris'
                              ? Icons.qr_code_scanner
                              : Icons.account_balance_wallet,
                          color: isSelected ? primaryColor : Colors.grey,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.name,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? primaryColor
                                      : (isDark
                                            ? Colors.white
                                            : Colors.black87),
                                ),
                              ),
                              if (m.username != null)
                                Text(
                                  "A.N. ${m.username}",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              if (m.details != null)
                                Text(
                                  m.details!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (m.type == 'qris' && m.qrisUrl != null)
                          IconButton(
                            icon: const Icon(Icons.qr_code, size: 20),
                            onPressed: () => _showQRISDialog(m),
                            color: primaryColor,
                          ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: primaryColor),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCashBtn(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: ActionChip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          setState(() {
            _cashReceived = amount;
            _cashController.text = NumberFormat.decimalPattern(
              'id',
            ).format(amount);
          });
        },
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        backgroundColor: Colors.grey.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
      ),
    );
  }

  void _showQRISDialog(PaymentMethod method) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    method.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (method.qrisUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image(
                  image: FileManager().getImageProvider(method.qrisUrl!),
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 16),
            if (method.username != null && method.username!.isNotEmpty)
              Text(
                "A.N. ${method.username}",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            if (method.details != null && method.details!.isNotEmpty)
              Text(
                method.details!,
                style: GoogleFonts.inter(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

class DottedLine extends StatelessWidget {
  const DottedLine({super.key});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey),
              ),
            );
          }),
        );
      },
    );
  }
}
