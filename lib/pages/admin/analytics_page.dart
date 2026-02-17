import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/analytics_controller.dart';
import '../../controllers/admin_controller.dart';
import 'employee_page.dart';
import 'history/history_page.dart';
import 'inventory_page.dart';
import 'widgets/pinterest_card.dart';
import 'widgets/stat_card.dart';

class AnalyticsPage extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  final Function(int index)? onNavigateToIndex;
  const AnalyticsPage({super.key, this.onMenuPressed, this.onNavigateToIndex});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminCtrl = Provider.of<AdminController>(context, listen: false);
      Provider.of<AnalyticsController>(
        context,
        listen: false,
      ).init(adminCtrl.storeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Analitik Bisnis",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
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
        actions: [
          IconButton(
            onPressed: () => context.read<AnalyticsController>().refreshData(),
            icon: const Icon(CupertinoIcons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<AnalyticsController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CupertinoActivityIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => controller.refreshData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("RINGKASAN PERFORMA"),
                  const SizedBox(height: 16),
                  _buildGridSummary(controller, isDark, context, currency),
                  const SizedBox(height: 32),
                  _buildSectionTitle("GRAFIK PENDAPATAN"),
                  const SizedBox(height: 16),
                  _buildChartSection(controller, currency, isDark),
                  const SizedBox(height: 32),
                  _buildSectionTitle("PERTUMBUHAN BISNIS"),
                  const SizedBox(height: 16),
                  _buildGrowthIndicators(controller, isDark),
                  const SizedBox(height: 32),
                  _buildReportLink(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
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

  Widget _buildGridSummary(
    AnalyticsController controller,
    bool isDark,
    BuildContext context,
    NumberFormat currency,
  ) {
    final storeId = context.read<AdminController>().storeId;

    final cards = [
      StatCard(
        title: "Karyawan",
        value: "${controller.employeeCount}",
        icon: CupertinoIcons.person_2_fill,
        color: const Color(0xFF3B82F6),
        onTap: () {
          if (widget.onNavigateToIndex != null) {
            widget.onNavigateToIndex!(5);
          } else if (storeId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EmployeePage(storeId: storeId)),
            );
          }
        },
      ),
      StatCard(
        title: "Transaksi",
        value: "${controller.totalTransactionCount}",
        icon: CupertinoIcons.doc_text_fill,
        color: const Color(0xFFF59E0B),
        onTap: () {
          if (widget.onNavigateToIndex != null) {
            widget.onNavigateToIndex!(4);
          } else if (storeId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HistoryPage(storeId: storeId)),
            );
          }
        },
      ),
      StatCard(
        title: "Hari Ini",
        value: currency.format(controller.todaySales),
        icon: Icons.today_rounded,
        color: const Color(0xFFEA5700),
        onTap: () => controller.setRange(ChartRange.today),
      ),
      StatCard(
        title: "Minggu Ini",
        value: currency.format(controller.thisWeekSales),
        icon: Icons.calendar_view_week_rounded,
        color: const Color(0xFF6366F1),
        onTap: () => controller.setRange(ChartRange.week),
      ),
      StatCard(
        title: "Bulan Ini",
        value: currency.format(controller.thisMonthSales),
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF10B981),
        onTap: () => controller.setRange(ChartRange.month),
      ),
      StatCard(
        title: "Produk",
        value: "${controller.totalProductCount}",
        icon: CupertinoIcons.cube_box_fill,
        color: const Color(0xFF8B5CF6),
        onTap: () {
          if (widget.onNavigateToIndex != null) {
            widget.onNavigateToIndex!(1);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InventoryPage()),
            );
          }
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 550;
        if (isWide) {
          return GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
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
    );
  }

  Widget _buildChartSection(
    AnalyticsController controller,
    NumberFormat currency,
    bool isDark,
  ) {
    return PinterestCard(
      padding: const EdgeInsets.fromLTRB(10, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: _buildRangeFilters(controller, isDark),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                      strokeWidth: 1,
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
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          space: 12,
                          child: Text(
                            NumberFormat.compactSimpleCurrency(
                              locale: 'id',
                            ).format(value),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < controller.chartData.length) {
                          // Show only some labels to avoid crowding
                          bool shouldShow = true;
                          if (controller.selectedRange == ChartRange.month) {
                            shouldShow = idx % 5 == 0;
                          } else if (controller.selectedRange ==
                              ChartRange.today) {
                            shouldShow = idx % 4 == 0;
                          }

                          if (shouldShow) {
                            return SideTitleWidget(
                              meta: meta,
                              space: 8,
                              child: Text(
                                controller.chartData[idx]['label'],
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(controller.chartData.length, (i) {
                      return FlSpot(
                        i.toDouble(),
                        controller.chartData[i]['amount'] as double,
                      );
                    }),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF6366F1),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: controller.selectedRange != ChartRange.month,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 3,
                          strokeColor: const Color(0xFF6366F1),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6366F1).withValues(alpha: 0.2),
                          const Color(0xFF6366F1).withValues(alpha: 0.0),
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
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          currency.format(spot.y),
                          GoogleFonts.poppins(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF2D3436),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        );
                      }).toList();
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

  Widget _buildRangeFilters(AnalyticsController controller, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterBtn(controller, ChartRange.today, "Hari Ini"),
          const SizedBox(width: 8),
          _buildFilterBtn(controller, ChartRange.week, "Minggu"),
          const SizedBox(width: 8),
          _buildFilterBtn(controller, ChartRange.month, "Bulan"),
        ],
      ),
    );
  }

  Widget _buildFilterBtn(
    AnalyticsController controller,
    ChartRange range,
    String label,
  ) {
    final isSelected = controller.selectedRange == range;
    return GestureDetector(
      onTap: () => controller.setRange(range),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1)
              : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey[100]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildGrowthIndicators(AnalyticsController controller, bool isDark) {
    return Column(
      children: [
        _buildGrowthCard("Mingguan", controller.weeklyGrowth, isDark),
        const SizedBox(height: 16),
        _buildGrowthCard("Bulanan", controller.monthlyGrowth, isDark),
      ],
    );
  }

  Widget _buildGrowthCard(String label, double growth, bool isDark) {
    final isPositive = growth >= 0;
    final color = isPositive
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return PinterestCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isPositive
                  ? CupertinoIcons.graph_circle_fill
                  : CupertinoIcons.graph_circle,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  isPositive ? "Mengalami kenaikan" : "Mengalami penurunan",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${isPositive ? '+' : ''}${growth.toStringAsFixed(1)}%",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color,
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportLink(BuildContext context) {
    return PinterestCard(
      color: const Color(0xFF6366F1),
      onTap: () {
        if (widget.onNavigateToIndex != null) {
          widget.onNavigateToIndex!(11); // ProfitLoss index
        }
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              CupertinoIcons.doc_chart_fill,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Laporan Laba Rugi",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Analisis keuntungan & kerugian",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const Icon(CupertinoIcons.arrow_right, color: Colors.white),
        ],
      ),
    );
  }
}
