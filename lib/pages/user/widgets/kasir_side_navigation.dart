import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KasirSideNavigation extends StatelessWidget {
  final String currentRoute;
  const KasirSideNavigation({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFFEA5700);

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
            child: Icon(CupertinoIcons.circle_grid_hex, color: primaryColor),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Column(
              children: [
                _buildNavItem(
                  context,
                  icon: CupertinoIcons.square_grid_2x2,
                  label: "Kasir",
                  isActive: currentRoute == '/kasir',
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/kasir'),
                ),
                _buildNavItem(
                  context,
                  icon: CupertinoIcons.doc_text,
                  label: "Riwayat",
                  isActive: currentRoute == '/order-history',
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/order-history'),
                ),
                _buildNavItem(
                  context,
                  icon: CupertinoIcons.clock,
                  label: "Absen",
                  isActive: currentRoute == '/attendance',
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/attendance'),
                ),
                _buildNavItem(
                  context,
                  icon: CupertinoIcons.printer,
                  label: "Printer",
                  isActive: currentRoute == '/printer-settings',
                  onTap: () => Navigator.pushReplacementNamed(
                    context,
                    '/printer-settings',
                  ),
                ),
                const Spacer(),
                _buildNavItem(
                  context,
                  icon: CupertinoIcons.power,
                  label: "Logout",
                  isActive: false,
                  color: Colors.redAccent,
                  onTap: () async {
                    final supabase = Supabase.instance.client;
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('last_route');
                    await supabase.auth.signOut();
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
      child: InkWell(
        onTap: onTap,
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
    );
  }
}
