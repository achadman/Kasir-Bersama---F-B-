import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../services/app_database.dart';
import 'widgets/promotion_form_sheet.dart';
import 'package:intl/intl.dart';
import '../../widgets/asri_dialog.dart';

class PromotionPage extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const PromotionPage({super.key, this.onMenuPressed});

  @override
  State<PromotionPage> createState() => _PromotionPageState();
}

class _PromotionPageState extends State<PromotionPage> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AdminController>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1A1C1E)
          : const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(
          'Kelola Promosi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        leading: Builder(
          builder: (ctx) {
            final isWide = MediaQuery.of(ctx).size.width >= 720;
            if (isWide) return const SizedBox.shrink();

            if (Navigator.canPop(context)) {
              return IconButton(
                icon: Icon(
                  CupertinoIcons.back,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                ),
                onPressed: () => Navigator.pop(context),
              );
            }

            return IconButton(
              icon: Icon(
                CupertinoIcons.bars,
                color: isDark ? Colors.white : const Color(0xFF2D3436),
              ),
              onPressed: () {
                if (widget.onMenuPressed != null) {
                  widget.onMenuPressed!();
                } else {
                  Scaffold.of(context).openDrawer();
                }
              },
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: () => _showInfoHelp(),
            icon: Icon(
              CupertinoIcons.info_circle,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
            tooltip: "Tentang Promosi",
          ),
          IconButton(
            onPressed: () => _showPromotionForm(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<Promotion>>(
        future: controller.promotionService.getAllPromotions(
          controller.storeId!,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final promos = snapshot.data ?? [];

          if (promos.isEmpty) {
            return _buildEmptyState(context, primaryColor);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: promos.length,
            itemBuilder: (context, index) {
              final promo = promos[index];
              return _buildPromoCard(context, promo, controller, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.percent, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Belum ada promosi',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Klik tombol + untuk membuat promosi baru',
            style: GoogleFonts.inter(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showPromotionForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Buat Promosi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(
    BuildContext context,
    Promotion promo,
    AdminController controller,
    bool isDark,
  ) {
    final typeLabel = _getTypeLabel(promo.type);
    final color = _getTypeColor(promo.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: promo.isActive ? color : Colors.grey),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              typeLabel,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          Switch.adaptive(
                            value: promo.isActive,
                            onChanged: (val) async {
                              await controller.promotionService
                                  .updatePromotionStatus(promo.id, val);
                              if (mounted) setState(() {});
                            },
                            activeTrackColor: color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        promo.name ?? 'Tanpa Nama',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (promo.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          promo.description!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (promo.value != null)
                            Text(
                              promo.discountType == 'percentage'
                                  ? '${promo.value!.toStringAsFixed(0)}% OFF'
                                  : _currencyFormat.format(promo.value!),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  CupertinoIcons.trash,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                onPressed: () =>
                                    _confirmDelete(context, promo, controller),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'discount':
        return 'DISKON';
      case 'buy_x_get_y':
        return 'B1G1 / B2G1';
      case 'bundle':
        return 'PAKET';
      default:
        return 'PROMO';
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'discount':
        return Colors.orange;
      case 'buy_x_get_y':
        return Colors.blue;
      case 'bundle':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  void _showPromotionForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PromotionFormSheet(),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Promotion promo,
    AdminController controller,
  ) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Hapus Promosi'),
        content: Text('Apakah Anda yakin ingin menghapus "${promo.name}"?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await controller.promotionService.deletePromotion(promo.id);
      if (mounted) setState(() {});
    }
  }

  void _showInfoHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AsriDialog(
        title: "Panduan Promosi",
        icon: CupertinoIcons.info_circle_fill,
        iconColor: Colors.orange,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(
              "Diskon",
              "Potongan harga langsung dalam bentuk Persen (%) atau Nominal Rupiah (Rp).",
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              "B1G1 / B2G1",
              "Beli X barang, Gratis Y barang. Sangat efektif untuk cuci gudang atau menaikkan volume penjualan.",
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              "Paket (Bundle)",
              "Harga khusus untuk pembelian set barang tertentu (Coming Soon).",
            ),
          ],
        ),
        primaryActionLabel: "Saya Mengerti",
        onPrimaryAction: () => Navigator.pop(ctx),
      ),
    );
  }

  Widget _buildInfoItem(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          desc,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
