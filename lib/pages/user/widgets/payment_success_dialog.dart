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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Pembayaran Berhasil!",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Transaksi #$transactionId telah tersimpan.",
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _row(
                    "Total Tagihan",
                    currencyFormat.format(totalAmount),
                    isBold: true,
                  ),
                  const SizedBox(height: 8),
                  _row("Tunai", currencyFormat.format(cashReceived)),
                  const SizedBox(height: 8),
                  Divider(color: Colors.grey.withValues(alpha: 0.2)),
                  const SizedBox(height: 8),
                  _row(
                    "Kembalian",
                    currencyFormat.format(change),
                    isBold: true,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handlePrint(context),
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text("Cetak"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleDownload(context),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text("Unduh"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  onNewTransaction();
                  Navigator.of(context).pop();
                },
                icon: const Icon(
                  Icons.add_shopping_cart_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  "Transaksi Baru",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4D4D),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
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
