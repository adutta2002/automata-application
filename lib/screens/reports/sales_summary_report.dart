import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/pos_provider.dart';
import '../../models/pos_models.dart';
import '../../core/app_theme.dart';

class SalesSummaryReport extends StatefulWidget {
  const SalesSummaryReport({super.key});

  @override
  State<SalesSummaryReport> createState() => _SalesSummaryReportState();
}

class _SalesSummaryReportState extends State<SalesSummaryReport> {
  DateTime? _dateFrom;
  DateTime? _dateTo;

  // Initialize with current month
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateFrom = DateTime(now.year, now.month, 1);
    _dateTo = now;
  }

  @override
  Widget build(BuildContext context) {
    // In a dialog, we might want a constrained size or just let it fit content
    return Container(
      width: 900, // Fixed width for the report dialog
      height: 700,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildFilters(),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   _buildSummaryMetrics(),
                   const SizedBox(height: 24),
                   _buildSalesTrendChart(),
                   const SizedBox(height: 24),
                   _buildDailyBreakdownTable(),
                 ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Sales Summary Report',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          tooltip: 'Close',
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
            const SizedBox(width: 12),
            Text(
              'Period: ${DateFormat('dd MMM yyyy').format(_dateFrom!)} - ${DateFormat('dd MMM yyyy').format(_dateTo!)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: DateTimeRange(start: _dateFrom!, end: _dateTo!),
                  builder: (context, child) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
                        child: child,
                      ),
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _dateFrom = picked.start;
                    _dateTo = picked.end;
                  });
                }
              },
              icon: const Icon(Icons.date_range, size: 18),
              label: const Text('Change Period'),
            ),
          ],
        ),
      ),
    );
  }

  List<Invoice> _getFilteredInvoices() {
    final provider = context.read<POSProvider>();
    return provider.invoices.where((i) {
      if (i.status != InvoiceStatus.active) return false;
      return i.createdAt.isAfter(_dateFrom!.subtract(const Duration(seconds: 1))) && 
             i.createdAt.isBefore(_dateTo!.add(const Duration(days: 1)));
    }).toList();
  }

  Widget _buildSummaryMetrics() {
    final invoices = _getFilteredInvoices();
    
    double totalNetSales = 0; // Total Amount
    double totalTax = 0;
    double totalDiscount = 0;
    
    for (var i in invoices) {
      totalNetSales += i.totalAmount;
      totalTax += i.taxAmount;
      totalDiscount += i.discountAmount;
    }
    
    // Derived Gross (Total + Discount - Tax is one way, or SubTotal + Discount)
    // Let's stick to visible metrics
    
    return Row(
      children: [
        Expanded(child: _buildMetricCard('Total Revenue', totalNetSales, Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Tax Collected', totalTax, Colors.red)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Discounts Given', totalDiscount, Colors.orange)),
      ],
    );
  }

  Widget _buildMetricCard(String title, double value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 13)),
            const SizedBox(height: 8),
            Text(
              '₹${NumberFormat('#,##,###.##').format(value)}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesTrendChart() {
    final invoices = _getFilteredInvoices();
    if (invoices.isEmpty) return const SizedBox.shrink();

    // Group by Date for the period
    final Map<int, double> dailyTotals = {};
    
    // Initialize all days in range with 0? 
    // If range is large, that's a lot of points. Let's just plot actual data points for now or sparse.
    // For a smoother look on a "Sales Trend", line chart is good.
    
    // Sort invoices
    final sortedInvoices = List<Invoice>.from(invoices)
      ..sort((a,b) => a.createdAt.compareTo(b.createdAt));
      
    for (var i in sortedInvoices) {
      // Normalize to day (remove time) for grouping
      final dateKey = DateTime(i.createdAt.year, i.createdAt.month, i.createdAt.day).millisecondsSinceEpoch;
      dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + i.totalAmount;
    }
    
    final sortedKeys = dailyTotals.keys.toList()..sort();
    
    // If we have very few points, maybe Bar is better? Sticking to Line per plan.
    final spots = sortedKeys.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), dailyTotals[entry.value]!);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sales Trend (Daily)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppTheme.primaryColor,
                      barWidth: 2,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: AppTheme.primaryColor.withOpacity(0.1)),
                    ),
                  ],
                  titlesData: FlTitlesData(
                     bottomTitles: AxisTitles(
                       sideTitles: SideTitles(
                         showTitles: true,
                         interval: (spots.length / 5).ceil().toDouble(), // Show roughly 5 labels
                         getTitlesWidget: (value, meta) {
                           final index = value.toInt();
                           if (index >= 0 && index < sortedKeys.length) {
                             final date = DateTime.fromMillisecondsSinceEpoch(sortedKeys[index]);
                             return Padding(
                               padding: const EdgeInsets.only(top: 8.0),
                               child: Text(DateFormat('dd MMM').format(date), style: const TextStyle(fontSize: 10)),
                             );
                           }
                           return const Text('');
                         },
                       ),
                     ),
                     leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                     topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                     rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                   lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                       tooltipBgColor: Colors.blueGrey, // Fix for v0.65.0
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyBreakdownTable() {
     final invoices = _getFilteredInvoices();
     
     // Group by Date for table
    final Map<DateTime, List<Invoice>> grouped = {};
    for (var i in invoices) {
      final date = DateTime(i.createdAt.year, i.createdAt.month, i.createdAt.day);
      if (!grouped.containsKey(date)) grouped[date] = [];
      grouped[date]!.add(i);
    }
    
    final sortedDates = grouped.keys.toList()..sort((a,b) => b.compareTo(a)); // Descending

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Invoices', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text('Revenue', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedDates.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final daysInvoices = grouped[date]!;
              final dailyRevenue = daysInvoices.fold(0.0, (sum, i) => sum + i.totalAmount);
              
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(DateFormat('dd MMM yyyy').format(date))),
                    Expanded(child: Text(daysInvoices.length.toString(), textAlign: TextAlign.center)),
                    Expanded(child: Text('₹${NumberFormat('#,##,###.##').format(dailyRevenue)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
