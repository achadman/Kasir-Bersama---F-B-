import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/app_database.dart';
import '../../services/export_service.dart';
import '../../services/bulk_import_service.dart';
import '../../services/platform/file_manager.dart';
import '../../controllers/admin_controller.dart';
import '../../widgets/asri_dialog.dart';
import 'package:drift/drift.dart' hide Column;

class DataManagementPage extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const DataManagementPage({super.key, this.onMenuPressed});

  @override
  State<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<DataManagementPage> {
  final _exportService = ExportService();
  late BulkImportService _importService;
  bool _isLoading = false;

  // Consistent Color Palette
  final _colors = {
    'export': const Color(0xFF2196F3), // Blue
    'import': const Color(0xFF00BFA5), // Teal
    'restock': const Color(0xFF4CAF50), // Green
    'category': const Color(0xFF5C6BC0), // Indigo
    'danger': const Color(0xFFEF5350), // Red
    'transactions': const Color(0xFFFF9800), // Orange
  };

  @override
  void initState() {
    super.initState();
    final db = context.read<AppDatabase>();
    _importService = BulkImportService(db);
  }

  Future<void> _exportProducts() async {
    setState(() => _isLoading = true);
    try {
      final db = context.read<AppDatabase>();
      final adminCtrl = context.read<AdminController>();
      final products = await (db.select(
        db.products,
      )..where((t) => t.storeId.equals(adminCtrl.storeId!))).get();

      final bytes = await _exportService.generateProductsExcel(
        adminCtrl.storeName ?? "ASRI Store",
        products,
      );

      final filename =
          "Daftar_Produk_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx";

      await FileManager().saveAndShareBytes(
        filename,
        bytes,
        mimeType:
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      );
    } catch (e) {
      if (!mounted) return;
      _showError("Gagal ekspor produk: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBulkImport() async {
    final adminCtrl = context.read<AdminController>();
    final storeId = adminCtrl.storeId;
    if (storeId == null) return;

    setState(() => _isLoading = true);
    try {
      final result = await _importService.importProducts(storeId);

      if (result['status'] == 'cancelled') return;

      if (result['status'] == 'error') {
        if (!mounted) return;
        _showError("Gagal impor: ${result['message']}");
        return;
      }

      if (result['status'] == 'success') {
        if (mounted) {
          _showImportResultDialog(
            success: result['successCount'],
            fail: result['failCount'],
            errors: result['errors'],
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showError("Error saat impor: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showImportResultDialog({
    required int success,
    required int fail,
    required List<String> errors,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AsriDialog(
        title: "Hasil Impor",
        icon: success > 0 ? Icons.check_circle_rounded : Icons.info_rounded,
        iconColor: success > 0 ? _colors['import'] : Colors.orange,
        content: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildImportStat("Berhasil", success.toString(), Colors.green),
                _buildImportStat("Gagal", fail.toString(), Colors.red),
              ],
            ),
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Detail Kesalahan:",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        itemCount: errors.length,
                        itemBuilder: (c, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            "• ${errors[i]}",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        primaryActionLabel: "Tutup",
        onPrimaryAction: () => Navigator.pop(ctx),
      ),
    );
  }

  Widget _buildImportStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _exportTransactions(String type) async {
    setState(() => _isLoading = true);
    try {
      final db = context.read<AppDatabase>();
      final adminCtrl = context.read<AdminController>();
      final transactions =
          await (db.select(db.transactions)
                ..where((t) => t.storeId.equals(adminCtrl.storeId!))
                ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
              .get();

      if (transactions.isEmpty) {
        _showError("Tidak ada transaksi untuk diekspor");
        return;
      }

      Uint8List bytes;
      String filename;
      String mimeType;

      if (type == 'pdf') {
        bytes = await _exportService.generateTransactionsPdf(
          adminCtrl.storeName ?? "ASRI Store",
          transactions,
        );
        filename =
            "Laporan_Transaksi_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf";
        mimeType = "application/pdf";
      } else {
        bytes = await _exportService.generateTransactionsExcel(
          adminCtrl.storeName ?? "ASRI Store",
          transactions,
        );
        filename =
            "Laporan_Transaksi_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx";
        mimeType =
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
      }

      await FileManager().saveAndShareBytes(
        filename,
        bytes,
        mimeType: mimeType,
      );
    } catch (e) {
      if (!mounted) return;
      _showError("Gagal ekspor transaksi: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Stock Management Methods
  Future<void> _handleRestockAll() async {
    final db = context.read<AppDatabase>();
    final adminCtrl = context.read<AdminController>();

    final amount = await _showRestockAmountDialog("Restock Semua Barang");
    if (amount == null || amount <= 0) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Update all products with stock management enabled
      await (db.update(db.products)..where(
            (t) =>
                t.storeId.equals(adminCtrl.storeId!) &
                t.isStockManaged.equals(true) &
                t.isDeleted.equals(false),
          ))
          .write(
            ProductsCompanion.custom(
              stockQuantity: db.products.stockQuantity + Variable(amount),
            ),
          );

      if (!mounted) return;
      _showSuccess("Berhasil menambah $amount stok ke semua barang");
    } catch (e) {
      if (!mounted) return;
      _showError("Gagal restock: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestockByCategory() async {
    final db = context.read<AppDatabase>();
    final adminCtrl = context.read<AdminController>();

    final categories = await (db.select(
      db.categories,
    )..where((t) => t.storeId.equals(adminCtrl.storeId!))).get();
    if (categories.isEmpty) {
      if (!mounted) return;
      _showError("Belum ada kategori");
      return;
    }

    final selectedCategory = await _showCategorySelectionDialog(categories);
    if (selectedCategory == null) return;

    final amount = await _showRestockAmountDialog(
      "Restock Kategori: ${selectedCategory.name}",
    );
    if (amount == null || amount <= 0) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await (db.update(db.products)..where(
            (t) =>
                t.storeId.equals(adminCtrl.storeId!) &
                t.categoryId.equals(selectedCategory.id) &
                t.isStockManaged.equals(true) &
                t.isDeleted.equals(false),
          ))
          .write(
            ProductsCompanion.custom(
              stockQuantity: db.products.stockQuantity + Variable(amount),
            ),
          );

      if (!mounted) return;
      _showSuccess(
        "Berhasil menambah $amount stok ke kategori ${selectedCategory.name}",
      );
    } catch (e) {
      if (!mounted) return;
      _showError("Gagal restock kategori: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmptyStock(bool all) async {
    final db = context.read<AppDatabase>();
    final adminCtrl = context.read<AdminController>();
    Category? selectedCategory;

    if (!all) {
      final categories = await (db.select(
        db.categories,
      )..where((t) => t.storeId.equals(adminCtrl.storeId!))).get();
      selectedCategory = await _showCategorySelectionDialog(categories);
      if (selectedCategory == null) return;
    }

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AsriDialog(
        title: all ? "Kosongkan Semua Stok?" : "Kosongkan Stok Kategori?",
        message: all
            ? "Semua stok barang 'Terbatas' akan diubah menjadi 0. Tindakan ini tidak dapat dibatalkan."
            : "Stok barang '${selectedCategory!.name}' akan diubah menjadi 0. Tindakan ini tidak dapat dibatalkan.",
        icon: Icons.warning_amber_rounded,
        iconColor: _colors['danger'],
        isDestructive: true,
        primaryActionLabel: "Kosongkan",
        secondaryActionLabel: "Batal",
        onPrimaryAction: () => Navigator.pop(ctx, true),
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final query = db.update(db.products)
        ..where(
          (t) =>
              t.storeId.equals(adminCtrl.storeId!) &
              t.isStockManaged.equals(true) &
              t.isDeleted.equals(false),
        );

      if (!all && selectedCategory != null) {
        query.where((t) => t.categoryId.equals(selectedCategory!.id));
      }

      await query.write(const ProductsCompanion(stockQuantity: Value(0)));

      if (!mounted) return;
      _showSuccess("Berhasil mengosongkan stok");
    } catch (e) {
      if (!mounted) return;
      _showError("Gagal mengosongkan stok: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Dialog Helpers
  Future<int?> _showRestockAmountDialog(String title) async {
    final controller = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (ctx) => AsriDialog(
        title: title,
        icon: Icons.add_business_rounded,
        iconColor: _colors['restock'],
        content: Column(
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: "Jumlah Tambahan",
                labelStyle: GoogleFonts.inter(fontSize: 14),
                hintText: "Contoh: 10",
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white10
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
        primaryActionLabel: "Simpan",
        secondaryActionLabel: "Batal",
        onPrimaryAction: () =>
            Navigator.pop(ctx, int.tryParse(controller.text)),
      ),
    );
  }

  Future<Category?> _showCategorySelectionDialog(
    List<Category> categories,
  ) async {
    return showDialog<Category>(
      context: context,
      builder: (ctx) => AsriDialog(
        title: "Pilih Kategori",
        icon: CupertinoIcons.square_grid_2x2_fill,
        iconColor: _colors['category'],
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => Navigator.pop(ctx, cat),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white10
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _colors['category']!.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.tag_fill,
                            size: 14,
                            color: _colors['category'],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          cat.name!,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          CupertinoIcons.chevron_right,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        secondaryActionLabel: "Batal",
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _colors['danger'],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Manajemen Data & Stok",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.bars),
          onPressed:
              widget.onMenuPressed ?? () => Scaffold.of(context).openDrawer(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSectionHeader("EKSPOR & IMPOR DATA"),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildActionCard(
                          title: "Ekspor Produk",
                          subtitle: "Simpan semua produk ke Excel (.xlsx)",
                          description:
                              "Download seluruh daftar produk Anda ke dalam file Excel. Berguna untuk cadangan data atau pengeditan massal di luar aplikasi.",
                          icon: CupertinoIcons.cube_box,
                          color: _colors['export']!,
                          onTap: _exportProducts,
                        ),
                        _buildActionCard(
                          title: "Impor Produk",
                          subtitle: "Unggah Excel untuk input barang massal",
                          description:
                              "Gunakan template Excel (dari fitur Ekspor) untuk menambah atau memperbarui ribuan produk sekaligus. Sangat cepat untuk stok baru atau perpindahan data.",
                          icon: CupertinoIcons.cloud_upload,
                          color: _colors['import']!,
                          onTap: _handleBulkImport,
                        ),
                        _buildActionCard(
                          title: "Laporan Transaksi",
                          subtitle: "Ekspor riwayat ke PDF atau Excel",
                          description:
                              "Melihat seluruh sejarah penjualan dalam periode tertentu. Bisa disimpan dalam format PDF (cetak) atau Excel (analisis data).",
                          icon: CupertinoIcons.doc_text,
                          color: _colors['transactions']!,
                          onTap: () => _showExportFormatDialog('transaksi'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader("MANAJEMEN STOK"),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildActionCard(
                          title: "Restock Semua",
                          subtitle: "Tambah jumlah stok ke seluruh barang",
                          description:
                              "Menambah jumlah stok yang sama ke SELURUH produk yang stoknya dikelola (Terbatas). Contoh: Menambah 10 ke semua barang.",
                          icon: Icons.playlist_add_check_rounded,
                          color: _colors['restock']!,
                          onTap: _handleRestockAll,
                        ),
                        _buildActionCard(
                          title: "Restock per Kategori",
                          subtitle: "Pilih kategori untuk ditambah stoknya",
                          description:
                              "Menambah stok hanya untuk kategori tertentu. Misal: Menambah 20 stok khusus untuk kategori 'Minuman'.",
                          icon: CupertinoIcons.square_grid_2x2,
                          color: _colors['category']!,
                          onTap: _handleRestockByCategory,
                        ),
                        _buildActionCard(
                          title: "Kosongkan Semua Stok",
                          subtitle: "Setel semua stok barang menjadi 0",
                          description:
                              "Mengubah seluruh jumlah stok produk (Terbatas) menjadi 0. Biasanya digunakan saat ingin melakukan stok opname dari awal.",
                          icon: Icons.delete_sweep_rounded,
                          color: _colors['danger']!,
                          onTap: () => _handleEmptyStock(true),
                        ),
                        _buildActionCard(
                          title: "Kosongkan Stok Kategori",
                          subtitle: "Setel stok kategori tertentu menjadi 0",
                          description:
                              "Mengubah stok produk dalam kategori pilihan menjadi 0 tanpa mempengaruhi kategori lain.",
                          icon: Icons.delete_outline_rounded,
                          color: _colors['danger']!.withValues(alpha: 0.8),
                          onTap: () => _handleEmptyStock(false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    // Calculate card width based on screen size
    final cardWidth = width > 1200
        ? (width - 100) / 3
        : (width > 720 ? (width - 80) / 2 : double.infinity);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () =>
                            _showFeatureInfo(title, description, icon, color),
                        borderRadius: BorderRadius.circular(20),
                        child: Icon(
                          CupertinoIcons.info_circle,
                          size: 16,
                          color: color.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[500],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeatureInfo(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AsriDialog(
        title: title,
        icon: icon,
        iconColor: color,
        content: Text(
          description,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            height: 1.5,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.grey[700],
          ),
        ),
        primaryActionLabel: "Paham",
        onPrimaryAction: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showExportFormatDialog(String category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "Pilih Format Ekspor",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _buildExportOption(
                      icon: Icons.picture_as_pdf,
                      label: "PDF Document",
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        _exportTransactions('pdf');
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildExportOption(
                      icon: Icons.table_chart,
                      label: "Excel Spreadsheet",
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        _exportTransactions('excel');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
