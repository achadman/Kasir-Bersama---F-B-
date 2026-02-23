import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import '../../../services/app_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:drift/drift.dart' hide Column, Table;

import '../../../services/export_service.dart';
import '../../../services/platform/file_manager.dart';
import '../widgets/pinterest_card.dart';
import 'expense_management_page.dart';

class ProfitLossPage extends StatefulWidget {
  final String storeId;
  final VoidCallback? onMenuPressed;
  const ProfitLossPage({super.key, required this.storeId, this.onMenuPressed});

  @override
  State<ProfitLossPage> createState() => _ProfitLossPageState();
}

class _ProfitLossPageState extends State<ProfitLossPage> {
  bool _isLoading = true;
  final _exportService = ExportService();

  // Data State
  int _selectedYear = DateTime.now().year;
  List<int> _availableYears = [];

  // Summary Metrics
  double _totalProfitAllTime = 0;
  double _totalExpensesAllTime = 0;

  double _thisMonthProfit = 0;
  double _thisMonthExpenses = 0;
  double _lastMonthProfit = 0;
  double _lastMonthExpenses = 0;

  double _thisMonthRevenue = 0;
  double _lastMonthRevenue = 0;

  double _thisWeekProfit = 0;
  double _lastWeekProfit = 0;

  // Chart Data: Year -> Week (1-53) -> Profit (Gross)
  Map<int, Map<int, double>> _weeklyProfit = {};
  Map<int, Map<int, String>> _weekToMonthLabel = {};

  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Simple Week Number Calculation (ISO-8601-ish)
  int _getWeekNumber(DateTime date) {
    int dayOfYear = int.parse(DateFormat("D").format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final db = context.read<AppDatabase>();

      // We join transactions with their items and products to get buy_price (basePrice)
      final query = db.select(db.transactions).join([
        leftOuterJoin(
          db.transactionItems,
          db.transactionItems.transactionId.equalsExp(db.transactions.id),
        ),
        leftOuterJoin(
          db.products,
          db.products.id.equalsExp(db.transactionItems.productId),
        ),
      ])..where(db.transactions.storeId.equals(widget.storeId));

      final results = await query.get();

      double totalRevAll = 0;
      double totalCostAll = 0;

      Map<int, Map<int, double>> tempWeeklyProfit = {};
      Map<int, Map<int, String>> tempWeekToMonthLabel = {};
      Set<int> years = {};

      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month);
      final lastMonth = now.month == 1
          ? DateTime(now.year - 1, 12)
          : DateTime(now.year, now.month - 1);

      final thisWeekNum = _getWeekNumber(now);
      final lastWeekNum = thisWeekNum == 1
          ? 52
          : thisWeekNum - 1; // Simplistic wrap
      final currentYear = now.year;
      final prevYear = thisWeekNum == 1 ? now.year - 1 : now.year;

      double thisMonRev = 0;
      double thisMonCost = 0;
      double lastMonRev = 0;
      double lastMonCost = 0;

      double thisWkProfit = 0;
      double lastWkProfit = 0;

      // Group by transaction to avoid double counting transaction-level totals
      // Drift join returns one row per item
      Map<String, double> txRevenues = {};
      Map<String, double> txCosts = {};
      Map<String, DateTime> txDates = {};

      for (var row in results) {
        final tx = row.readTable(db.transactions);
        final item = row.readTableOrNull(db.transactionItems);
        final product = row.readTableOrNull(db.products);

        final txId = tx.id;
        final date = tx.createdAt?.toLocal() ?? DateTime.now();

        if (!txRevenues.containsKey(txId)) {
          txRevenues[txId] = tx.totalAmount ?? 0;
          txDates[txId] = date;
          txCosts[txId] = 0;
        }

        if (item != null) {
          final qty = (item.quantity ?? 0).toDouble();
          final buyPrice = product?.basePrice ?? 0;
          txCosts[txId] = (txCosts[txId] ?? 0) + (qty * buyPrice);
        }
      }

      // Process grouped transactions
      txRevenues.forEach((txId, rev) {
        final date = txDates[txId]!;
        final cost = txCosts[txId] ?? 0;
        final profit = rev - cost;
        final year = date.year;
        final week = _getWeekNumber(date);

        years.add(year);
        totalRevAll += rev;
        totalCostAll += cost;

        if (!tempWeeklyProfit.containsKey(year)) {
          tempWeeklyProfit[year] = {};
          tempWeekToMonthLabel[year] = {};
        }
        tempWeeklyProfit[year]![week] =
            (tempWeeklyProfit[year]![week] ?? 0) + profit;

        if (!tempWeekToMonthLabel[year]!.containsKey(week)) {
          tempWeekToMonthLabel[year]![week] = DateFormat.MMM().format(date);
        }

        // Monthly Check
        if (date.year == thisMonth.year && date.month == thisMonth.month) {
          thisMonRev += rev;
          thisMonCost += cost;
        } else if (date.year == lastMonth.year &&
            date.month == lastMonth.month) {
          lastMonRev += rev;
          lastMonCost += cost;
        }

        // Weekly Check
        if (year == currentYear && week == thisWeekNum) {
          thisWkProfit += profit;
        } else if (year == prevYear && week == lastWeekNum) {
          lastWkProfit += profit;
        }
      });

      _thisWeekProfit = thisWkProfit;
      _lastWeekProfit = lastWkProfit;

      // 2. Fetch Expenses
      final allExpenses = await (db.select(
        db.expenses,
      )..where((t) => t.storeId.equals(widget.storeId))).get();

      double totalExpAll = 0;
      double thisMonExp = 0;
      double lastMonExp = 0;

      for (var exp in allExpenses) {
        final date = exp.date ?? DateTime.now();
        final amount = exp.amount ?? 0;
        totalExpAll += amount;

        if (date.year == thisMonth.year && date.month == thisMonth.month) {
          thisMonExp += amount;
        } else if (date.year == lastMonth.year &&
            date.month == lastMonth.month) {
          lastMonExp += amount;
        }
      }

      _availableYears = years.toList()..sort((a, b) => b.compareTo(a));
      if (_availableYears.isEmpty) {
        _availableYears = [now.year];
      }
      if (!_availableYears.contains(_selectedYear)) {
        _selectedYear = _availableYears.first;
      }

      _weeklyProfit = tempWeeklyProfit;
      _weekToMonthLabel = tempWeekToMonthLabel;
      _totalProfitAllTime = totalRevAll - totalCostAll;
      _totalExpensesAllTime = totalExpAll;

      _thisMonthProfit = thisMonRev - thisMonCost;
      _thisMonthExpenses = thisMonExp;

      _lastMonthProfit = lastMonRev - lastMonCost;
      _lastMonthExpenses = lastMonExp;

      _thisMonthRevenue = thisMonRev;
      _lastMonthRevenue = lastMonRev;
    } catch (e) {
      debugPrint("Error fetching profit data: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal memuat data: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleExport(String type) async {
    final yearData = _weeklyProfit[_selectedYear] ?? {};
    if (yearData.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      Uint8List bytes;
      String filename;
      String mimeType;

      double totalProfit = yearData.values.fold(0, (sum, val) => sum + val);

      if (type == 'pdf') {
        bytes = await _exportService.generateProfitLossPdf(
          "ASRI Store",
          _selectedYear,
          yearData,
          totalProfit,
        );
        filename = "Laporan_LabaRugi_$_selectedYear.pdf";
        mimeType = "application/pdf";
      } else {
        bytes = await _exportService.generateProfitLossExcel(
          "ASRI Store",
          _selectedYear,
          yearData,
          totalProfit,
        );
        filename = "Laporan_LabaRugi_$_selectedYear.xlsx";
        mimeType =
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
      }

      await FileManager().saveAndShareBytes(
        filename,
        bytes,
        mimeType: mimeType,
      );
    } catch (e) {
      debugPrint("Export Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal ekspor: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showExportMenu() {
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
                "Pilih Format Ekspor ($_selectedYear)",
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Laba Rugi (Mingguan)",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ExpenseManagementPage(storeId: widget.storeId),
              ),
            ).then((_) => _fetchData()),
            icon: const Icon(CupertinoIcons.plus_app),
            tooltip: "Kelola Pengeluaran",
          ),
          IconButton(
            onPressed: (_weeklyProfit[_selectedYear] ?? {}).isEmpty
                ? null
                : _showExportMenu,
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
                onPressed: () => Navigator.pop(context),
                icon: const Icon(CupertinoIcons.back),
              );
            }

            return IconButton(
              onPressed: () {
                if (widget.onMenuPressed != null) {
                  widget.onMenuPressed!();
                } else {
                  Scaffold.of(context).openDrawer();
                }
              },
              icon: const Icon(CupertinoIcons.bars),
            );
          },
        ),
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: GoogleFonts.poppins(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards Carousel
                    SizedBox(
                      height: 180,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildSummaryCard(
                            "Bulan Ini",
                            _thisMonthProfit,
                            _thisMonthExpenses,
                            _thisMonthRevenue,
                            Colors.blue,
                            isDark,
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryCard(
                            "Bulan Lalu",
                            _lastMonthProfit,
                            _lastMonthExpenses,
                            _lastMonthRevenue,
                            Colors.orange,
                            isDark,
                          ),
                          const SizedBox(width: 12),
                          _buildTotalCard(isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Weekly Status & Progress
                    _buildWeeklyStatus(isDark),
                    const SizedBox(height: 30),

                    // Filter Year & Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Grafik Mingguan",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              "Performa profit tiap minggu",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        _buildYearPicker(isDark),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Line Chart (Smaller)
                    SizedBox(height: 220, child: _buildLineChart(isDark)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double grossProfit,
    double expenses,
    double revenue,
    Color color,
    bool isDark,
  ) {
    final netProfit = grossProfit - expenses;
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "Rev: ${_currencyFormat.format(revenue)}",
                style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetricLine(
            "Laba Kotor",
            grossProfit,
            Colors.grey[600]!,
            isDark,
          ),
          const SizedBox(height: 4),
          _buildMetricLine("Pengeluaran", expenses, Colors.red[400]!, isDark),
          const Divider(height: 16),
          _buildMetricLine(
            "Laba Bersih",
            netProfit,
            color,
            isDark,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricLine(
    String label,
    double val,
    Color color,
    bool isDark, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          _currencyFormat.format(val),
          style: GoogleFonts.poppins(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 14 : 12,
            color: isBold
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCard(bool isDark) {
    final netProfitTotal = _totalProfitAllTime - _totalExpensesAllTime;
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Total (All Time)",
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildTotalMetricLine("Laba Kotor", _totalProfitAllTime),
          _buildTotalMetricLine("Pengeluaran", _totalExpensesAllTime),
          const Divider(height: 16, color: Colors.white10),
          _buildTotalMetricLine("Laba Bersih", netProfitTotal, isBold: true),
        ],
      ),
    );
  }

  Widget _buildTotalMetricLine(
    String label,
    double val, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.white60),
        ),
        Text(
          _currencyFormat.format(val),
          style: GoogleFonts.poppins(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 14 : 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(bool isDark) {
    final Map<int, double> selectedYearData =
        _weeklyProfit[_selectedYear] ?? {};
    final Map<int, String> selectedYearLabels =
        _weekToMonthLabel[_selectedYear] ?? {};

    // 1. Prepare sorted data points
    final List<MapEntry<int, double>> dataPoints =
        selectedYearData.entries.where((e) => e.value != 0).toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    if (dataPoints.isEmpty) {
      return Center(
        child: Text(
          "Tidak ada data transaksi untuk tahun $_selectedYear",
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }

    // 2. Calculate Min/Max for Y-Axis
    double maxY = 0;
    double minY = 0;
    for (var e in dataPoints) {
      if (e.value > maxY) maxY = e.value;
      if (e.value < minY) minY = e.value;
    }
    final yBuffer = (maxY - minY).abs() * 0.2;
    maxY += yBuffer;
    if (minY < 0) minY -= yBuffer;
    if (minY == 0 && maxY == 0) maxY = 100;

    // 3. Create Line Segments (Green/Red)
    List<LineChartBarData> lineBarsData = [];

    if (dataPoints.length == 1) {
      // Single point
      lineBarsData.add(
        LineChartBarData(
          spots: [FlSpot(dataPoints[0].key.toDouble(), dataPoints[0].value)],
          color: Colors.teal,
          barWidth: 4,
          dotData: const FlDotData(show: true),
        ),
      );
    } else {
      for (int i = 0; i < dataPoints.length - 1; i++) {
        final current = dataPoints[i];
        final next = dataPoints[i + 1];

        final isGrowth = next.value >= current.value;
        final color = isGrowth ? Colors.green : Colors.red;

        lineBarsData.add(
          LineChartBarData(
            spots: [
              FlSpot(current.key.toDouble(), current.value),
              FlSpot(next.key.toDouble(), next.value),
            ],
            color: color,
            barWidth: 3,
            isCurved: false,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: color,
                  strokeWidth: 1,
                  strokeColor: isDark ? Colors.black : Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
        );
      }
    }

    return LineChart(
      LineChartData(
        minX: dataPoints.first.key.toDouble() - 0.5,
        maxX: dataPoints.last.key.toDouble() + 0.5,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark
                  ? Colors.white10
                  : Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final weekIndex = value.toInt();
                if (dataPoints.any((e) => e.key == weekIndex)) {
                  final label = selectedYearLabels[weekIndex] ?? '';
                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "W$weekIndex",
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey.withValues(alpha: 0.7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: lineBarsData,
        lineTouchData: LineTouchData(
          getTouchedSpotIndicator:
              (LineChartBarData barData, List<int> spotIndexes) {
                return spotIndexes.map((spotIndex) {
                  return TouchedSpotIndicatorData(
                    const FlLine(
                      color: Colors.grey,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                    FlDotData(
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: barData.color ?? Colors.teal,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  );
                }).toList();
              },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;
                return LineTooltipItem(
                  NumberFormat.compactSimpleCurrency(
                    locale: 'id',
                  ).format(flSpot.y),
                  TextStyle(
                    color: barSpot.bar.color ?? Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyStatus(bool isDark) {
    final diff = _thisWeekProfit - _lastWeekProfit;
    final isGrow = diff >= 0;
    final percent = _lastWeekProfit == 0
        ? (isGrow ? 100.0 : 0.0)
        : (diff / _lastWeekProfit.abs() * 100);

    return PinterestCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ringkasan Mingguan",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currencyFormat.format(_thisWeekProfit),
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (isGrow ? Colors.green : Colors.red).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGrow
                          ? CupertinoIcons.arrow_up_right
                          : CupertinoIcons.arrow_down_right,
                      color: isGrow ? Colors.green : Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${percent.abs().toStringAsFixed(1)}%",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isGrow ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isGrow ? "Pertumbuhan Profit" : "Penurunan Profit",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          isGrow ? "Bagus!" : "Waspada",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isGrow ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (percent.abs() / 100).clamp(0.1, 1.0),
                        backgroundColor: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isGrow ? Colors.green : Colors.red,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isGrow
                ? "Profit meningkat dibanding minggu lalu. Pertahankan!"
                : "Profit menurun. Periksa pengeluaran atau tingkatkan penjualan.",
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.grey[400],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearPicker(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _availableYears.take(3).map((year) {
          final isSelected = _selectedYear == year;
          return GestureDetector(
            onTap: () => setState(() => _selectedYear = year),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                year.toString(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : (isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
