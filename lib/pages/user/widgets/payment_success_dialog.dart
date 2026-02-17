import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart'; // For sharing PDF
import 'package:intl/intl.dart';
import '../../../services/bluetooth_printer_service.dart';

class PaymentSuccessDialog extends StatelessWidget {
  final Uint8List pdfData;
  final String transactionId;
  final double totalAmount;
  final double cashReceived;
  final double change;
  final VoidCallback onNewTransaction;

  // Print Data
  final String storeName;
  final DateTime createdAt;
  final List<Map<String, dynamic>> items;
  final String paymentMethod;

  const PaymentSuccessDialog({
    super.key,
    required this.pdfData,
    required this.transactionId,
    required this.totalAmount,
    required this.cashReceived,
    required this.change,
    required this.onNewTransaction,
    required this.storeName,
    required this.createdAt,
    required this.items,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480), // Modern dialog width
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32), // Increased padding
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Pembayaran Berhasil!",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Transaksi #$transactionId telah tersimpan.",
                  style: GoogleFonts.inter(fontSize: 15, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    children: [
                      _row(
                        "Total Tagihan",
                        currencyFormat.format(totalAmount),
                        isBold: true,
                        fontSize: 16,
                      ),
                      const SizedBox(height: 12),
                      _row("Tunai", currencyFormat.format(cashReceived)),
                      const SizedBox(height: 12),
                      Divider(color: Colors.grey.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      _row(
                        "Kembalian",
                        currencyFormat.format(change),
                        isBold: true,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => _handlePrint(context),
                          icon: const Icon(Icons.print_rounded, size: 20),
                          label: const Text("Cetak"),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : Colors.grey[300]!,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleDownload(context),
                          icon: const Icon(Icons.download_rounded, size: 20),
                          label: const Text("Unduh"),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : Colors.grey[300]!,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Close dialog effectively first
                      Navigator.of(context, rootNavigator: true).pop();
                      // Then reset state
                      onNewTransaction();
                    },
                    icon: const Icon(
                      Icons.add_shopping_cart_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    label: Text(
                      "Transaksi Baru",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D4D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: const Color(
                        0xFFFF4D4D,
                      ).withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
    double fontSize = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: fontSize, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _handlePrint(BuildContext context) async {
    final printerService = BluetoothPrinterService();

    // Check connection first
    final isConnected = await printerService.isConnectedStatus;
    if (isConnected != true) {
      // Not connected
    }

    if (!printerService.isConnected) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Printer belum terhubung! Silakan hubungkan di menu Pengaturan.",
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      await printerService.printReceipt(
        storeName: storeName,
        transactionId: transactionId,
        createdAt: createdAt,
        items: items,
        totalAmount: totalAmount,
        cashReceived: cashReceived,
        change: change,
        paymentMethod: paymentMethod,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Mencetak struk...")));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal mencetak: $e")));
      }
    }
  }

  Future<void> _handleDownload(BuildContext context) async {
    try {
      await Printing.sharePdf(
        bytes: pdfData,
        filename: 'Struk-$transactionId.pdf',
      );
    } catch (e) {
      debugPrint("Error sharing PDF: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Gagal mengunduh PDF")));
      }
    }
  }
}
