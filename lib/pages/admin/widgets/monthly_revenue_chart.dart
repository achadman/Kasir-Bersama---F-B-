import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'pinterest_card.dart';

class MonthlyRevenueChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyData;
  final NumberFormat currencyFormat;

  const MonthlyRevenueChart({
    super.key,
    required this.monthlyData,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    if (monthlyData.isEmpty) {
      return PinterestCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Belum ada data penjualan',
            style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
          ),
        ),
      );
    }

    return PinterestCard(
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              'Penjualan Bulanan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
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
                      reservedSize: 50,
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
                        if (idx >= 0 && idx < monthlyData.length) {
                          return SideTitleWidget(
                            meta: meta,
                            space: 8,
                            child: Text(
                              monthlyData[idx]['month'],
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.bold,
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
                    spots: List.generate(monthlyData.length, (i) {
                      return FlSpot(i.toDouble(), monthlyData[i]['amount']);
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
                              currencyFormat.format(spot.y),
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
}
