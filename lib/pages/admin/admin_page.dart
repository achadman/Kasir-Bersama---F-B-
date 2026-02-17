import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../user/kasir_page.dart';
import 'package:flutter/cupertino.dart';
import 'category_page.dart';
import 'inventory_page.dart';
import 'profile_page.dart';
import 'employee_page.dart';
import 'history/history_page.dart';
import '../other/printer_settings_page.dart';
import 'promotion_page.dart';
import 'data_management_page.dart';
import 'report/profit_loss_page.dart';

import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import 'analytics_page.dart';
import 'widgets/admin_drawer.dart';
import 'widgets/admin_navigation_rail.dart';
import 'widgets/stat_card.dart';
import 'widgets/recent_transactions_list.dart';
import 'widgets/pinterest_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Color _primaryColor = const Color(0xFFEA5700);
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<AdminController>(context, listen: false);
      controller.loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AdminController>(context);
    final isWideScreen = MediaQuery.of(context).size.width >= 720;

    if (controller.isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (isWideScreen) {
      return Scaffold(
        primary: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Builder(
          builder: (context) => Row(
            children: [
              AdminNavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
                storeLogo: controller.storeLogo,
                onLogout: _handleLogout,
                onProfileTap: () => setState(() => _selectedIndex = 8),
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: _getSelectedPage(controller)),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        key: _scaffoldKey,
        primary: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: null,
        drawer: AdminDrawer(
          userName: controller.userName ?? 'User',
          profileUrl: controller.profileUrl,
          storeName: controller.storeName,
          role: controller.role ?? 'cashier',
          permissions: controller.permissions ?? {},
          primaryColor: _primaryColor,
          selectedIndex: _selectedIndex,
          onDashboardTap: () => setState(() => _selectedIndex = 0),
          onProfileTap: () => setState(() => _selectedIndex = 8),
          onInventoryTap: () => setState(() => _selectedIndex = 1),
          onCategoryTap: () => setState(() => _selectedIndex = 2),
          onKasirTap: () => setState(() => _selectedIndex = 3),
          onEmployeeTap: () => setState(() => _selectedIndex = 5),
          onHistoryTap: () => setState(() => _selectedIndex = 4),
          onAnalyticsTap: () => setState(() => _selectedIndex = 6),
          onPrinterTap: () => setState(() => _selectedIndex = 7),
          onPromotionTap: () => setState(() => _selectedIndex = 9),
          onExportImportTap: () => setState(() => _selectedIndex = 10),
          onProfitLossTap: () => setState(() => _selectedIndex = 11),
          onLogoutTap: _handleLogout,
        ),
        body: Builder(builder: (context) => _getSelectedPage(controller)),
      );
    }
  }

  Widget _getSelectedPage(AdminController controller) {
    final sId = controller.storeId;
    if (sId == null && _selectedIndex != 0 && _selectedIndex != 7) {
      return const Center(child: CircularProgressIndicator());
    }

    void onMenuPressed() => _scaffoldKey.currentState?.openDrawer();

    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent(controller);
      case 1:
        return InventoryPage(onMenuPressed: onMenuPressed);
      case 2:
        return CategoryPage(storeId: sId!, onMenuPressed: onMenuPressed);
      case 3:
        return KasirPage(showSidebar: false, onMenuPressed: onMenuPressed);
      case 4:
        return HistoryPage(storeId: sId!, onMenuPressed: onMenuPressed);
      case 5:
        return EmployeePage(storeId: sId!, onMenuPressed: onMenuPressed);
      case 6:
        return AnalyticsPage(
          onMenuPressed: onMenuPressed,
          onNavigateToIndex: (index) => setState(() => _selectedIndex = index),
        );
      case 7:
        return const PrinterSettingsPage();
      case 8:
        return ProfilePage(storeId: sId!, onMenuPressed: onMenuPressed);
      case 9:
        return PromotionPage(onMenuPressed: onMenuPressed);
      case 10:
        return DataManagementPage(onMenuPressed: onMenuPressed);
      case 11:
        return ProfitLossPage(storeId: sId!, onMenuPressed: onMenuPressed);
      default:
        return _buildDashboardContent(controller);
    }
  }

  Widget _buildDashboardContent(AdminController controller) {
    final isWide = MediaQuery.of(context).size.width >= 720;

    Widget content = Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1C1C1E)
          : const Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEA5700), Color(0xFFFF6B35)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEA5700).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (!isWide)
                      Builder(
                        builder: (context) => IconButton(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          icon: const Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                    if (!isWide) const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Selamat datang, ${controller.storeName ?? "Admin"}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isWide
                      ? TextButton.icon(
                          onPressed: () => setState(() => _selectedIndex = 6),
                          icon: const Icon(
                            Icons.analytics_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Lihat Analitik',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: () => setState(() => _selectedIndex = 6),
                          icon: const Icon(
                            Icons.analytics_outlined,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("RINGKASAN HARI INI"),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWideThreshold = constraints.maxWidth > 550;
                    final cards = [
                      StatCard(
                        title: 'Pendapatan',
                        value: currencyFormat.format(controller.todaySales),
                        icon: Icons.attach_money_rounded,
                        color: const Color(0xFFEA5700),
                        onTap: () => setState(() => _selectedIndex = 6),
                      ),
                      StatCard(
                        title: 'Transaksi',
                        value: '${controller.transactionCount}',
                        icon: Icons.receipt_long_rounded,
                        color: const Color(0xFF2196F3),
                        onTap: () => setState(() => _selectedIndex = 4),
                      ),
                      FutureBuilder<int>(
                        future: _getTotalProducts(controller),
                        builder: (context, snapshot) {
                          return StatCard(
                            title: 'Produk',
                            value: '${snapshot.data ?? 0}',
                            icon: Icons.inventory_2_rounded,
                            color: const Color(0xFF4CAF50),
                            onTap: () => setState(() => _selectedIndex = 1),
                          );
                        },
                      ),
                      FutureBuilder<int>(
                        future: _getTotalEmployees(controller),
                        builder: (context, snapshot) {
                          return StatCard(
                            title: 'Karyawan',
                            value: '${snapshot.data ?? 0}',
                            icon: Icons.people_rounded,
                            color: const Color(0xFF9C27B0),
                            onTap: () => setState(() => _selectedIndex = 5),
                          );
                        },
                      ),
                    ];

                    if (isWideThreshold) {
                      return GridView.count(
                        crossAxisCount: 4,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.3,
                        children: cards,
                      );
                    } else {
                      return GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.1,
                        children: cards,
                      );
                    }
                  },
                ),
                const SizedBox(height: 32),
                _buildSectionTitle("PERFORMA PENDAPATAN (LIFETIME)"),
                const SizedBox(height: 16),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getLifetimeRevenue(controller),
                  builder: (context, snapshot) {
                    return _buildLifetimeRevenueChart(
                      snapshot.data ?? [],
                      currencyFormat,
                    );
                  },
                ),
                const SizedBox(height: 32),
                _buildSectionTitle("INDIKATOR PERTUMBUHAN"),
                const SizedBox(height: 16),
                FutureBuilder<Map<String, double>>(
                  future: _getGrowthMetrics(controller),
                  builder: (context, snapshot) {
                    final metrics =
                        snapshot.data ?? {'weekly': 0.0, 'monthly': 0.0};
                    return _buildGrowthIndicators(
                      metrics['weekly'] ?? 0.0,
                      metrics['monthly'] ?? 0.0,
                      Theme.of(context).brightness == Brightness.dark,
                    );
                  },
                ),
                const SizedBox(height: 32),
                _buildSectionTitle("TRANSAKSI TERAKHIR"),
                const SizedBox(height: 16),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getRecentTransactions(controller),
                  builder: (context, snapshot) {
                    return RecentTransactionsList(
                      transactions: snapshot.data ?? [],
                      currencyFormat: currencyFormat,
                      onViewAll: () => setState(() => _selectedIndex = 4),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return RefreshIndicator(
      onRefresh: controller.loadInitialData,
      color: _primaryColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isWide ? 20 : 0),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        child: content,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey[500],
        letterSpacing: 1.2,
      ),
    );
  }

  Future<int> _getTotalProducts(AdminController controller) async {
    try {
      final db = controller.database;
      if (db == null) return 0;
      final result = await db
          .customSelect(
            'SELECT COUNT(*) as count FROM products WHERE store_id = ? AND is_deleted = 0',
            variables: [Variable.withString(controller.storeId!)],
          )
          .getSingle();
      return result.data['count'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getTotalEmployees(AdminController controller) async {
    try {
      final db = controller.database;
      if (db == null) return 0;
      final result = await db
          .customSelect(
            'SELECT COUNT(*) as count FROM profiles WHERE store_id = ? AND role = ?',
            variables: [
              Variable.withString(controller.storeId!),
              Variable.withString('cashier'),
            ],
          )
          .getSingle();
      return result.data['count'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> _getRecentTransactions(
    AdminController controller,
  ) async {
    try {
      final db = controller.database;
      if (db == null) return [];
      final results = await db
          .customSelect(
            '''
        SELECT 
          t.id, t.total_amount, t.created_at, t.cashier_id, p.full_name as cashier_name
        FROM transactions t
        LEFT JOIN profiles p ON t.cashier_id = p.id
        WHERE t.store_id = ?
        ORDER BY t.created_at DESC LIMIT 10
        ''',
            variables: [Variable.withString(controller.storeId!)],
            readsFrom: {db.transactions, db.profiles},
          )
          .get();

      return results.map((row) {
        DateTime? date;
        final createdAtValue = row.data['created_at'];
        if (createdAtValue is int) {
          date = DateTime.fromMillisecondsSinceEpoch(createdAtValue).toLocal();
        } else if (createdAtValue is DateTime) {
          date = createdAtValue.toLocal();
        }

        final txId = row.data['id'] as String? ?? '';
        final invoiceNumber = txId.isNotEmpty
            ? 'INV-${txId.substring(0, 8).toUpperCase()}'
            : '-';

        return {
          'invoice_number': invoiceNumber,
          'total': (row.data['total_amount'] as num?)?.toDouble() ?? 0.0,
          'date': date,
          'cashier': row.data['cashier_name'] as String? ?? 'System',
          'status': 'completed',
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('store_id');
      await prefs.remove('user_role');
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<List<Map<String, dynamic>>> _getLifetimeRevenue(
    AdminController controller,
  ) async {
    try {
      final db = controller.database;
      if (db == null) return [];
      final results = await db
          .customSelect(
            '''
        SELECT 
          strftime('%Y-%m', datetime(created_at/1000, 'unixepoch')) as month,
          SUM(total_amount) as revenue
        FROM transactions
        WHERE store_id = ? GROUP BY month ORDER BY month ASC
        ''',
            variables: [Variable.withString(controller.storeId!)],
          )
          .get();

      return results.map((row) {
        final monthStr = row.data['month'] as String?;
        final revenue = (row.data['revenue'] as num?)?.toDouble() ?? 0.0;
        String label = monthStr ?? '';
        if (monthStr != null) {
          try {
            final parts = monthStr.split('-');
            if (parts.length == 2) {
              final month = int.parse(parts[1]);
              final monthNames = [
                'Jan',
                'Feb',
                'Mar',
                'Apr',
                'May',
                'Jun',
                'Jul',
                'Aug',
                'Sep',
                'Oct',
                'Nov',
                'Dec',
              ];
              label = '${monthNames[month - 1]} ${parts[0].substring(2)}';
            }
          } catch (e) {}
        }
        return {'label': label, 'amount': revenue};
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, double>> _getGrowthMetrics(
    AdminController controller,
  ) async {
    try {
      final db = controller.database;
      if (db == null) return {'weekly': 0.0, 'monthly': 0.0};
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final startOfThisWeek = startOfToday.subtract(
        Duration(days: now.weekday - 1),
      );
      final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));
      final startOfThisMonth = DateTime(now.year, now.month, 1);
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);

      final thisWeekRes = await db
          .customSelect(
            'SELECT COALESCE(SUM(total_amount), 0) as total FROM transactions WHERE store_id = ? AND created_at >= ?',
            variables: [
              Variable.withString(controller.storeId!),
              Variable.withInt(startOfThisWeek.millisecondsSinceEpoch),
            ],
          )
          .getSingle();
      final lastWeekRes = await db
          .customSelect(
            'SELECT COALESCE(SUM(total_amount), 0) as total FROM transactions WHERE store_id = ? AND created_at >= ? AND created_at < ?',
            variables: [
              Variable.withString(controller.storeId!),
              Variable.withInt(startOfLastWeek.millisecondsSinceEpoch),
              Variable.withInt(startOfThisWeek.millisecondsSinceEpoch),
            ],
          )
          .getSingle();
      final thisWeek = (thisWeekRes.data['total'] as num?)?.toDouble() ?? 0.0;
      final lastWeek = (lastWeekRes.data['total'] as num?)?.toDouble() ?? 0.0;
      final weeklyGrowth = lastWeek == 0
          ? (thisWeek > 0 ? 100.0 : 0.0)
          : ((thisWeek - lastWeek) / lastWeek * 100);

      final thisMonthRes = await db
          .customSelect(
            'SELECT COALESCE(SUM(total_amount), 0) as total FROM transactions WHERE store_id = ? AND created_at >= ?',
            variables: [
              Variable.withString(controller.storeId!),
              Variable.withInt(startOfThisMonth.millisecondsSinceEpoch),
            ],
          )
          .getSingle();
      final lastMonthRes = await db
          .customSelect(
            'SELECT COALESCE(SUM(total_amount), 0) as total FROM transactions WHERE store_id = ? AND created_at >= ? AND created_at < ?',
            variables: [
              Variable.withString(controller.storeId!),
              Variable.withInt(startOfLastMonth.millisecondsSinceEpoch),
              Variable.withInt(startOfThisMonth.millisecondsSinceEpoch),
            ],
          )
          .getSingle();
      final thisMonth = (thisMonthRes.data['total'] as num?)?.toDouble() ?? 0.0;
      final lastMonth = (lastMonthRes.data['total'] as num?)?.toDouble() ?? 0.0;
      final monthlyGrowth = lastMonth == 0
          ? (thisMonth > 0 ? 100.0 : 0.0)
          : ((thisMonth - lastMonth) / lastMonth * 100);

      return {'weekly': weeklyGrowth, 'monthly': monthlyGrowth};
    } catch (e) {
      return {'weekly': 0.0, 'monthly': 0.0};
    }
  }

  Widget _buildLifetimeRevenueChart(
    List<Map<String, dynamic>> chartData,
    NumberFormat currency,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PinterestCard(
      padding: const EdgeInsets.fromLTRB(10, 24, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chartData.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Text('Belum ada data transaksi'),
              ),
            )
          else
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (val) => FlLine(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          space: 12,
                          child: Text(
                            NumberFormat.compactSimpleCurrency(
                              locale: 'id',
                            ).format(value),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < chartData.length) {
                            return SideTitleWidget(
                              meta: meta,
                              space: 8,
                              child: Text(
                                chartData[idx]['label'],
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(chartData.length, (i) {
                        return FlSpot(i.toDouble(), chartData[i]['amount']);
                      }),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: const Color(0xFFEA5700),
                      barWidth: 4,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFEA5700).withValues(alpha: 0.2),
                            const Color(0xFFEA5700).withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) =>
                          isDark ? const Color(0xFF2C2C2E) : Colors.white,
                      tooltipRoundedRadius: 12,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots
                            .map(
                              (spot) => LineTooltipItem(
                                currency.format(spot.y),
                                GoogleFonts.poppins(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            )
                            .toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrowthIndicators(double weekly, double monthly, bool isDark) {
    return Column(
      children: [
        _buildGrowthMiniCard("Trend Mingguan", weekly, isDark),
        const SizedBox(height: 12),
        _buildGrowthMiniCard("Trend Bulanan", monthly, isDark),
      ],
    );
  }

  Widget _buildGrowthMiniCard(String label, double growth, bool isDark) {
    final isPos = growth >= 0;
    final color = isPos ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return PinterestCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(
            isPos
                ? CupertinoIcons.arrow_up_circle_fill
                : CupertinoIcons.arrow_down_circle_fill,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            "${isPos ? '+' : ''}${growth.toStringAsFixed(1)}%",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
