import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/gold999_client.dart';

/// Interactive chart widget for GOLD 999 price history (24 hours)
class GoldChart extends StatelessWidget {
  final ChartData chartData;
  final String interval;

  const GoldChart({super.key, required this.chartData, required this.interval});

  @override
  Widget build(BuildContext context) {
    if (chartData.data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No chart data available'),
        ),
      );
    }

    final minPrice = chartData.data
        .map((p) => p.ltp)
        .reduce((a, b) => a < b ? a : b);
    final maxPrice = chartData.data
        .map((p) => p.ltp)
        .reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;
    final chartMin = minPrice - (priceRange * 0.1);
    final chartMax = maxPrice + (priceRange * 0.1);

    final isPositiveTrend = chartData.data.last.ltp >= chartData.data.first.ltp;
    final lineColor = isPositiveTrend ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time period info (24 hours only)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Last 24 Hours',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${chartData.data.length} data points',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Chart
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (chartMax - chartMin) / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
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
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: _getBottomInterval(),
                      getTitlesWidget: (value, meta) {
                        return _getBottomTitleWidget(value, meta);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60, // Increased to prevent truncation
                      interval: (chartMax - chartMin) / 5,
                      getTitlesWidget: (value, meta) {
                        final priceStr = NumberFormat(
                          '#,##,###',
                        ).format(value.toInt());
                        // Format with 'L' for lakhs if needed
                        final formatted = priceStr.length > 6
                            ? '₹${priceStr.substring(0, priceStr.length - 5)}L'
                            : '₹$priceStr';
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            formatted,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[300]!),
                ),
                minX: 0,
                maxX: (chartData.data.length - 1).toDouble(),
                minY: chartMin,
                maxY: chartMax,
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData.data.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.ltp);
                    }).toList(),
                    isCurved: true,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.grey[900]!,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final point = chartData.data[spot.x.toInt()];
                        return LineTooltipItem(
                          '₹${NumberFormat('#,##,###').format(spot.y.toInt())}\n${_formatTooltipTime(point.timestamp)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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

  double _getBottomInterval() {
    final length = chartData.data.length;
    if (length <= 10) return 1;
    if (length <= 20) return 2;
    if (length <= 50) return 5;
    return 10;
  }

  Widget _getBottomTitleWidget(double value, TitleMeta meta) {
    if (value.toInt() >= chartData.data.length) {
      return const Text('');
    }
    final point = chartData.data[value.toInt()];
    return Text(
      _formatAxisTime(point.timestamp),
      style: TextStyle(color: Colors.grey[600], fontSize: 10),
    );
  }

  String _formatAxisTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      // Format with AM/PM for 24-hour view
      return DateFormat('h a').format(date); // e.g., "1 PM", "6 AM"
    } catch (e) {
      return '';
    }
  }

  String _formatTooltipTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      // Format with AM/PM for tooltip
      return DateFormat(
        'MMM d, h:mm a',
      ).format(date); // e.g., "Oct 29, 2:30 PM"
    } catch (e) {
      return timestamp;
    }
  }
}
