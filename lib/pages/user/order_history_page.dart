import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/order_service.dart';
import '../../services/app_database.dart';
import 'package:provider/provider.dart';
import '../../widgets/kasir_drawer.dart';
import 'widgets/kasir_side_navigation.dart';

import '../../../controllers/admin_controller.dart';

class OrderHistoryPage extends StatefulWidget {
  final bool showSidebar;
  final VoidCallback? onMenuPressed;
  const OrderHistoryPage({
    super.key,
    this.showSidebar = true,
    this.onMenuPressed,
  });

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  late OrderService _orderService;
  String? _storeId;
  bool _isLoading = true;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = context.read<AppDatabase>();
      _orderService = OrderService(db);
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final admin = context.read<AdminController>();
    if (admin.storeId != null) {
      if (mounted) {
        setState(() {
          _storeId = admin.storeId;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          "Riwayat Pesanan",
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
            final isWide = MediaQuery.of(ctx).size.width >= 900;
            if (isWide) return const SizedBox.shrink();
            return IconButton(
              icon: Icon(
                CupertinoIcons.bars,
                color: isDark ? Colors.white : const Color(0xFF2D3436),
              ),
              onPressed: () {
                if (widget.onMenuPressed != null) {
                  widget.onMenuPressed!();
                } else {
                  Scaffold.of(ctx).openDrawer();
                }
              },
            );
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _storeId == null
          ? const Center(child: Text("Toko tidak ditemukan"))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _orderService.getTodayOrders(_storeId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snapshot.data ?? [];

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 80,
                          color: isDark ? Colors.white10 : Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Belum ada pesanan hari ini.",
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white38 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final items =
                        (order['transaction_items'] ??
                                order['transactionItems'])
                            as List? ??
                        [];

                    final rawDate = order['createdAt'] ?? order['created_at'];
                    DateTime date;
                    if (rawDate is DateTime) {
                      date = rawDate.toLocal();
                    } else if (rawDate != null) {
                      date =
                          DateTime.tryParse(rawDate.toString())?.toLocal() ??
                          DateTime.now();
                    } else {
                      date = DateTime.now();
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.03,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Colors.green,
                          ),
                        ),
                        title: Text(
                          _currencyFormat.format(
                            order['totalAmount'] ?? order['total_amount'] ?? 0,
                          ),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF2D3436),
                          ),
                        ),
                        subtitle: Text(
                          DateFormat('HH:mm').format(date),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                        children: [
                          const Divider(),
                          ...items.map((item) {
                            final productName =
                                item['productName'] ??
                                item['product_name'] ??
                                'Product';
                            final qty = item['quantity'] ?? 0;
                            final price =
                                item['unitPrice'] ?? item['unit_price'] ?? 0;
                            return ListTile(
                              dense: true,
                              title: Text(
                                productName,
                                style: GoogleFonts.inter(
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                "${qty}x ${_currencyFormat.format(price)}",
                                style: GoogleFonts.inter(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey[600],
                                ),
                              ),
                              trailing: Text(
                                _currencyFormat.format(qty * price),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );

    return Scaffold(
      drawer: widget.showSidebar
          ? const KasirDrawer(currentRoute: '/order-history')
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          if (isWide && widget.showSidebar) {
            return Row(
              children: [
                const KasirSideNavigation(currentRoute: '/order-history'),
                Expanded(child: content),
              ],
            );
          }
          return content;
        },
      ),
    );
  }
}
