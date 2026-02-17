import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../services/platform/file_manager.dart';

class CompactAdminHeader extends StatelessWidget {
  final String? storeName;
  final String? storeLogo;
  final double todaySales;
  final int transactionCount;
  final int lowStockCount;
  final NumberFormat currencyFormat;
  final Color primaryColor;
  final VoidCallback onProfileTap;
  final VoidCallback onLowStockTap;
  final VoidCallback onSalesTap;
  final VoidCallback onSettingsTap;

  const CompactAdminHeader({
    super.key,
    this.storeName,
    this.storeLogo,
    required this.todaySales,
    required this.transactionCount,
    required this.lowStockCount,
    required this.currencyFormat,
    required this.primaryColor,
    required this.onProfileTap,
    required this.onLowStockTap,
    required this.onSalesTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Store Logo & Name
          GestureDetector(
            onTap: onProfileTap,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  backgroundImage: storeLogo != null
                      ? FileManager().getImageProvider(storeLogo!)
                      : null,
                  child: storeLogo == null
                      ? Icon(
                          Icons.storefront_rounded,
                          color: primaryColor,
                          size: 24,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    storeName ?? 'Store',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Quick Stats Cards
          _buildStatCard(
            icon: CupertinoIcons.graph_circle,
            label: 'Penjualan',
            value: currencyFormat.format(todaySales),
            subtitle: '$transactionCount Transaksi',
            color: Colors.green,
            isDark: isDark,
            onTap: onSalesTap,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            icon: CupertinoIcons.cube_box,
            label: 'Low Stock',
            value: '$lowStockCount',
            subtitle: 'Item',
            color: Colors.orange,
            isDark: isDark,
            onTap: onLowStockTap,
          ),
          const SizedBox(width: 24),

          // Settings Icon
          GestureDetector(
            onTap: onSettingsTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                CupertinoIcons.settings,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
