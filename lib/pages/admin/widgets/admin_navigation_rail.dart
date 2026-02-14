import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final String? storeLogo;
  final VoidCallback onLogout;

  const AdminNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.storeLogo,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1C1E) : Colors.white;

    return Container(
      width: 80, // Fixed width for icon-only rail
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
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Store Logo
          Container(
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
                      image: NetworkImage(storeLogo!),
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
                  _buildRailItem(
                    index: 1,
                    icon: CupertinoIcons.cube_box_fill,
                    label: "Barang",
                    isActive: selectedIndex == 1,
                  ),
                  _buildRailItem(
                    index: 2,
                    icon: CupertinoIcons
                        .grid, // Keeping outlined for category usually
                    label: "Kategori",
                    isActive: selectedIndex == 2,
                  ),
                  _buildRailItem(
                    index: 3,
                    icon: CupertinoIcons.cart_fill,
                    label: "Kasir",
                    isActive: selectedIndex == 3,
                  ),
                  _buildRailItem(
                    index: 4,
                    icon: CupertinoIcons.person_2_fill,
                    label: "Karyawan",
                    isActive: selectedIndex == 4,
                  ),
                  _buildRailItem(
                    index: 5,
                    icon: CupertinoIcons.doc_text_fill,
                    label: "Riwayat",
                    isActive: selectedIndex == 5,
                  ),
                  _buildRailItem(
                    index: 6,
                    icon: CupertinoIcons.graph_square_fill,
                    label: "Analitik",
                    isActive: selectedIndex == 6,
                  ),
                  _buildRailItem(
                    index: 7,
                    icon: CupertinoIcons.printer_fill,
                    label: "Printer",
                    isActive: selectedIndex == 7,
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
    );
  }

  Widget _buildRailItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    const primaryColor = Color(0xFFEA5700);

    return Tooltip(
      message: label,
      preferBelow: false,
      margin: const EdgeInsets.only(left: 10),
      verticalOffset: 0,
      decoration: BoxDecoration(
        color: const Color(0xFF2D3436),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: InkWell(
          onTap: () => onDestinationSelected(index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive ? primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
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
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
