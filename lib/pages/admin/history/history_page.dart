import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../controllers/admin_controller.dart';

import 'tabs/transactions_tab.dart';
import 'tabs/performance_tab.dart';
import '../../../services/export_service.dart';
import '../../../services/platform/file_manager.dart';
import 'package:intl/intl.dart';

import '../../../services/app_database.dart';
import 'package:drift/drift.dart' hide Column;

class HistoryPage extends StatefulWidget {
  final String? storeId;
  final VoidCallback? onMenuPressed;
  const HistoryPage({super.key, this.storeId, this.onMenuPressed});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String? _storeId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _storeId = widget.storeId;
    if (_storeId == null) {
      _loadStoreId();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadStoreId() async {
    final adminCtrl = Provider.of<AdminController>(context, listen: false);
    if (mounted) {
      setState(() {
        _storeId = adminCtrl.userProfile?['store_id'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final content = Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(
                  "Riwayat & Performa",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF2D3436),
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                actions: [
                  IconButton(
                    onPressed: () => _showExportMenu(context),
                    icon: const Icon(Icons.ios_share_rounded),
                    tooltip: "Ekspor Laporan",
                  ),
                  const SizedBox(width: 8),
                ],
                leading: Builder(
                  builder: (ctx) {
                    final isWide = MediaQuery.of(ctx).size.width >= 720;
                    if (isWide) return const SizedBox.shrink();

                    if (Navigator.canPop(context)) {
                      return IconButton(
                        icon: Icon(
                          CupertinoIcons.back,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF2D3436),
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
                bottom: TabBar(
                  indicatorColor: const Color(0xFFEA5700),
                  labelColor: const Color(0xFFEA5700),
                  unselectedLabelColor: Colors.grey,
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(
                      text: "TRANSAKSI",
                      icon: Icon(CupertinoIcons.list_bullet, size: 20),
                    ),
                    Tab(
                      text: "PERFORMA STAF",
                      icon: Icon(CupertinoIcons.graph_square, size: 20),
                    ),
                  ],
                ),
              ),
              body: Consumer<AdminController>(
                builder: (context, adminCtrl, child) {
                  if (_isLoading || adminCtrl.isInitializing) {
                    return const Center(child: CupertinoActivityIndicator());
                  }

                  if (_storeId == null) {
                    return const Center(child: Text("Toko tidak ditemukan"));
                  }

                  return TabBarView(
                    children: [
                      TransactionsTab(storeId: _storeId!),
                      PerformanceTab(storeId: _storeId!),
                    ],
                  );
                },
              ),
            );

            return content;
          },
        ),
      ),
    );
  }

  void _showExportMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "Ekspor Riwayat Transaksi",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text("Ekspor PDF"),
              onTap: () {
                Navigator.pop(context);
                _handleExport('pdf');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text("Ekspor Excel"),
              onTap: () {
                Navigator.pop(context);
                _handleExport('excel');
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExport(String type) async {
    if (_storeId == null) return;

    final db = context.read<AppDatabase>();
    final exportService = ExportService();

    // Show loading? Maybe just do it.
    try {
      final transactions =
          await (db.select(db.transactions)
                ..where((t) => t.storeId.equals(_storeId!))
                ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
              .get();

      if (transactions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tidak ada transaksi untuk diekspor")),
          );
        }
        return;
      }

      Uint8List bytes;
      String filename;
      String mimeType;

      if (type == 'pdf') {
        bytes = await exportService.generateTransactionsPdf(
          "ASRI Store",
          transactions,
        );
        filename =
            "Laporan_Transaksi_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf";
        mimeType = "application/pdf";
      } else {
        bytes = await exportService.generateTransactionsExcel(
          "ASRI Store",
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal ekspor: $e")));
      }
    }
  }
}
