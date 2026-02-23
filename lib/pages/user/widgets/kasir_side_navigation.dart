import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../controllers/admin_controller.dart';
import '../../../controllers/settings_controller.dart';

class KasirSideNavigation extends StatelessWidget {
  final String currentRoute;
  final Function(int)? onIndexSelected;

  const KasirSideNavigation({
    super.key,
    required this.currentRoute,
    this.onIndexSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFFEA5700);
    final adminCtrl = context.watch<AdminController>();

    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // App Logo
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              CupertinoIcons.circle_grid_hex,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Column(
              children: [
                if (_hasPerm(adminCtrl, 'pos_access'))
                  _buildNavItem(
                    context,
                    icon: CupertinoIcons.square_grid_2x2,
                    label: SettingsController.instance.getString('nav_cashier'),
                    isActive: currentRoute == '/kasir',
                    onTap: () {
                      if (onIndexSelected != null) {
                        onIndexSelected!(0);
                      } else if (currentRoute != '/kasir') {
                        Navigator.pushReplacementNamed(context, '/kasir');
                      }
                    },
                  ),
                if (_hasPerm(adminCtrl, 'view_history'))
                  _buildNavItem(
                    context,
                    icon: CupertinoIcons.doc_text,
                    label: SettingsController.instance.getString('nav_history'),
                    isActive: currentRoute == '/order-history',
                    onTap: () {
                      if (onIndexSelected != null) {
                        onIndexSelected!(1);
                      } else if (currentRoute != '/order-history') {
                        Navigator.pushReplacementNamed(
                          context,
                          '/order-history',
                        );
                      }
                    },
                  ),
                _buildNavItem(
                  context,
                  icon: CupertinoIcons.clock,
                  label: SettingsController.instance.getString('nav_absent'),
                  isActive: currentRoute == '/attendance',
                  onTap: () {
                    if (onIndexSelected != null) {
                      onIndexSelected!(2);
                    } else if (currentRoute != '/attendance') {
                      Navigator.pushReplacementNamed(context, '/attendance');
                    }
                  },
                ),
                if (_hasPerm(adminCtrl, 'manage_printer'))
                  _buildNavItem(
                    context,
                    icon: CupertinoIcons.printer,
                    label: SettingsController.instance.getString('nav_printer'),
                    isActive: currentRoute == '/printer-settings',
                    onTap: () {
                      if (onIndexSelected != null) {
                        onIndexSelected!(3);
                      } else if (currentRoute != '/printer-settings') {
                        Navigator.pushReplacementNamed(
                          context,
                          '/printer-settings',
                        );
                      }
                    },
                  ),
                const Spacer(),
                _buildNavItem(
                  context,
                  icon: CupertinoIcons.power,
                  label: SettingsController.instance.getString('logout'),
                  isActive: false,
                  color: Colors.redAccent,
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('last_route');
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    Color? color,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFFEA5700);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive
                      ? primaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isActive
                      ? primaryColor
                      : (color ?? (isDark ? Colors.white54 : Colors.grey[600])),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive
                      ? primaryColor
                      : (color ?? (isDark ? Colors.white54 : Colors.grey[600])),
                ),
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
