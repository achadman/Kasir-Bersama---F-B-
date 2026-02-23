import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../widgets/floating_card.dart';
import '../../../services/receipt_service.dart';
import '../../../controllers/admin_controller.dart';
import '../../user/widgets/payment_success_dialog.dart';

class TransactionDetailPage extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final total = (transaction['totalAmount'] ?? 0 as num).toDouble();
    final items = List<Map<String, dynamic>>.from(
      transaction['transaction_items'] ?? [],
    );
    final rawDate = transaction['createdAt'];
    DateTime date;
    if (rawDate is DateTime) {
      date = rawDate.toLocal();
    } else if (rawDate != null) {
      final str = rawDate.toString();
      final asInt = int.tryParse(str);
      if (asInt != null) {
        date = DateTime.fromMillisecondsSinceEpoch(asInt).toLocal();
      } else {
        date = DateTime.tryParse(str)?.toLocal() ?? DateTime.now();
      }
    } else {
      date = DateTime.now();
    }
    final cashierName = transaction['profiles']?['fullName'] ?? 'System';

    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Detail Transaksi",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF2D3436),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: isDark ? Colors.white : const Color(0xFF2D3436),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Receipt Header Card
            FloatingCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA5700).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.bag_fill,
                      color: Color(0xFFEA5700),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currencyFormat.format(total),
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFEA5700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "ID: #${transaction['id'].toString().substring(0, 8).toUpperCase()}",
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white54 : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Transaction Info
            FloatingCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoRow(
                    context,
                    "Waktu",
                    DateFormat('d MMM yyyy, HH:mm').format(date),
                    CupertinoIcons.time,
                  ),
                  const Divider(height: 32),
                  _buildInfoRow(
                    context,
                    "Kasir",
                    cashierName,
                    CupertinoIcons.person,
                  ),
                  const Divider(height: 32),
                  _buildInfoRow(
                    context,
                    "Metode Bayar",
                    transaction['paymentMethod']?.toString().toUpperCase() ??
                        "TUNAI",
                    CupertinoIcons.creditcard,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Items List
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  "DAFTAR BELANJA",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            FloatingCard(
              padding: const EdgeInsets.all(20),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final productName = item['productName'] ?? 'Produk';
                  final qty = item['quantity'] ?? 1;
                  final price = (item['unitPrice'] ?? 0 as num).toDouble();

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF2D3436),
                              ),
                            ),
                            Text(
                              "$qty x ${currencyFormat.format(price)}",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        currencyFormat.format(qty * price),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF2D3436),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            // Print Action
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final adminCtrl = context.read<AdminController>();
                  final receiptService = ReceiptService();

                  final pdfData = await receiptService.generateReceiptPdf(
                    storeName: adminCtrl.storeName ?? "Toko Asri",
                    storeLogoUrl: adminCtrl.storeLogo,
                    transactionId: transaction['id'].toString(),
                    createdAt: date,
                    items: items.map((it) {
                      return {
                        'name': it['productName'] ?? 'Produk',
                        'quantity': it['quantity'],
                        'total_price':
                            (it['unitPrice'] ?? 0 as num).toDouble() *
                            (it['quantity'] as num).toDouble(),
                      };
                    }).toList(),
                    totalAmount: total,
                    cashReceived:
                        (transaction['cashReceived'] as num?)?.toDouble() ??
                        total,
                    change: (transaction['change'] as num?)?.toDouble() ?? 0,
                    paymentMethod:
                        transaction['paymentMethod']?.toString() ?? "TUNAI",
                  );

                  if (context.mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => PaymentSuccessDialog(
                        pdfData: pdfData,
                        transactionId: transaction['id']
                            .toString()
                            .substring(0, 8)
                            .toUpperCase(),
                        totalAmount: total,
                        cashReceived:
                            (transaction['cashReceived'] as num?)?.toDouble() ??
                            total,
                        change:
                            (transaction['change'] as num?)?.toDouble() ?? 0,
                        storeName: adminCtrl.storeName ?? "Toko Asri",
                        createdAt: date,
                        items: items.map((it) {
                          return {
                            'name': it['productName'] ?? 'Produk',
                            'quantity': it['quantity'],
                            'total_price':
                                (it['unitPrice'] ?? 0 as num).toDouble() *
                                (it['quantity'] as num).toDouble(),
                          };
                        }).toList(),
                        paymentMethod:
                            transaction['paymentMethod']?.toString() ?? "TUNAI",
                        onNewTransaction: () {
                          // Just close the dialog
                        },
                      ),
                    );
                  }
                },
                icon: const Icon(CupertinoIcons.printer),
                label: Text(
                  "CETAK STRUK",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA5700),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final adminCtrl = context.read<AdminController>();
                  final receiptService = ReceiptService();

                  await receiptService.shareReceiptPdf(
                    storeName: adminCtrl.storeName ?? "Toko Asri",
                    storeLogoUrl: adminCtrl.storeLogo,
                    transactionId: transaction['id'].toString(),
                    createdAt: date,
                    items: items.map((it) {
                      return {
                        'name': it['productName'] ?? 'Produk',
                        'quantity': it['quantity'],
                        'total_price':
                            (it['unitPrice'] ?? 0 as num).toDouble() *
                            (it['quantity'] as num).toDouble(),
                      };
                    }).toList(),
                    totalAmount: total,
                    cashReceived:
                        (transaction['cashReceived'] as num?)?.toDouble() ??
                        total,
                    change: (transaction['change'] as num?)?.toDouble() ?? 0,
                    paymentMethod:
                        transaction['paymentMethod']?.toString() ?? "TUNAI",
                  );
                },
                icon: const Icon(CupertinoIcons.share),
                label: Text(
                  "BAGIKAN STRUK DIGITAL",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEA5700),
                  side: const BorderSide(color: Color(0xFFEA5700), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFEA5700)),
        const SizedBox(width: 16),
        Text(
          label,
          style: GoogleFonts.inter(
            color: isDark ? Colors.white54 : Colors.grey[600],
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF2D3436),
          ),
        ),
      ],
    );
  }
}
