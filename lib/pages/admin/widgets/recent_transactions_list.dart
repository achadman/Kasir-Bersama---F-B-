import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'pinterest_card.dart';

class RecentTransactionsList extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final NumberFormat currencyFormat;
  final VoidCallback? onViewAll;

  const RecentTransactionsList({
    super.key,
    required this.transactions,
    required this.currencyFormat,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return PinterestCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transaksi Terbaru',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: Text(
                    'Lihat Semua',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFEA5700),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (transactions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Belum ada transaksi',
                  style: GoogleFonts.inter(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length > 10 ? 10 : transactions.length,
              separatorBuilder: (context, index) => Divider(
                height: 32,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return _buildTransactionItem(
                  context,
                  transaction,
                  index + 1,
                  isDark,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    Map<String, dynamic> transaction,
    int index,
    bool isDark,
  ) {
    final date = transaction['date'] as DateTime?;
    final invoiceNumber = transaction['invoice_number'] as String? ?? '-';
    final total = transaction['total'] as double? ?? 0.0;
    final status = transaction['status'] as String? ?? 'completed';
    final textColor = isDark ? Colors.white : Colors.black87;

    return Row(
      children: [
        Container(
          width: 54,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEA5700).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFFEA5700),
                size: 20,
              ),
              Positioned(
                top: 4,
                left: 4,
                child: Text(
                  '$index',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFEA5700),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invoiceNumber,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 12,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      transaction['cashier'] as String? ?? 'System',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    date != null ? DateFormat('HH:mm').format(date) : '-',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(total),
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: status == 'completed'
                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status == 'completed' ? 'Selesai' : 'Pending',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: status == 'completed'
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
