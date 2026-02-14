import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ProfitLossPage extends StatefulWidget {
  final String storeId;
  const ProfitLossPage({super.key, required this.storeId});

  @override
  State<ProfitLossPage> createState() => _ProfitLossPageState();
}

class _ProfitLossPageState extends State<ProfitLossPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;

  // Data State
  int _selectedYear = DateTime.now().year;
  List<int> _availableYears = [];

  // Summary Metrics
  double _totalProfitAllTime = 0;
  double _thisMonthProfit = 0;
  double _lastMonthProfit = 0;

  double _thisMonthRevenue = 0;
  double _lastMonthRevenue = 0;

  // Chart Data: Year -> Week (1-53) -> Profit
  // Also storing a mapping of Week -> MonthName for labels
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
      final txResponse = await supabase
          .from('transactions')
          .select('id, total_amount, created_at')
          .eq('store_id', widget.storeId)
          .eq('status', 'completed')
          .order('created_at');

      double totalRevAll = 0;
      double totalCostAll = 0;

      Map<int, Map<int, double>> tempWeeklyProfit = {};
      Map<int, Map<int, String>> tempWeekToMonthLabel = {};
      Set<int> years = {};

      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month);
      final lastMonth = DateTime(now.year, now.month - 1);

      double thisMonRev = 0;
      double thisMonCost = 0;
      double lastMonRev = 0;
      double lastMonCost = 0;

      for (var tx in txResponse) {
        final txId = tx['id'];
        final total = (tx['total_amount'] as num).toDouble();
        final date = DateTime.parse(tx['created_at']).toLocal();
        final year = date.year;
        // final month = date.month; // Unused
        final week = _getWeekNumber(date);

        years.add(year);

        final itemsResponse = await supabase
            .from('transaction_items')
            .select('quantity, products(buy_price)')
            .eq('transaction_id', txId);

        double txCost = 0;
        for (var item in itemsResponse) {
          final qty = (item['quantity'] as num).toDouble();
          final product = item['products'] as Map<String, dynamic>?;
          final buyPrice = (product?['buy_price'] ?? 0) as num;
          txCost += (qty * buyPrice);
        }

        final profit = total - txCost;

        totalRevAll += total;
        totalCostAll += txCost;

        // Group by Year/Week
        if (!tempWeeklyProfit.containsKey(year)) {
          tempWeeklyProfit[year] = {};
          tempWeekToMonthLabel[year] = {};
        }
        tempWeeklyProfit[year]![week] =
            (tempWeeklyProfit[year]![week] ?? 0) + profit;

        // Label logic: Map week to its Month name (short)
        // If multiple months in a week, usually the month of the start date wins,
        // or just use the month of this transaction.
        // We'll overwrite, so the last tx in that week determines the label (roughly same month).
        if (!tempWeekToMonthLabel[year]!.containsKey(week)) {
          tempWeekToMonthLabel[year]![week] = DateFormat.MMM().format(date);
        }

        // Specific Summaries (Monthly logic remains for cards)
        if (date.year == thisMonth.year && date.month == thisMonth.month) {
          thisMonRev += total;
          thisMonCost += txCost;
        } else if (date.year == lastMonth.year &&
            date.month == lastMonth.month) {
          lastMonRev += total;
          lastMonCost += txCost;
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
      _thisMonthProfit = thisMonRev - thisMonCost;
      _lastMonthProfit = lastMonRev - lastMonCost;

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
                      height: 140,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildSummaryCard(
                            "Bulan Ini",
                            _thisMonthProfit,
                            _thisMonthRevenue,
                            Colors.teal,
                            isDark,
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryCard(
                            "Bulan Lalu",
                            _lastMonthProfit,
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

                    // Filter Year
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Grafik Mingguan",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        DropdownButton<int>(
                          value: _selectedYear,
                          dropdownColor: Theme.of(context).cardColor,
                          underline: const SizedBox(),
                          icon: Icon(Icons.arrow_drop_down, color: textColor),
                          style: GoogleFonts.inter(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                          items: _availableYears.map((year) {
                            return DropdownMenuItem<int>(
                              value: year,
                              child: Text(year.toString()),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedYear = val);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Line Chart
                    AspectRatio(
                      aspectRatio: 1.2,
                      child: _buildLineChart(isDark),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double profit,
    double revenue,
    Color color,
    bool isDark,
  ) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(profit),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Rev: ${_currencyFormat.format(revenue)}",
            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(bool isDark) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2C3E50), const Color(0xFF34495E)]
              : [const Color(0xFF2C3E50), const Color(0xFF34495E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(_totalProfitAllTime),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
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
              color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.2),
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
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final weekIndex = value.toInt();
                // Show label if this week exists in data
                if (dataPoints.any((e) => e.key == weekIndex)) {
                  // Show month label roughly once per month or if strictly needed
                  // Let's show month name if it's available in our map
                  final label = selectedYearLabels[weekIndex] ?? '';

                  // To avoid clustering, maybe only show if it's the first time this label appears?
                  // Simple heuristic: always show, let chart handle overlap or skip
                  // Or just show W{num}

                  // User asked: "shows chart by weeks ... shows analytic even though its not a year"
                  // Maybe just showing W1, W2 etc is fine?
                  // But "shows analytic" implies maybe dates.
                  // Let's try combining: "W1\nJan" if it fits?
                  // Or just "Jan" if it's the first week of Jan?

                  // Let's just show Month (Jan) and maybe Day?
                  // Week numbers are abstract.
                  // Let's use the stored Month Label.
                  // To avoid repetition ("Jan", "Jan", "Jan"), we can check previous.

                  // Check if previous sorted data point had same month?
                  // Too complex for `getTitlesWidget`.

                  // Let's just show Week number for clarity + Month if possible?
                  // Or just Month.

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
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
                            color: Colors.grey.withOpacity(0.7),
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
}
