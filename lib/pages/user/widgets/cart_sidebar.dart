import 'package:flutter/material.dart';
import '../../../services/platform/file_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../services/app_database.dart';
import '../../../widgets/custom_numpad.dart';
import '../../../widgets/order_numpad.dart';

class CartSidebar extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Map<String, dynamic>? discountData;
  final Function(String cartId) onRemoveItem;
  final Function(Product product, {List? options, String? notes, double? price})
  onAddItem;
  final Function(double cashReceived, String paymentMethod) onCheckout;
  final Function(bool isPaymentMode)? onModeChanged;
  final bool isProcessing;

  const CartSidebar({
    super.key,
    required this.cartItems,
    this.discountData,
    required this.onRemoveItem,
    required this.onAddItem,
    required this.onCheckout,
    this.onModeChanged,
    required this.isProcessing,
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

  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _cashController.dispose();
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
      if (!rawValue.contains(".") && rawValue.length < 11 && rawValue.isNotEmpty) {
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
      _cashController.text = NumberFormat.decimalPattern('id').format(_cashReceived);
    }
    setState(() {});
  }

  void _handleOrderNumpadTap(String val) {
    if (_selectedItemIndex == -1 || _selectedItemIndex >= widget.cartItems.length) return;

    if (val == ".") {
      if (!_numpadBuffer.contains(".")) {
        _numpadBuffer += ".";
      }
    } else {
      _numpadBuffer += val;
    }

    _applyNumpadValue();
  }

  void _handleOrderNumpadBackspace() {
    if (_numpadBuffer.isNotEmpty) {
      _numpadBuffer = _numpadBuffer.substring(0, _numpadBuffer.length - 1);
      _applyNumpadValue();
    } else {
      // If buffer empty, maybe reset the value? 
      // Odoo usually keeps the value until new input.
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
    if (_selectedItemIndex == -1) return;
    
    final item = widget.cartItems[_selectedItemIndex];
    double val = double.tryParse(_numpadBuffer) ?? 0;

    setState(() {
      if (_numpadMode == OrderNumpadMode.qty) {
        item['quantity'] = val.toInt().clamp(1, 999);
      } else if (_numpadMode == OrderNumpadMode.disc) {
        // Handle discount (percentage or amount? standard is percentage in Odoo '%')
        // For now let's assume it updates price or a disc field if we have one.
        // Our cart items don't have a direct 'discount' field yet, they have 'price'.
        // Let's just update 'price' for 'Price' mode.
      } else if (_numpadMode == OrderNumpadMode.price) {
        item['price'] = val;
      }
    });
  }

  int _getCartTotalCount() {
    return widget.cartItems.fold(
      0,
      (sum, item) => sum + (item['quantity'] as int),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = Color(0xFFEA5700);

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
        final isDesktop = constraints.maxWidth >= 380 || MediaQuery.of(context).size.width >= 720;
        
        // On desktop, we hide the "Next to Payment" button and can auto-show payment details
        // if the user wants it to be faster. 
        
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
            border: Border(
              left: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(isDark, primaryColor, isDesktop),
              Expanded(
                child: _isPaymentMode
                    ? _buildPaymentView(isDark, primaryColor, subTotal, discount, total, change, isDesktop)
                    : _buildCartView(isDark, primaryColor, isDesktop),
              ),
              if (!isDesktop) _buildBottomAction(primaryColor, total),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark, Color primaryColor, bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (_isPaymentMode)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => setState(() => _isPaymentMode = false),
                )
              else if (!isDesktop) // Only show close on mobile sidebar
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              const SizedBox(width: 8),
              Text(
                _isPaymentMode ? "Pembayaran" : "Keranjang",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }

  Widget _buildCartView(bool isDark, Color primaryColor, bool isDesktop) {
    if (widget.cartItems.isEmpty) {
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
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: widget.cartItems.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final item = widget.cartItems[i];
              final Product p = item['product'];
              final qty = item['quantity'] as int;
              final price = item['price'] as double;
              final isSelected = _selectedItemIndex == i;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedItemIndex = i;
                    _numpadBuffer = ""; // Reset buffer on selection
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 56,
                          height: 56,
                          color: isDark ? Colors.white10 : Colors.grey[100],
                          child: p.imageUrl != null
                              ? Image(
                                  image: FileManager().getImageProvider(p.imageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : Icon(Icons.fastfood, color: Colors.grey[400]),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name ?? "Unknown",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$qty x ${_currencyFormat.format(price)}",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isSelected ? primaryColor : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _currencyFormat.format(price * qty),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (isDesktop) ...[
          const Divider(height: 1),
          _buildOdooSummary(isDark, primaryColor),
          OrderNumpad(
            mode: _numpadMode,
            onModeChanged: (m) => setState(() => _numpadMode = m),
            onTap: _handleOrderNumpadTap,
            onBackspace: _handleOrderNumpadBackspace,
            onToggleSign: _handleOrderNumpadToggleSign,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: widget.cartItems.isEmpty 
                  ? null 
                  : () => setState(() => _isPaymentMode = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5B7B), // Odoo-like purple-ish color
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  "Payment",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOdooSummary(bool isDark, Color primaryColor) {
    double subTotal = widget.cartItems.fold(
      0,
      (sum, item) => sum + ((item['price'] as double) * (item['quantity'] as int)),
    );
    double discount = widget.discountData?['total_discount'] ?? 0.0;
    double total = subTotal - discount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey[50],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Taxes", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
              Text(_currencyFormat.format(0), style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Text(
                _currencyFormat.format(total),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, 
                  fontSize: 22,
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
  ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                // Compact Payment Summary Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total Bayar",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
                        if (_selectedPaymentMethod == "Tunai") ...[
                          const SizedBox(height: 4),
                          _buildSummaryLine("Kembalian", change > 0 ? change : 0, isSmall: true),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Metode Pembayaran",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildPaymentMethodIcon("Tunai", Icons.payments_outlined),
                              const SizedBox(width: 8),
                              _buildPaymentMethodIcon("QRIS", Icons.qr_code_scanner),
                              const SizedBox(width: 8),
                              _buildPaymentMethodIcon("Transfer", Icons.account_balance_wallet),
                            ],
                          ),
                        ],
                      ),

                      if (_selectedPaymentMethod == "Tunai") ...[
                        const SizedBox(height: 24),
                        Text(
                          "Uang Diterima",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _cashController,
                          readOnly: true,
                          showCursor: true,
                          keyboardType: TextInputType.none,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                          decoration: InputDecoration(
                            hintText: "0",
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 18, right: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Rp",
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear, size: 24),
                              onPressed: () {
                                setState(() {
                                  _cashController.clear();
                                  _cashReceived = 0;
                                });
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
        // Numpad remains at the bottom, not inside scroll view to keep it fixed and avoid "police line"
        if (_selectedPaymentMethod == "Tunai")
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: CustomNumpad(
              onTap: _handleNumpadTap,
              onConfirm: () {
                if (widget.isProcessing) return;
                if (_selectedPaymentMethod == "Tunai" && _cashReceived < total) {
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
            ),
          )
        else if (isDesktop)
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: widget.isProcessing
                    ? null
                    : () => widget.onCheckout(_cashReceived, _selectedPaymentMethod),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: widget.isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Konfirmasi Pembayaran"),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomAction(Color primaryColor, double total) {
    // Hide bottom button on payment screen if using Tunai (keyboard has its own button)
    if (_isPaymentMode && _selectedPaymentMethod == "Tunai") {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: widget.cartItems.isEmpty
                ? null
                : (_isPaymentMode
                    ? ((widget.isProcessing ||
                            (_selectedPaymentMethod == "Tunai" && _cashReceived < total))
                        ? null
                        : () => widget.onCheckout(_cashReceived, _selectedPaymentMethod))
                    : () {
                        setState(() => _isPaymentMode = true);
                        widget.onModeChanged?.call(true);
                      }),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            ),
            child: widget.isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    _isPaymentMode ? "Konfirmasi Pembayaran" : "Lanjut ke Pembayaran",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSummaryLine(
    String label,
    double amount, {
    bool isNegative = false,
    bool isSmall = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmall ? 2 : 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.grey[600],
              fontSize: isSmall ? 10 : 12,
            ),
          ),
          Text(
            (isNegative ? "- " : "") + _currencyFormat.format(amount),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: isSmall ? 11 : 13,
              color: isNegative ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodIcon(String label, IconData icon) {
    final isSelected = _selectedPaymentMethod == label;
    const primaryColor = Color(0xFFEA5700);
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = label),
      child: Container(
        width: 50,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.withValues(alpha: 0.2),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isSelected ? primaryColor : Colors.grey,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildQuickCashBtn(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        onPressed: () {
          setState(() {
            _cashReceived = amount;
            _cashController.text = NumberFormat.decimalPattern('id').format(amount);
          });
        },
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        backgroundColor: Colors.grey.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
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
