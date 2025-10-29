import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/gold999_client.dart';

/// Interactive chart widget for GOLD 999 price history
class GoldChart extends StatelessWidget {
  final ChartData chartData;
  final String interval;
  final ValueChanged<String>? onIntervalChanged;

  const GoldChart({
    super.key,
    required this.chartData,
    required this.interval,
    this.onIntervalChanged,
  });

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

    final minPrice = chartData.data.map((p) => p.ltp).reduce((a, b) => a < b ? a : b);
    final maxPrice = chartData.data.map((p) => p.ltp).reduce((a, b) => a > b ? a : b);
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
          // Time period selector
          Row(
            children: [
              _buildPeriodButton(context, '1H', 'realtime', 1),
              const SizedBox(width: 8),
              _buildPeriodButton(context, '6H', 'hourly', 1),
              const SizedBox(width: 8),
              _buildPeriodButton(context, '1D', 'hourly', 1),
              const SizedBox(width: 8),
              _buildPeriodButton(context, '7D', 'hourly', 7),
              const SizedBox(width: 8),
              _buildPeriodButton(context, '30D', 'daily', 30),
            ],
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
                    return FlLine(
                      color: Colors.grey[200]!,
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
                        final priceStr = NumberFormat('#,##,###').format(value.toInt());
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

  Widget _buildPeriodButton(BuildContext context, String label, String intervalType, int days) {
    // Use exact match - check if current interval and days match this button's params
    final isSelected = interval == intervalType && 
                       chartData.metadata['period']?.toString().contains('$days') == true;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => onIntervalChanged?.call('$intervalType:$days'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.amber : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.amber.shade700 : Colors.transparent,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.grey[900] : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
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
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 10,
      ),
    );
  }

  String _formatAxisTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      // Check if this is a date-only format (no time component)
      if (timestamp.length <= 10 || !timestamp.contains('T') && !timestamp.contains(' ')) {
        return DateFormat('MMM d').format(date);
      } else if (interval == 'daily') {
        return DateFormat('MMM d').format(date);
      } else {
        return DateFormat('HH:mm').format(date);
      }
    } catch (e) {
      return '';
    }
  }

  String _formatTooltipTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return DateFormat('MMM d, HH:mm').format(date);
    } catch (e) {
      return timestamp;
    }
  }
}

