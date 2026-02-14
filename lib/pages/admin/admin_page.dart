import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:intl/intl.dart';
import '../user/kasir_page.dart';
import 'package:flutter/cupertino.dart';
import 'laporan_page.dart';
import 'category_page.dart';
import 'inventory_page.dart';
import 'profile_page.dart';
import 'employee_page.dart';
import 'history/history_page.dart';
import '../other/printer_settings_page.dart';

import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import 'analytics_page.dart';
import 'widgets/admin_header.dart';
import 'widgets/admin_menu_item.dart';
import 'widgets/admin_drawer.dart';
import 'widgets/low_stock_dialog.dart';
import 'report/shift_report_page.dart';
import 'report/profit_loss_page.dart';
import 'widgets/admin_navigation_rail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ... imports ...

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  // ... existing variables ...
  final supabase = Supabase.instance.client;
  final currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final Color _primaryColor = const Color(0xFFEA5700);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminController>().loadInitialData();
    });
  }

  void _showLowStockAlert(AdminController controller) {
    // ... existing implementation ...
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) => LowStockDialog(
        lowStockItems: controller.lowStockItems,
        onInventoryTap: () {
          Navigator.pop(context);
          if (mounted && controller.storeId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InventoryPage(storeId: controller.storeId!),
              ),
            );
          }
        },
      ),
    );
  }

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminController>(
      builder: (context, controller, child) {
        if (controller.isInitializing) {
          return const Scaffold(
            body: Center(child: CupertinoActivityIndicator(radius: 15)),
          );
        }

        if (controller.storeId == null) {
          return _buildNoStoreView(controller);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // Lower breakpoint to 700 for better tablet support
            final isWideScreen = constraints.maxWidth > 700;

            if (isWideScreen) {
              return Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                body: Row(
                  children: [
                    AdminNavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (index) =>
                          _onRailDestinationSelected(index, controller),
                      storeLogo: controller.storeLogo,
                      onLogout: _handleLogout,
                    ),
                    const VerticalDivider(thickness: 1, width: 1),
                    const SizedBox(width: 20), // Added spacing
                    Expanded(child: _getSelectedPage(controller)),
                  ],
                ),
              );
            }

            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              drawer: AdminDrawer(
                userName: controller.userName,
                profileUrl: controller.profileUrl,
                storeName: controller.storeName,
                storeLogo: controller.storeLogo,
                primaryColor: _primaryColor,
                onProfileTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilePage(storeId: controller.storeId!),
                    ),
                  );
                  controller.loadInitialData();
                },
                onInventoryTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InventoryPage(storeId: controller.storeId!),
                  ),
                ),
                onCategoryTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryPage(storeId: controller.storeId!),
                  ),
                ),
                onKasirTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KasirPage()),
                ),
                onEmployeeTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EmployeePage(storeId: controller.storeId!),
                  ),
                ),
                onHistoryTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistoryPage(storeId: controller.storeId!),
                  ),
                ),
                onAnalyticsTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnalyticsPage()),
                ),
                onPrinterTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrinterSettingsPage(),
                  ),
                ),
                role: controller.role,
                permissions: controller.permissions,
                onLogoutTap: _handleLogout,
              ),
              body: _getSelectedPage(controller),
            );
          },
        );
      },
    );
  }

  void _onRailDestinationSelected(int index, AdminController controller) {
    setState(() {
      _selectedIndex = index;
    });

    // Handle special cases (push external pages) if needed, currently we switch in-place
    // Note: If you want Kasir to still be full screen, you can check index == 3 and push.
    if (index == 3) {
      // Kasir POS usually needs full screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const KasirPage()),
      );
      // Reset index back to previous if you don't want 'Kasir' to remain selected after pop
      // Or keep it selected if you want to indicate where they were.
    }
  }

  Widget _getSelectedPage(AdminController controller) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent(controller);
      case 1:
        return InventoryPage(storeId: controller.storeId!);
      case 2:
        return CategoryPage(storeId: controller.storeId!);
      // case 3 is Kasir (handled as push usually, but if embedded:)
      case 3:
        // If we want embedded Kasir, return it here.
        // But POS usually wants to hide admin UI.
        // Let's keep it as push for now in logic, or placeholder here.
        return const Center(child: Text("Kasir opened in new window"));
      case 4:
        return EmployeePage(storeId: controller.storeId!);
      case 5:
        return HistoryPage(storeId: controller.storeId!);
      case 6:
        return const AnalyticsPage();
      case 7:
        return const PrinterSettingsPage();
      default:
        return _buildDashboardContent(controller);
    }
  }

  Widget _buildDashboardContent(AdminController controller) {
    return RefreshIndicator(
      onRefresh: controller.loadInitialData,
      color: _primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          children: [
            AdminHeader(
              userName: controller.storeName,
              profileUrl: controller.storeLogo,
              storeName: controller.storeName,
              todaySales: controller.todaySales,
              transactionCount: controller.transactionCount,
              lowStockCount: controller.lowStockCount,
              currencyFormat: currencyFormat,
              primaryColor: _primaryColor,
              onProfileTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(storeId: controller.storeId!),
                  ),
                );
                controller.loadInitialData();
              },
              onLowStockTap: () => _showLowStockAlert(controller),
              onSalesTap:
                  (controller.role == 'owner' || controller.role == 'admin')
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LaporanPage(storeId: controller.storeId!),
                      ),
                    )
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Akses Dibatasi: Hanya Owner yang dapat melihat laporan detail.",
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (controller.role == 'owner' ||
                      controller.role == 'admin' ||
                      (controller.permissions?['manage_inventory'] ?? true) ||
                      (controller.permissions?['manage_categories'] ?? true))
                    _buildAnimatedSection(
                      delay: 0,
                      child: AdminMenuSection(
                        title: "Manajemen Stok",
                        icon: CupertinoIcons.cube_box,
                        items: [
                          if (controller.role == 'owner' ||
                              controller.role == 'admin' ||
                              (controller.permissions?['manage_inventory'] ??
                                  true))
                            AdminMenuItem(
                              label: "Barang",
                              icon: CupertinoIcons.doc_text_viewfinder,
                              color: Colors.blue,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InventoryPage(
                                    storeId: controller.storeId!,
                                  ),
                                ),
                              ),
                            ),
                          if (controller.role == 'owner' ||
                              controller.role == 'admin' ||
                              (controller.permissions?['manage_categories'] ??
                                  true))
                            AdminMenuItem(
                              label: "Kategori",
                              icon: CupertinoIcons.grid,
                              color: Colors.indigo,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CategoryPage(
                                    storeId: controller.storeId!,
                                  ),
                                ),
                              ),
                            ),
                          AdminMenuItem(
                            label: "Laporan Analitik",
                            icon: CupertinoIcons.chart_bar_square,
                            color: Colors.pinkAccent,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AnalyticsPage(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  _buildAnimatedSection(
                    delay: 200,
                    child: AdminMenuSection(
                      title: "Operasional Kasir",
                      icon: CupertinoIcons.cart,
                      items: [
                        if (controller.role == 'owner' ||
                            controller.role == 'admin' ||
                            (controller.permissions?['pos_access'] ?? true))
                          AdminMenuItem(
                            label: "Transaksi",
                            icon: CupertinoIcons.cart_badge_plus,
                            color: Colors.orange,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const KasirPage(),
                                ),
                              );
                              controller.fetchDashboardStats();
                            },
                          ),
                        if (controller.role == 'owner' ||
                            controller.role == 'admin' ||
                            (controller.permissions?['view_history'] ?? true))
                          AdminMenuItem(
                            label: "Riwayat",
                            icon: CupertinoIcons.doc_text,
                            color: Colors.purple,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    HistoryPage(storeId: controller.storeId!),
                              ),
                            ),
                          ),
                        if (controller.role == 'owner' ||
                            controller.role == 'admin' ||
                            (controller.permissions?['manage_printer'] ?? true))
                          AdminMenuItem(
                            label: "Printer",
                            icon: CupertinoIcons.printer,
                            color: Colors.blueGrey,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PrinterSettingsPage(),
                              ),
                            ),
                          ),
                        if (controller.role == 'owner' ||
                            controller.role == 'admin')
                          AdminMenuItem(
                            label: "Karyawan",
                            icon: CupertinoIcons.person_2,
                            color: Colors.cyan,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EmployeePage(storeId: controller.storeId!),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (controller.role == 'owner' ||
                      controller.role == 'admin' ||
                      (controller.permissions?['view_reports'] ?? false))
                    _buildAnimatedSection(
                      delay: 400,
                      child: AdminMenuSection(
                        title: "Analitik & Laporan",
                        icon: CupertinoIcons.graph_square,
                        items: [
                          AdminMenuItem(
                            label: "Lap. Shift",
                            icon: CupertinoIcons.list_bullet_indent,
                            color: Colors.blueAccent,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ShiftReportPage(
                                  storeId: controller.storeId!,
                                ),
                              ),
                            ),
                          ),
                          AdminMenuItem(
                            label: "Penjualan",
                            icon: CupertinoIcons.graph_circle,
                            color: Colors.green,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    LaporanPage(storeId: controller.storeId!),
                              ),
                            ),
                          ),
                          AdminMenuItem(
                            label: "Laba Rugi",
                            icon: CupertinoIcons.money_dollar_circle,
                            color: Colors.teal,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfitLossPage(
                                  storeId: controller.storeId!,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Konfirmasi Keluar"),
        content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
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
      await supabase.auth.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Widget _buildNoStoreView(AdminController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.house_alt_fill,
                size: 100,
                color: Color(0xFFEA5700),
              ),
              const SizedBox(height: 24),
              Text(
                "Toko Belum Terdaftar",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Akun Anda terdeteksi belum memiliki toko. Silakan buat toko baru untuk mulai mengelola bisnis Anda.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _showCreateStoreDialog(controller),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA5700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Buat Toko Sekarang",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  final shouldLogout = await showCupertinoDialog<bool>(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text("Konfirmasi Keluar"),
                      content: const Text(
                        "Apakah Anda yakin ingin keluar dari akun?",
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
                    await supabase.auth.signOut();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  }
                },
                child: Text(
                  "Keluar Akun",
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateStoreDialog(AdminController controller) async {
    final nameController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Buka Toko Baru",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Nama Toko",
            hintText: "Contoh: Steak Asri Pusat",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text("Buat Toko"),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final storeRes = await supabase
            .from('stores')
            .insert({'name': result})
            .select()
            .single();

        await supabase
            .from('profiles')
            .update({'store_id': storeRes['id']})
            .eq('id', supabase.auth.currentUser!.id);

        controller.loadInitialData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Toko berhasil dibuat!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildAnimatedSection({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuint,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
