import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TransactionItem extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onTap;

  const TransactionItem({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final total = (transaction['total_amount'] as num).toDouble();
    final date = DateTime.parse(transaction['created_at']).toLocal();
    final cashierName = transaction['profiles']?['full_name'] ?? 'System';
    final txId = transaction['id'].toString().substring(0, 8).toUpperCase();

    final List items = transaction['transaction_items'] ?? [];
    String displayTitle = "#$txId";
    if (items.isNotEmpty) {
      final firstName = items[0]['products']?['name'] ?? 'Item';
      if (items.length > 1) {
        displayTitle = "$firstName + ${items.length - 1} item";
      } else {
        displayTitle = firstName;
      }
    }

    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            ),
          ),
        ),
        child: Row(
          children: [
            // Product Name & ID/Time
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF2D3436),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        "#$txId",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('HH:mm').format(date),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Cashier
            Expanded(
              flex: 2,
              child: Text(
                cashierName,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Amount
            Expanded(
              flex: 2,
              child: Text(
                currencyFormat.format(total),
                textAlign: TextAlign.right,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFFEA5700),
                ),
              ),
            ),

            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: Colors.grey.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
