import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/platform/file_manager.dart';

class AdminNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final String? storeLogo;
  final VoidCallback onLogout;
  final VoidCallback? onProfileTap;
  final VoidCallback? onCustomerTap;
  final String? userName;
  final String? storeName;
  final String? role;
  final Map<String, dynamic>? permissions;

  const AdminNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.storeLogo,
    required this.onLogout,
    this.onProfileTap,
    this.onCustomerTap,
    this.userName,
    this.storeName,
    this.role,
    this.permissions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1C1E) : Colors.white;

    return Container(
      width: 90,
      height: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            // Store Logo / Profile Tap
            GestureDetector(
              onTap: onProfileTap ?? () => onDestinationSelected(8),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEA5700).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFFEA5700).withValues(alpha: 0.1),
                    width: 2,
                  ),
                  image: storeLogo != null
                      ? DecorationImage(
                          image: FileManager().getImageProvider(storeLogo!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: storeLogo == null
                    ? const Icon(
                        CupertinoIcons.building_2_fill,
                        color: Color(0xFFEA5700),
                        size: 24,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 48),

            // Navigation Items
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildRailItem(
                      index: 0,
                      icon: CupertinoIcons.square_grid_2x2_fill,
                      label: "Dashboard",
                      isActive: selectedIndex == 0,
                    ),
                    if (_hasPerm('manage_inventory'))
                      _buildRailItem(
                        index: 1,
                        icon: CupertinoIcons.cube_box_fill,
                        label: "Barang",
                        isActive: selectedIndex == 1,
                      ),
                    if (_hasPerm('manage_categories'))
                      _buildRailItem(
                        index: 2,
                        icon: CupertinoIcons.grid,
                        label: "Kategori",
                        isActive: selectedIndex == 2,
                      ),
                    if (_hasPerm('pos_access'))
                      _buildRailItem(
                        index: 3,
                        icon: CupertinoIcons.cart_fill,
                        label: "Kasir",
                        isActive: selectedIndex == 3,
                      ),
                    if (_hasPerm('view_history'))
                      _buildRailItem(
                        index: 4,
                        icon: CupertinoIcons.doc_text_fill,
                        label: "Riwayat",
                        isActive: selectedIndex == 4,
                      ),
                    if (role?.toLowerCase() == 'owner' ||
                        role?.toLowerCase() == 'admin')
                      _buildRailItem(
                        index: 5,
                        icon: CupertinoIcons.person_2_fill,
                        label: "Karyawan",
                        isActive: selectedIndex == 5,
                      ),
                    if (role?.toLowerCase() == 'owner' ||
                        role?.toLowerCase() == 'admin' ||
                        _hasPerm('view_reports'))
                      _buildRailItem(
                        index: 6,
                        icon: CupertinoIcons.graph_square_fill,
                        label: "Analitik",
                        isActive: selectedIndex == 6,
                      ),
                    if (role?.toLowerCase() == 'owner' ||
                        role?.toLowerCase() == 'admin' ||
                        _hasPerm('view_reports'))
                      _buildRailItem(
                        index: 11,
                        icon: CupertinoIcons.graph_circle_fill,
                        label: "Laba Rugi",
                        isActive: selectedIndex == 11,
                      ),
                    _buildRailItem(
                      index: 12,
                      icon: CupertinoIcons.person_crop_circle_fill,
                      label: "Pelanggan",
                      isActive: selectedIndex == 12,
                    ),
                    if (role?.toLowerCase() == 'owner' ||
                        role?.toLowerCase() == 'admin' ||
                        _hasPerm('view_reports'))
                      _buildRailItem(
                        index: 10,
                        icon: CupertinoIcons.cloud_download_fill,
                        label: "Data & Stok",
                        isActive: selectedIndex == 10,
                      ),
                    if (_hasPerm('manage_printer'))
                      _buildRailItem(
                        index: 7,
                        icon: CupertinoIcons.printer_fill,
                        label: "Printer",
                        isActive: selectedIndex == 7,
                      ),
                    if (_hasPerm('manage_promotions'))
                      _buildRailItem(
                        index: 9,
                        icon: CupertinoIcons.percent,
                        label: "Promosi",
                        isActive: selectedIndex == 9,
                      ),
                  ],
                ),
              ),
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: IconButton(
                onPressed: onLogout,
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.power,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                tooltip: "Keluar",
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasPerm(String key) {
    if (role?.toLowerCase() == 'owner' || role?.toLowerCase() == 'admin') {
      return true;
    }
    return permissions?[key] ?? false;
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
          onTap: () => onDestinationSelected(index),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                              color: primaryColor.withValues(alpha: 0.4),
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
      ),
    );
  }
}
