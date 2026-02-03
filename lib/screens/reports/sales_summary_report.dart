import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
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

  Map<String, double> _totals = {};
  List<Invoice> _reportData = [];
  bool _isLoading = false;

  // Initialize with current month
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateFrom = DateTime(now.year, now.month, 1);
    _dateTo = now;
    // creating a microtask to allow context usage
    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final result = await context.read<POSProvider>().getSalesSummary(_dateFrom!, _dateTo!);
      if (mounted) {
        setState(() {
          _reportData = result['invoices'] as List<Invoice>;
          final totalsMap = result['totals'] as Map<String, dynamic>?;
          if (totalsMap != null) {
             _totals = {
               'revenue': (totalsMap['revenue'] ?? 0.0) as double,
               'tax': (totalsMap['tax'] ?? 0.0) as double,
               'discount': (totalsMap['discount'] ?? 0.0) as double,
             };
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading report: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportToCsv() async {
    try {
      final invoices = _reportData;
      if (invoices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export')));
        return;
      }

      // 1. Prepare Data
      List<List<dynamic>> rows = [];
      
      // Header
      rows.add([
        'Date',
        'Total Invoices',
        'Service Sales',
        'Product Sales',
        'Membership Sales',
        'Gross Revenue',
        'Discount', // Added Discount
        'Tax (GST)',
        'Net Sales (Profit)'
      ]);

      // Group by Date
      final Map<DateTime, List<Invoice>> grouped = {};
      for (var i in invoices) {
        final date = DateTime(i.createdAt.year, i.createdAt.month, i.createdAt.day);
        if (!grouped.containsKey(date)) grouped[date] = [];
        grouped[date]!.add(i);
      }
      final sortedDates = grouped.keys.toList()..sort((a,b) => b.compareTo(a));

      for (var date in sortedDates) {
        final daysInvoices = grouped[date]!;
        
        double serviceSales = 0;
        double productSales = 0;
        double membershipSales = 0;
        double totalRevenue = 0;
        double totalTax = 0;
        double totalDiscount = 0; // Track Discount

        for (var inv in daysInvoices) {
          if (inv.status == InvoiceStatus.cancelled || inv.status == InvoiceStatus.hold) continue;
          
          totalRevenue += inv.totalAmount;
          totalTax += inv.taxAmount;
          totalDiscount += inv.discountAmount; // Sum discount

          if (inv.type == InvoiceType.service) serviceSales += inv.totalAmount;
          else if (inv.type == InvoiceType.product) productSales += inv.totalAmount;
          else if (inv.type == InvoiceType.membership) membershipSales += inv.totalAmount;
          else {
             productSales += inv.totalAmount;
          }
        }
        
        final netSales = totalRevenue - totalTax;

        rows.add([
          DateFormat('yyyy-MM-dd').format(date),
          daysInvoices.length,
          serviceSales.toStringAsFixed(2),
          productSales.toStringAsFixed(2),
          membershipSales.toStringAsFixed(2),
          totalRevenue.toStringAsFixed(2),
          totalDiscount.toStringAsFixed(2), // Add Discount
          totalTax.toStringAsFixed(2),
          netSales.toStringAsFixed(2),
        ]);
      }

      // Convert to CSV
      String csvData = const ListToCsvConverter().convert(rows);

      // Save File
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Report CSV',
        fileName: 'sales_summary_${DateFormat('yyyyMMdd').format(_dateFrom!)}-${DateFormat('yyyyMMdd').format(_dateTo!)}.csv',
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(csvData);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report saved to $outputFile')));
        }
      }
    } catch (e) {
      debugPrint('Export Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // In a dialog, the parent handles size constraints
    return Container(
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.all(24),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildFilters(),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
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
        Row(
          children: [
             OutlinedButton.icon(
              onPressed: _exportToCsv,
              icon: const Icon(Icons.download),
              label: const Text('Export CSV'),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              tooltip: 'Close',
            ),
          ],
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
                    _dateTo = picked.end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
                  });
                  _loadData();
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

  // Replaced by _reportData
  // List<Invoice> _getFilteredInvoices() { ... }

  Widget _buildSummaryMetrics() {
    return Row(
      children: [
        Expanded(child: _buildMetricCard('Total Revenue', _totals['revenue'] ?? 0, Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Tax Collected', _totals['tax'] ?? 0, Colors.red)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Discounts Given', _totals['discount'] ?? 0, Colors.orange)),
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
    final invoices = _reportData;
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
     final invoices = _reportData;
     
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
                Expanded(child: Text('Service', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                Expanded(child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                Expanded(child: Text('Member', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)), // Added Membership
                Expanded(child: Text('GST', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                Expanded(child: Text('Disc.', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)), // Added Discount
                Expanded(child: Text('Net', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
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
              
              double serviceSales = 0;
              double productSales = 0;
              double membershipSales = 0; // Track Membership
              double totalRevenue = 0;
              double totalTax = 0;
              double totalDiscount = 0; // Track Discount
              
              for (var inv in daysInvoices) {
                if (inv.status == InvoiceStatus.cancelled || inv.status == InvoiceStatus.hold) continue;
                
                totalRevenue += inv.totalAmount;
                totalTax += inv.taxAmount;
                totalDiscount += inv.discountAmount; // Sum discounts
                
                // Classify based on invoice type
                if (inv.type == InvoiceType.service) {
                  serviceSales += inv.totalAmount;
                } else if (inv.type == InvoiceType.product) {
                  productSales += inv.totalAmount;
                } else if (inv.type == InvoiceType.membership) {
                   membershipSales += inv.totalAmount;
                } else {
                   // Fallback for others
                   productSales += inv.totalAmount;
                }
              }
              
              // Net Sales = Revenue - Tax
              final netSales = totalRevenue - totalTax;
              
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('dd MMM yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text('${daysInvoices.length} invoices', style: TextStyle(fontSize: 11, color: AppTheme.mutedTextColor)),
                      ],
                    )),
                    Expanded(child: Text('₹${NumberFormat('#,##,##0.00').format(serviceSales)}', textAlign: TextAlign.right, style: TextStyle(color: AppTheme.mutedTextColor))),
                    Expanded(child: Text('₹${NumberFormat('#,##,##0.00').format(productSales)}', textAlign: TextAlign.right, style: TextStyle(color: AppTheme.mutedTextColor))),
                    Expanded(child: Text('₹${NumberFormat('#,##,##0.00').format(membershipSales)}', textAlign: TextAlign.right, style: TextStyle(color: AppTheme.mutedTextColor))),
                    Expanded(child: Text('₹${NumberFormat('#,##,##0.00').format(totalTax)}', textAlign: TextAlign.right, style: TextStyle(color: Colors.red.shade400))),
                    Expanded(child: Text('₹${NumberFormat('#,##,##0.00').format(totalDiscount)}', textAlign: TextAlign.right, style: TextStyle(color: Colors.orange.shade400))), // Discount
                    Expanded(child: Text('₹${NumberFormat('#,##,##0.00').format(netSales)}', textAlign: TextAlign.right, style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('₹${NumberFormat('#,##,##0.00').format(totalRevenue)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
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
