import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/app_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../widgets/floating_card.dart';
import 'package:drift/drift.dart' hide Column;

class FinanceReport extends StatefulWidget {
  final String storeId;

  const FinanceReport({super.key, required this.storeId});

  @override
  State<FinanceReport> createState() => _FinanceReportState();
}

class _FinanceReportState extends State<FinanceReport> {
  List<Transaction> _txs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      final db = context.read<AppDatabase>();
      final results =
          await (db.select(db.transactions)
                ..where((t) => t.storeId.equals(widget.storeId))
                ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
              .get();
      setState(() {
        _txs = results;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching transactions: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final textHeading = isDark ? Colors.white : const Color(0xFF2D3436);

    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_txs.isEmpty) {
      return Center(
        child: Text(
          "Belum ada transaksi.",
          style: GoogleFonts.inter(color: Colors.grey[500]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: _txs.length,
        itemBuilder: (context, index) {
          final tx = _txs[index];
          return FloatingCard(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.receipt_long_rounded, color: primaryColor),
              ),
              title: Text(
                currencyFormat.format(tx.totalAmount),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: textHeading,
                ),
              ),
              subtitle: Text(
                "${tx.paymentMethod ?? 'Unknown'} • ${tx.createdAt != null ? DateFormat('dd MMM, HH:mm').format(tx.createdAt!.toLocal()) : ''}",
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[300],
              ),
            ),
          );
        },
      ),
    );
  }
}
