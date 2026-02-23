import 'package:flutter/material.dart';
import '../../../services/platform/file_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/app_database.dart';

class CartSidebar extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Map<String, dynamic>? discountData;
  final Function(String cartId) onRemoveItem;
  final Function(Product product, {List? options, String? notes, double? price})
  onAddItem;
  final Function(double cashReceived, String paymentMethod) onCheckout;
  final bool isProcessing;
  final Customer? selectedCustomer;
  final Function(Customer? customer) onCustomerChanged;

  const CartSidebar({
    super.key,
    required this.cartItems,
    this.discountData,
    required this.onRemoveItem,
    required this.onAddItem,
    required this.onCheckout,
    required this.isProcessing,
    this.selectedCustomer,
    required this.onCustomerChanged,
  });

  @override
  State<CartSidebar> createState() => _CartSidebarState();
}

class _CartSidebarState extends State<CartSidebar> {
  final TextEditingController _cashController = TextEditingController();
  double _cashReceived = 0;
  String _selectedPaymentMethod = "Tunai";

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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
        border: Border(
          left: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Invoice",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF2D3436),
                    ),
                  ),
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
            ),

            // Customer Selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: InkWell(
                onTap: () => _showCustomerPicker(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.selectedCustomer == null
                              ? CupertinoIcons.person_add
                              : CupertinoIcons.person_fill,
                          color: primaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.selectedCustomer?.name ??
                                  "Pilih Pelanggan",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: widget.selectedCustomer == null
                                    ? Colors.grey
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                            if (widget.selectedCustomer != null)
                              Text(
                                "${widget.selectedCustomer!.points} Points",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (widget.selectedCustomer != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => widget.onCustomerChanged(null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
                      else
                        const Icon(
                          CupertinoIcons.chevron_right,
                          size: 14,
                          color: Colors.grey,
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Cart Items List
            widget.cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.cart,
                          size: 60,
                          color: isDark ? Colors.white10 : Colors.grey[200],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No items in cart",
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: widget.cartItems.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final item = widget.cartItems[i];
                      final Product p = item['product'];
                      final qty = item['quantity'] as int;
                      final price = item['price'] as double;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
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
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 44,
                                height: 44,
                                color: isDark
                                    ? Colors.white12
                                    : Colors.grey[100],
                                child: p.imageUrl != null
                                    ? Image(
                                        image: FileManager().getImageProvider(
                                          p.imageUrl!,
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(
                                        Icons.fastfood,
                                        color: Colors.grey[400],
                                        size: 20,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name ?? "Unknown",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _currencyFormat.format(price),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _buildQtyBtn(
                                  CupertinoIcons.minus,
                                  () => widget.onRemoveItem(item['cart_id']),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Text(
                                    "$qty",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Builder(
                                  builder: (context) {
                                    final totalInCart = widget.cartItems
                                        .where(
                                          (ci) =>
                                              (ci['product'] as Product).id ==
                                              p.id,
                                        )
                                        .fold<int>(
                                          0,
                                          (sum, ci) =>
                                              sum + (ci['quantity'] as int),
                                        );
                                    final bool isStockReached =
                                        p.isStockManaged &&
                                        totalInCart >= (p.stockQuantity ?? 0);

                                    return _buildQtyBtn(
                                      CupertinoIcons.plus,
                                      isStockReached
                                          ? null
                                          : () {
                                              widget.onAddItem(
                                                p,
                                                options:
                                                    item['selected_options'],
                                                notes: item['notes'],
                                                price: item['price'],
                                              );
                                            },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

            // Payment Summary Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Payment Summary",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_selectedPaymentMethod == "Tunai") ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _cashController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                      decoration: InputDecoration(
                        labelText: "Cash Received",
                        prefixText: "Rp ",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              _cashController.clear();
                              _cashReceived = 0;
                            });
                          },
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _cashReceived =
                              double.tryParse(
                                val.replaceAll(RegExp(r'[^0-9]'), ''),
                              ) ??
                              0;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildQuickCashBtn("Exact", total),
                          _buildQuickCashBtn("50k", 50000),
                          _buildQuickCashBtn("100k", 100000),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _buildSummaryLine("Sub Total", subTotal),
                  if (discount > 0) ...[
                    _buildSummaryLine("Diskon", discount, isNegative: true),
                    if (widget.discountData?['promo_names'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          (widget.discountData!['promo_names'] as List).join(
                            ", ",
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.green,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                  _buildSummaryLine("Tax", 0),
                  if (_selectedPaymentMethod == "Tunai" && _cashReceived > 0)
                    _buildSummaryLine("Change", change > 0 ? change : 0),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: DottedLine(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Payment",
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
                  const SizedBox(height: 20),
                  Text(
                    "Payment Method",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildPaymentMethodIcon("Tunai", Icons.payments_outlined),
                      const SizedBox(width: 12),
                      _buildPaymentMethodIcon("QRIS", Icons.qr_code_scanner),
                      const SizedBox(width: 12),
                      _buildPaymentMethodIcon(
                        "Transfer",
                        Icons.account_balance_wallet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          (widget.isProcessing ||
                              widget.cartItems.isEmpty ||
                              (_selectedPaymentMethod == "Tunai" &&
                                  _cashReceived < total))
                          ? null
                          : () => widget.onCheckout(
                              _cashReceived,
                              _selectedPaymentMethod,
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: widget.isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "Place An Order Now",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback? onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDisabled
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey[50])
              : (isDark ? Colors.white10 : Colors.grey[100]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isDisabled
              ? Colors.grey.withValues(alpha: 0.3)
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildSummaryLine(
    String label,
    double amount, {
    bool isNegative = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
          ),
          Text(
            (isNegative ? "- " : "") + _currencyFormat.format(amount),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
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
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPaymentMethod = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : Colors.grey.withValues(alpha: 0.2),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isSelected ? primaryColor : Colors.grey,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCashBtn(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: () {
          setState(() {
            _cashReceived = amount;
            _cashController.text = amount.toInt().toString();
          });
        },
        visualDensity: VisualDensity.compact,
        backgroundColor: Colors.grey.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
      ),
    );
  }

  void _showCustomerPicker(BuildContext context) async {
    final db = context.read<AppDatabase>();
    final customers = await db.select(db.customers).get();

    if (!mounted) return;
    // Capture the widget's context after confirming it is still mounted,
    // so we can safely use it in the modal sheet below.
    final safeCtx = this.context;

    showModalBottomSheet(
      // ignore: use_build_context_synchronously
      context: safeCtx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bCtx) => Container(
        height: MediaQuery.of(bCtx).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(bCtx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Pilih Pelanggan",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(bCtx),
                    child: const Text("Tutup"),
                  ),
                ],
              ),
            ),
            Expanded(
              child: customers.isEmpty
                  ? Center(
                      child: Text(
                        "Belum ada pelanggan",
                        style: GoogleFonts.inter(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final c = customers[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: const Color(
                              0xFFEA5700,
                            ).withValues(alpha: 0.1),
                            child: Text(
                              (c.name?.isNotEmpty == true ? c.name![0] : "?")
                                  .toUpperCase(),
                              style: const TextStyle(color: Color(0xFFEA5700)),
                            ),
                          ),
                          title: Text(
                            c.name ?? "Pelanggan",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            "${c.phoneNumber ?? ''} • ${c.points} Points",
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                          onTap: () {
                            widget.onCustomerChanged(c);
                            Navigator.pop(bCtx);
                          },
                        );
                      },
                    ),
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
