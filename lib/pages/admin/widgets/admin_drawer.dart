import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/platform/file_manager.dart';

class AdminDrawer extends StatelessWidget {
  final String? userName;
  final String? profileUrl;
  final String? storeName;
  final String? storeLogo;
  final String? role;
  final Map<String, dynamic>? permissions;
  final Color primaryColor;
  final int selectedIndex;
  final VoidCallback onDashboardTap;
  final VoidCallback onProfileTap;
  final VoidCallback onInventoryTap;
  final VoidCallback onCategoryTap;
  final VoidCallback onKasirTap;
  final VoidCallback onEmployeeTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onAnalyticsTap;
  final VoidCallback onPrinterTap;
  final VoidCallback onPromotionTap;
  final VoidCallback onExportImportTap;
  final VoidCallback onProfitLossTap;
  final VoidCallback onCustomerTap;
  final VoidCallback onLogoutTap;

  const AdminDrawer({
    super.key,
    this.userName,
    this.profileUrl,
    this.storeName,
    this.storeLogo,
    this.role,
    this.permissions,
    required this.primaryColor,
    required this.selectedIndex,
    required this.onDashboardTap,
    required this.onProfileTap,
    required this.onInventoryTap,
    required this.onCategoryTap,
    required this.onKasirTap,
    required this.onEmployeeTap,
    required this.onHistoryTap,
    required this.onAnalyticsTap,
    required this.onPrinterTap,
    required this.onPromotionTap,
    required this.onExportImportTap,
    required this.onProfitLossTap,
    required this.onCustomerTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1C1E) : Colors.white;

    return Drawer(
      elevation: 0,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(0)),
      ),
      child: Column(
        children: [
          _buildModernHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                _buildSectionTitle("UTAMA"),
                _buildModernItem(
                  context,
                  icon: CupertinoIcons.square_grid_2x2,
                  label: "Dashboard",
                  onTap: () {
                    Navigator.pop(context);
                    onDashboardTap();
                  },
                  isActive: selectedIndex == 0,
                ),
                _buildSectionTitle("OPERASIONAL"),
                if (role?.toLowerCase() == 'owner' ||
                    role?.toLowerCase() == 'admin' ||
                    (permissions?['manage_inventory'] ?? true))
                  _buildModernItem(
                    context,
                    icon: CupertinoIcons.cube_box,
                    label: "Inventori Barang",
                    onTap: () {
                      Navigator.pop(context);
                      onInventoryTap();
                    },
                    isActive: selectedIndex == 1,
                  ),
                if (role?.toLowerCase() == 'owner' ||
                    role?.toLowerCase() == 'admin' ||
                    (permissions?['manage_categories'] ?? true))
                  _buildModernItem(
                    context,
                    icon: CupertinoIcons.grid,
                    label: "Manajemen Kategori",
                    onTap: () {
                      Navigator.pop(context);
                      onCategoryTap();
                    },
                    isActive: selectedIndex == 2,
                  ),
                if (role?.toLowerCase() == 'owner' ||
                    role?.toLowerCase() == 'admin' ||
                    (permissions?['pos_access'] ?? true))
                  _buildModernItem(
                    context,
                    icon: CupertinoIcons.cart,
                    label: "Kasir (POS)",
                    onTap: () {
                      Navigator.pop(context);
                      onKasirTap();
                    },
                    isActive: selectedIndex == 3,
                  ),
                if (role?.toLowerCase() == 'owner' ||
                    role?.toLowerCase() == 'admin')
                  _buildModernItem(
                    context,
                    icon: CupertinoIcons.person_2,
                    label: "Manajemen Karyawan",
                    onTap: () {
                      Navigator.pop(context);
                      onEmployeeTap();
                    },
                    isActive: selectedIndex == 5,
                  ),
                if (role?.toLowerCase() == 'owner' ||
                    role?.toLowerCase() == 'admin' ||
                    (permissions?['view_history'] ?? true))
                  _buildModernItem(
                    context,
                    icon: CupertinoIcons.doc_text,
                    label: "Riwayat Transaksi",
                    onTap: () {
                      Navigator.pop(context);
                      onHistoryTap();
                    },
                    isActive: selectedIndex == 4,
                  ),
                _buildModernItem(
                  context,
                  icon: CupertinoIcons.person_crop_circle_badge_checkmark,
                  label: "Loyalty & Pelanggan",
                  onTap: () {
                    Navigator.pop(context);
                    onCustomerTap();
                  },
                  isActive: selectedIndex == 12,
                ),
                if (role?.toLowerCase() == 'owner' ||
                    role?.toLowerCase() == 'admin' ||
                    (permissions?['manage_promotions'] ?? true))
                  _buildModernItem(
                    context,
                    icon: CupertinoIcons.percent,
                    label: "Promosi & Diskon",
                    onTap: () {
                      Navigator.pop(context);
                      onPromotionTap();
                    },
                    isActive: selectedIndex == 9,
                  ),
                if (role?.toLowerCase() == 'owner' ||
                    role?.toLowerCase() == 'admin' ||
                    (permissions?['manage_printer'] ?? true))
                  _buildModernItem(
                    context,
                    icon: CupertinoIcons.printer,
                    label: "Pengaturan Printer",
                    onTap: () {
                      Navigator.pop(context);
                      onPrinterTap();
                    },
                    isActive: selectedIndex == 7,
                  ),
                if (role?.toLowerCase() == 'owner' ||
                    role?.toLowerCase() == 'admin' ||
                    (permissions?['view_reports'] ?? false)) ...[
                  _buildSectionTitle("LAINNYA"),
                  _buildModernItem(
                    context,
                    icon: Icons.analytics_rounded,
                    label: "Laporan Analitik",
                    onTap: () {
                      Navigator.pop(context);
                      onAnalyticsTap();
                    },
                    isSpecial: true,
                    isActive: selectedIndex == 6,
                  ),
                  _buildModernItem(
                    context,
                    icon: CupertinoIcons.graph_circle,
                    label: "Laporan Laba Rugi",
                    onTap: () {
                      Navigator.pop(context);
                      onProfitLossTap();
                    },
                    isSpecial: true,
                    isActive: selectedIndex == 11,
                  ),
                  _buildModernItem(
                    context,
                    icon: CupertinoIcons.cloud_download,
                    label: "Manajemen Data & Stok",
                    onTap: () {
                      Navigator.pop(context);
                      onExportImportTap();
                    },
                    isSpecial: true,
                    isActive: selectedIndex == 10,
                  ),
                ],
              ],
            ),
          ),
          _buildFooter(context, isDark),
        ],
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onProfileTap();
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    backgroundImage: (profileUrl ?? storeLogo) != null
                        ? FileManager().getImageProvider(
                            profileUrl ?? storeLogo!,
                          )
                        : null,
                    child: (profileUrl ?? storeLogo) == null
                        ? Icon(Icons.person, size: 36, color: Colors.grey[400])
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName ?? 'Admin',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        role?.toUpperCase() ?? "STAFF",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              onProfileTap();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  if (storeLogo != null)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: FileManager().getImageProvider(storeLogo!),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(color: Colors.white38, width: 1),
                      ),
                    )
                  else
                    const Icon(
                      CupertinoIcons.building_2_fill,
                      color: Colors.white70,
                      size: 16,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      storeName ?? "Toko Saya",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey[400],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildModernItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool isSpecial = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeColor = isSpecial ? Colors.blue : primaryColor;
    final activeBg = activeColor.withValues(alpha: 0.1);
    final textColor = isActive
        ? activeColor
        : (isDark ? Colors.white70 : const Color(0xFF2D3436));
    final iconColor = isActive
        ? activeColor
        : (isDark ? Colors.white54 : Colors.grey[500]);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: iconColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 1,
            color: isDark ? Colors.white10 : Colors.grey[200],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              Navigator.pop(context);
              onLogoutTap();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.power, color: Colors.red, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    "Keluar Sesi",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Ver 1.0.0 • by PosKasirAsri",
            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
