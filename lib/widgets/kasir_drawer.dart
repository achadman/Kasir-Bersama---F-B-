import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/platform/file_manager.dart';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/theme_controller.dart';
import '../pages/other/printer_settings_page.dart';
import 'package:provider/provider.dart';
import '../controllers/admin_controller.dart';
import '../pages/admin/inventory_page.dart';
import '../pages/admin/category_page.dart';
import '../pages/admin/report/profit_loss_page.dart';
import '../pages/admin/customer_page.dart';
import '../pages/admin/promotion_page.dart';
import '../controllers/settings_controller.dart';

class KasirDrawer extends StatefulWidget {
  final String currentRoute;
  final Function(int)? onIndexSelected;

  const KasirDrawer({
    super.key,
    required this.currentRoute,
    this.onIndexSelected,
  });

  @override
  State<KasirDrawer> createState() => _KasirDrawerState();
}

class _KasirDrawerState extends State<KasirDrawer> {
  bool _isLoading = false;

  Future<void> _updateName() async {
    final adminCtrl = context.read<AdminController>();
    final controller = TextEditingController(text: adminCtrl.userName);

    await showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Ubah Nama"),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: CupertinoTextField(
            controller: controller,
            placeholder: "Nama Lengkap",
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Batal"),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            child: const Text("Simpan"),
            onPressed: () async {
              Navigator.pop(ctx);
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await adminCtrl.updateProfile(name: newName);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updatePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final adminCtrl = context.read<AdminController>();
        final fileName =
            'avatar_${adminCtrl.userId}_${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedFile.path)}';

        String savedPath = await FileManager().saveFile(pickedFile, fileName);

        await adminCtrl.updateProfile(avatarUrl: savedPath);
      } catch (e) {
        debugPrint("Upload Error: $e");
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Gagal simpan foto: $e")));
        }
      } finally {
        if (context.mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    final bgColor = isDark ? const Color(0xFF1A1C1E) : Colors.white;
    const accentColor = Color(0xFFFF4D4D); // Vibrant Red for Kasir

    final adminCtrl = context.watch<AdminController>();
    final role = adminCtrl.role;

    return Drawer(
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(0)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(isDark, adminCtrl),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                children: [
                  _buildSectionTitle(
                    SettingsController.instance.getString('navigation'),
                  ),
                  _buildModernItem(
                    icon: CupertinoIcons.person_crop_circle,
                    label: "Profil Saya",
                    isSelected: widget.currentRoute == '/profile',
                    accentColor: accentColor,
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.onIndexSelected != null) {
                        widget.onIndexSelected!(8);
                      } else if (widget.currentRoute != '/profile') {
                        Navigator.pushReplacementNamed(context, '/profile');
                      }
                    },
                  ),
                  if (_hasPerm(adminCtrl, 'pos_access'))
                    _buildModernItem(
                      icon: CupertinoIcons.home,
                      label: SettingsController.instance.getString('beranda'),
                      isSelected: widget.currentRoute == '/kasir',
                      accentColor: accentColor,
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.onIndexSelected != null) {
                          widget.onIndexSelected!(3);
                        } else if (widget.currentRoute != '/kasir') {
                          Navigator.pushReplacementNamed(context, '/kasir');
                        }
                      },
                    ),
                  if (_hasPerm(adminCtrl, 'manage_inventory'))
                    _buildModernItem(
                      icon: CupertinoIcons.cube_box,
                      label: SettingsController.instance.getString(
                        'nav_inventory',
                      ),
                      isSelected: widget.currentRoute == '/inventory',
                      accentColor: accentColor,
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.onIndexSelected != null) {
                          widget.onIndexSelected!(1);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => const InventoryPage(),
                            ),
                          );
                        }
                      },
                    ),
                  if (_hasPerm(adminCtrl, 'manage_categories'))
                    _buildModernItem(
                      icon: CupertinoIcons.tag,
                      label: SettingsController.instance.getString(
                        'nav_category',
                      ),
                      isSelected: widget.currentRoute == '/categories',
                      accentColor: accentColor,
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.onIndexSelected != null) {
                          widget.onIndexSelected!(2);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) =>
                                  CategoryPage(storeId: adminCtrl.storeId!),
                            ),
                          );
                        }
                      },
                    ),
                  _buildModernItem(
                    icon: CupertinoIcons.clock,
                    label: SettingsController.instance.getString('absen_staff'),
                    isSelected: widget.currentRoute == '/attendance',
                    accentColor: accentColor,
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.onIndexSelected != null) {
                        widget.onIndexSelected!(13);
                      } else if (widget.currentRoute != '/attendance') {
                        Navigator.pushReplacementNamed(context, '/attendance');
                      }
                    },
                  ),
                  if (_hasPerm(adminCtrl, 'view_history'))
                    _buildModernItem(
                      icon: CupertinoIcons.doc_text,
                      label: SettingsController.instance.getString(
                        'nav_history',
                      ),
                      isSelected: widget.currentRoute == '/order-history',
                      accentColor: accentColor,
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.onIndexSelected != null) {
                          widget.onIndexSelected!(4);
                        } else {
                          Navigator.pushReplacementNamed(
                            context,
                            '/order-history',
                          );
                        }
                      },
                    ),
                  if (_hasPerm(adminCtrl, 'view_reports'))
                    _buildModernItem(
                      icon: CupertinoIcons.chart_bar_square,
                      label: SettingsController.instance.getString(
                        'nav_profit_loss',
                      ),
                      isSelected: widget.currentRoute == '/profit-loss',
                      accentColor: accentColor,
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.onIndexSelected != null) {
                          widget.onIndexSelected!(11);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) =>
                                  ProfitLossPage(storeId: adminCtrl.storeId!),
                            ),
                          );
                        }
                      },
                    ),
                  if (_hasPerm(adminCtrl, 'manage_customers'))
                    _buildModernItem(
                      icon: CupertinoIcons.person_2,
                      label: "Loyalty Pelanggan",
                      isSelected: widget.currentRoute == '/customers',
                      accentColor: accentColor,
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.onIndexSelected != null) {
                          widget.onIndexSelected!(12);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => const CustomerPage(),
                            ),
                          );
                        }
                      },
                    ),
                  if (_hasPerm(adminCtrl, 'manage_promotions'))
                    _buildModernItem(
                      icon: CupertinoIcons.percent,
                      label: "Promosi & Diskon",
                      isSelected: widget.currentRoute == '/promotions',
                      accentColor: accentColor,
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.onIndexSelected != null) {
                          widget.onIndexSelected!(9);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => PromotionPage(),
                            ),
                          );
                        }
                      },
                    ),
                  if (_hasPerm(adminCtrl, 'manage_printer'))
                    _buildModernItem(
                      icon: CupertinoIcons.printer,
                      label: SettingsController.instance.getString(
                        'nav_printer',
                      ),
                      isSelected: widget.currentRoute == '/printer-settings',
                      accentColor: accentColor,
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.onIndexSelected != null) {
                          widget.onIndexSelected!(7);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => const PrinterSettingsPage(),
                            ),
                          );
                        }
                      },
                    ),
                  if (role == 'admin' || role == 'owner') ...[
                    _buildSectionTitle(
                      SettingsController.instance.getString('administration'),
                    ),
                    _buildModernItem(
                      icon: CupertinoIcons.shield_lefthalf_fill,
                      label: SettingsController.instance.getString(
                        'admin_panel',
                      ),
                      isSelected: false,
                      accentColor: Colors.blue,
                      isSpecial: true,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, '/admin');
                      },
                    ),
                  ],
                ],
              ),
            ),
            _buildThemeToggle(isDark, accentColor),
            _buildFooter(isDark),
          ],
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

  Widget _buildModernHeader(bool isDark, AdminController adminCtrl) {
    final avatarUrl = adminCtrl.profileUrl;
    final fullName = adminCtrl.userName ?? "Kasir";

    // A slightly different style for Kasir active user
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey[200]!,
          ),
        ),
      ),
      child: Column(
        children: [
        GestureDetector(
            onTap: () {
              Navigator.pop(context);
              if (widget.onIndexSelected != null) {
                widget.onIndexSelected!(4);
              }
            },
            child: Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF4D4D),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    image: avatarUrl != null
                        ? DecorationImage(
                            image: FileManager().getImageProvider(avatarUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: isDark ? Colors.grey[800] : Colors.white,
                  ),
                  child: avatarUrl == null
                      ? Icon(
                          CupertinoIcons.person_solid,
                          size: 40,
                          color: isDark ? Colors.white38 : Colors.grey[400],
                        )
                      : null,
                ),
                if (_isLoading)
                  const Positioned.fill(child: CircularProgressIndicator()),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4D4D),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.camera_fill,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                fullName,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _updateName,
                child: Icon(
                  CupertinoIcons.pencil,
                  size: 16,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4D4D).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "POS TERMINAL",
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF4D4D),
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
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

  Widget _buildModernItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color accentColor,
    bool isSpecial = false,
  }) {
    final isDark = ThemeController.instance.isDarkMode;
    final activeColor = isSpecial ? Colors.blue : accentColor;
    final activeBg = activeColor.withValues(alpha: 0.1);
    final textColor = isSelected
        ? activeColor
        : (isDark ? Colors.white70 : const Color(0xFF2D3436));
    final iconColor = isSelected
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
              color: isSelected ? activeBg : Colors.transparent,
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
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                if (isSelected)
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

  Widget _buildThemeToggle(bool isDark, Color accentColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
            color: isDark ? Colors.white70 : Colors.grey[700],
            size: 20,
          ),
          const SizedBox(width: 16),
          Text(
            isDark ? "Dark Mode" : "Light Mode",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.grey[800],
            ),
          ),
          const Spacer(),
          CupertinoSwitch(
            value: isDark,
            activeTrackColor: accentColor,
            onChanged: (val) {
              ThemeController.instance.toggleTheme();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: InkWell(
        onTap: () async {
          final shouldLogout = await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text("Konfirmasi Keluar"),
              content: const Text(
                "Apakah Anda yakin ingin keluar dari aplikasi?",
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text("Batal"),
                  onPressed: () => Navigator.pop(context, false),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: const Text("Keluar"),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          );

          if (shouldLogout == true) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('last_route');
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/login');
          }
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
                SettingsController.instance.getString('logout_app'),
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
    );
  }
}
