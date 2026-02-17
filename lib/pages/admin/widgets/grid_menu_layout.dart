import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GridMenuItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const GridMenuItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class GridMenuLayout extends StatelessWidget {
  final List<GridMenuItem> items;
  final int crossAxisCount;

  const GridMenuLayout({
    super.key,
    required this.items,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      child: GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildGridCard(item, isDark);
        },
      ),
    );
  }

  Widget _buildGridCard(GridMenuItem item, bool isDark) {
    return Material(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey[200]!,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                item.label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
