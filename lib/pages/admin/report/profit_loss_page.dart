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
  String _selectedRange = 'Hari Ini'; // Hari Ini, Minggu Ini, Bulan Ini

  double _totalRevenue = 0;
  double _totalCost = 0;
  double _totalProfit = 0;

  List<Map<String, dynamic>> _chartData = [];

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

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      DateTime startDate;

      if (_selectedRange == 'Hari Ini') {
        startDate = DateTime(now.year, now.month, now.day);
      } else if (_selectedRange == 'Minggu Ini') {
        // Start of week (Monday)
        startDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
      } else {
        // Start of month
        startDate = DateTime(now.year, now.month, 1);
      }

      // 1. Fetch Transactions
      final txResponse = await supabase
          .from('transactions')
          .select('id, total_amount, created_at')
          .eq('store_id', widget.storeId)
          .gte('created_at', startDate.toIso8601String())
          .order('created_at');

      double revenue = 0;
      double cost = 0;
      Map<String, double> profitMap = {};

      for (var tx in txResponse) {
        final txId = tx['id'];
        final total = (tx['total_amount'] as num).toDouble();
        final date = DateTime.parse(tx['created_at']).toLocal();

        revenue += total;

        // 2. Fetch Items for Cost Calculation
        // Note: Ideally, 'buy_price' should be stored in 'transaction_items' at the time of purchase.
        // If not, we have to fetch current product buy_price, which might be inaccurate for history.
        // Checking if 'transaction_items' table has cost info or we need to join products.
        // Based on previous analysis, 'transaction_items' has 'price_at_time'.
        // Let's assume we need to join products to get 'buy_price'.

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
        cost += txCost;

        // Chart Data Grouping
        String key;
        if (_selectedRange == 'Hari Ini') {
          key = DateFormat('HH:00').format(date);
        } else {
          key = DateFormat('dd MMM').format(date);
        }

        profitMap[key] = (profitMap[key] ?? 0) + (total - txCost);
      }

      _totalRevenue = revenue;
      _totalCost = cost;
      _totalProfit = revenue - cost;

      _chartData = profitMap.entries
          .map((e) => {'label': e.key, 'value': e.value})
          .toList();
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
          "Laba Rugi",
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
                    // Filter Range
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Hari Ini', 'Minggu Ini', 'Bulan Ini']
                            .map(
                              (range) => Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: ChoiceChip(
                                  label: Text(range),
                                  selected: _selectedRange == range,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _selectedRange = range);
                                      _fetchData();
                                    }
                                  },
                                  selectedColor: Colors.teal.withValues(
                                    alpha: 0.2,
                                  ),
                                  labelStyle: GoogleFonts.inter(
                                    color: _selectedRange == range
                                        ? Colors.teal
                                        : Colors.grey,
                                    fontWeight: _selectedRange == range
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  backgroundColor: isDark
                                      ? Colors.white10
                                      : Colors.grey[100],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: _selectedRange == range
                                          ? Colors.teal
                                          : Colors.transparent,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Net Profit Big Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [Colors.teal.shade900, Colors.teal.shade800]
                              : [Colors.teal, Colors.teal.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "LABA BERSIH (Gross Profit)",
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currencyFormat.format(_totalProfit),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Revenue vs Cost Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            "Pendapatan",
                            _totalRevenue,
                            Colors.blue,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            "Modal (HPP)",
                            _totalCost,
                            Colors.orange,
                            isDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    Text(
                      "Tren Keuntungan",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Simple Bar Chart
                    AspectRatio(
                      aspectRatio: 1.5,
                      child: _chartData.isEmpty
                          ? Center(
                              child: Text(
                                "Belum ada data",
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: _chartData.isEmpty
                                    ? 100
                                    : _chartData
                                              .map((e) => e['value'] as double)
                                              .reduce((a, b) => a > b ? a : b) *
                                          1.2,
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() >= 0 &&
                                            value.toInt() < _chartData.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8.0,
                                            ),
                                            child: Text(
                                              _chartData[value
                                                  .toInt()]['label'],
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          );
                                        }
                                        return SizedBox.shrink();
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                gridData: FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                barGroups: _chartData.asMap().entries.map((e) {
                                  return BarChartGroupData(
                                    x: e.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: e.value['value'] as double,
                                        color: Colors.teal,
                                        width: 12,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, double amount, Color color, bool isDark) {
    return Container(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _currencyFormat.format(amount),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
