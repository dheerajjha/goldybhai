import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/gold999_client.dart';
import '../l10n/app_localizations.dart';

/// Interactive chart widget for GOLD 999 price history (1 hour)
class GoldChart extends StatelessWidget {
  final ChartData chartData;
  final String interval;
  final String period;

  const GoldChart({
    super.key,
    required this.chartData,
    required this.interval,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    print('📈 GoldChart build called with ${chartData.data.length} points');

    if (chartData.data.isEmpty) {
      print('📈 Chart data is empty, showing empty state');
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No chart data available'),
        ),
      );
    }

    print('📈 Rendering chart with ${chartData.data.length} points');

    final minPrice = chartData.data
        .map((p) => p.ltp)
        .reduce((a, b) => a < b ? a : b);
    final maxPrice = chartData.data
        .map((p) => p.ltp)
        .reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;

    // Ensure minimum range to avoid zero interval
    final effectiveRange = priceRange > 0 ? priceRange : maxPrice * 0.01;
    final chartMin = minPrice - (effectiveRange * 0.1);
    final chartMax = maxPrice + (effectiveRange * 0.1);

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
                      AppLocalizations.of(context)?.last24Hours ??
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
                  AppLocalizations.of(
                        context,
                      )?.dataPoints(chartData.data.length) ??
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
                      reservedSize: 65,
                      interval: (chartMax - chartMin) / 5,
                      getTitlesWidget: (value, meta) {
                        // Show full price with Indian formatting to see all digit changes
                        // Format: 1,24,121 (shows all digits for precision)
                        final price = value.toInt();
                        final str = price.toString();
                        
                        // Indian numbering: last 3 digits, then groups of 2
                        String formatted;
                        if (str.length <= 3) {
                          formatted = str;
                        } else if (str.length <= 5) {
                          formatted = '${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
                        } else {
                          // For 6+ digits: X,XX,XXX format
                          final last3 = str.substring(str.length - 3);
                          final remaining = str.substring(0, str.length - 3);
                          final middle2 = remaining.substring(remaining.length - 2);
                          final first = remaining.substring(0, remaining.length - 2);
                          formatted = '$first,$middle2,$last3';
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            formatted,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
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
    // Show max 6-8 labels on X-axis to prevent overlap
    if (length <= 10) return 1.0;
    if (length <= 20) return 3.0;
    if (length <= 50) return 8.0;
    if (length <= 100) return 15.0;
    if (length <= 200) return 30.0;
    return (length / 6).floorToDouble(); // Show ~6 labels for any length
  }

  Widget _getBottomTitleWidget(double value, TitleMeta meta) {
    if (value.toInt() >= chartData.data.length) {
      return const SizedBox.shrink();
    }

    // Only show labels at specific intervals to prevent overlap
    final interval = _getBottomInterval();
    if (value.toInt() % interval.toInt() != 0) {
      return const SizedBox.shrink();
    }

    final point = chartData.data[value.toInt()];
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        _formatAxisTime(point.timestamp),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatAxisTime(DateTime timestamp) {
    try {
      // Format with minutes and AM/PM for clarity
      return DateFormat(
        'h:mm a',
      ).format(timestamp); // e.g., "1:30 PM", "2:45 PM"
    } catch (e) {
      return '';
    }
  }

  String _formatTooltipTime(DateTime timestamp) {
    try {
      // Format with AM/PM for tooltip
      return DateFormat('h:mm a').format(timestamp); // e.g., "2:30 PM"
    } catch (e) {
      return timestamp.toString();
    }
  }
}
