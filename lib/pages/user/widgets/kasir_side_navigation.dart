import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../services/platform/file_manager.dart';
import '../../../controllers/admin_controller.dart';
import '../../../controllers/settings_controller.dart';
import '../../admin/inventory_page.dart';
import '../../admin/category_page.dart';
import '../../admin/report/profit_loss_page.dart';
import '../../admin/promotion_page.dart';
import '../../admin/customer_page.dart';

class KasirSideNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int)? onIndexSelected;
  final String? currentRoute; // Added for backward compatibility

  const KasirSideNavigation({
    super.key,
    this.selectedIndex = 3, // Default POS
    this.onIndexSelected,
    this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1C1E) : Colors.white;
    final adminCtrl = context.watch<AdminController>();

    int effectiveIndex = selectedIndex;
    if (currentRoute != null) {
      switch (currentRoute) {
        case '/inventory': effectiveIndex = 1; break;
        case '/categories': effectiveIndex = 2; break;
        case '/kasir': effectiveIndex = 3; break;
        case '/order-history': effectiveIndex = 4; break;
        case '/printer-settings': effectiveIndex = 7; break;
        case '/profile': effectiveIndex = 8; break;
        case '/promotions': effectiveIndex = 9; break;
        case '/profit-loss': effectiveIndex = 11; break;
        case '/customers': effectiveIndex = 12; break;
        case '/attendance': effectiveIndex = 13; break;
      }
    }

    return Container(
      width: 90,
      height: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Profile Icon (Static tap to profile index 8)
            GestureDetector(
              onTap: () => onIndexSelected?.call(8),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.grey[800] : Colors.white,
                  border: Border.all(
                    color: effectiveIndex == 8
                        ? const Color(0xFFEA5700)
                        : const Color(0xFFEA5700).withOpacity(0.1),
                    width: 2,
                  ),
                  image: adminCtrl.profileUrl != null
                      ? DecorationImage(
                          image: FileManager().getImageProvider(adminCtrl.profileUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: adminCtrl.profileUrl == null
                    ? Icon(
                        CupertinoIcons.person_fill,
                        color: effectiveIndex == 8
                            ? const Color(0xFFEA5700)
                            : Colors.grey[400],
                        size: 24,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 48),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (_hasPerm(adminCtrl, 'pos_access'))
                      _buildRailItem(
                        index: 3,
                        icon: CupertinoIcons.cart_fill,
                        label: "Kasir",
                        isActive: effectiveIndex == 3,
                      ),
                    if (_hasPerm(adminCtrl, 'manage_inventory'))
                      _buildRailItem(
                        index: 1,
                        icon: CupertinoIcons.cube_box_fill,
                        label: "Barang",
                        isActive: effectiveIndex == 1,
                      ),
                    if (_hasPerm(adminCtrl, 'manage_categories'))
                      _buildRailItem(
                        index: 2,
                        icon: CupertinoIcons.grid,
                        label: "Kategori",
                        isActive: effectiveIndex == 2,
                      ),
                    if (_hasPerm(adminCtrl, 'view_history'))
                      _buildRailItem(
                        index: 4,
                        icon: CupertinoIcons.doc_text_fill,
                        label: "Riwayat",
                        isActive: effectiveIndex == 4,
                      ),
                    _buildRailItem(
                      index: 13, // Unique index for Attendance
                      icon: CupertinoIcons.clock_fill,
                      label: "Absensi",
                      isActive: effectiveIndex == 13,
                    ),
                    if (_hasPerm(adminCtrl, 'view_reports'))
                      _buildRailItem(
                        index: 11,
                        icon: CupertinoIcons.graph_circle_fill,
                        label: "Laba Rugi",
                        isActive: effectiveIndex == 11,
                      ),
                    if (_hasPerm(adminCtrl, 'manage_customers'))
                      _buildRailItem(
                        index: 12,
                        icon: CupertinoIcons.person_crop_circle_fill,
                        label: "Customer",
                        isActive: effectiveIndex == 12,
                      ),
                    if (_hasPerm(adminCtrl, 'manage_promotions'))
                      _buildRailItem(
                        index: 9,
                        icon: CupertinoIcons.percent,
                        label: "Promosi",
                        isActive: effectiveIndex == 9,
                      ),
                    if (_hasPerm(adminCtrl, 'manage_printer'))
                      _buildRailItem(
                        index: 7,
                        icon: CupertinoIcons.printer_fill,
                        label: "Printer",
                        isActive: effectiveIndex == 7,
                      ),
                  ],
                ),
              ),
            ),
            // Power / Logout
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: IconButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('last_route');
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.power,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRailItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    const primaryColor = Color(0xFFEA5700);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onIndexSelected?.call(index),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  icon,
                  color: isActive ? Colors.white : Colors.grey[400],
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? primaryColor : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasPerm(AdminController ctrl, String key) {
    if (ctrl.role == 'admin' || ctrl.role == 'owner') return true;
    final perms = ctrl.permissions;
    if (perms == null) return false;
    return perms[key] == true;
  }
}
