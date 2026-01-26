import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/pos_provider.dart';
import '../../core/app_theme.dart';
import '../../models/pos_models.dart';

class SalesChart extends StatefulWidget {
  const SalesChart({super.key});

  @override
  State<SalesChart> createState() => _SalesChartState();
}

class _SalesChartState extends State<SalesChart> {
  bool _showWeekly = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Revenue Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SegmentedButton<bool>(
                  segments: const [
                     ButtonSegment(value: true, label: Text('Weekly')),
                     ButtonSegment(value: false, label: Text('Monthly')),
                  ],
                  selected: {_showWeekly},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      _showWeekly = newSelection.first;
                    });
                  },
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 300,
              child: Consumer<POSProvider>(
                builder: (context, provider, child) {
                  return _showWeekly 
                      ? _buildWeeklyChart(provider.invoices)
                      : _buildMonthlyChart(provider.invoices);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(List<Invoice> invoices) {
    // 1. Process Data: Last 7 days
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last7Days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    
    // Map of date string to total amount
    final dataMap = <String, double>{};
    for (var date in last7Days) {
      dataMap[DateFormat('yyyy-MM-dd').format(date)] = 0;
    }

    for (var invoice in invoices) {
      if (invoice.status != InvoiceStatus.active) continue;
      
      final invoiceDate = DateTime(invoice.createdAt.year, invoice.createdAt.month, invoice.createdAt.day);
      if (invoiceDate.isAfter(today.subtract(const Duration(days: 7))) && 
          invoiceDate.isBefore(today.add(const Duration(days: 1)))) {
        final key = DateFormat('yyyy-MM-dd').format(invoiceDate);
        dataMap[key] = (dataMap[key] ?? 0) + invoice.totalAmount;
      }
    }

    final barGroups = last7Days.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      final total = dataMap[DateFormat('yyyy-MM-dd').format(date)] ?? 0;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: total,
            color: AppTheme.primaryColor,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
               show: true,
               toY: (dataMap.values.fold(0.0, (p, c) => c > p ? c : p)) * 1.2, // Max + 20%
               color: Colors.grey.shade100,
            ),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < last7Days.length) {
                   return Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: Text(
                       DateFormat('E').format(last7Days[value.toInt()]),
                       style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 12),
                     ),
                   );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                 if (value == 0) return const Text('');
                 return Text(
                   NumberFormat.compact().format(value),
                   style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 10),
                 );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
           show: true,
           drawVerticalLine: false,
           horizontalInterval: (dataMap.values.fold(0.0, (p, c) => c > p ? c : p)) / 5 > 0 ? (dataMap.values.fold(0.0, (p, c) => c > p ? c : p)) / 5 : 100,
           getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
             tooltipBgColor: Colors.blueGrey,
             getTooltipItem: (group, groupIndex, rod, rodIndex) {
               return BarTooltipItem(
                 '₹${NumberFormat('#,##,###').format(rod.toY)}',
                 const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
               );
             },
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyChart(List<Invoice> invoices) {
    // Last 6 months
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - 5 + i, 1);
      return d;
    });

    final dataMap = <String, double>{};
    for (var date in months) {
      dataMap[DateFormat('MMM-yyyy').format(date)] = 0;
    }

    for (var invoice in invoices) {
       if (invoice.status != InvoiceStatus.active) continue;
       final key = DateFormat('MMM-yyyy').format(invoice.createdAt);
       if (dataMap.containsKey(key)) {
         dataMap[key] = (dataMap[key] ?? 0) + invoice.totalAmount;
       }
    }

    final spots = months.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      final total = dataMap[DateFormat('MMM-yyyy').format(date)] ?? 0;
      return FlSpot(index.toDouble(), total);
    }).toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryColor.withOpacity(0.1),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < months.length) {
                   return Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: Text(
                       DateFormat('MMM').format(months[value.toInt()]),
                       style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 12),
                     ),
                   );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
               getTitlesWidget: (value, meta) {
                 if (value == 0) return const Text('');
                 return Text(
                   NumberFormat.compact().format(value),
                   style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 10),
                 );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
           show: true,
           drawVerticalLine: false,
           getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
             tooltipBgColor: Colors.blueGrey,
             getTooltipItems: (touchedSpots) {
               return touchedSpots.map((spot) {
                 return LineTooltipItem(
                   '₹${NumberFormat('#,##,###').format(spot.y)}',
                   const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                 );
               }).toList();
             },
          ),
        ),
      ),
    );
  }
}
