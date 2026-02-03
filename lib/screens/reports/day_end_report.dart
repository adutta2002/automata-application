
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../providers/pos_provider.dart';
import '../../models/pos_models.dart';

class DayEndReport extends StatelessWidget {
  const DayEndReport({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Day End Report (Daily Closing)'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<POSProvider>(
        builder: (context, provider, child) {
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

          // Filter invoices for today (Completed & Partial)
          // We exclude Cancelled for revenue, but might list them separately.
          final todayInvoices = provider.invoices.where((i) {
            return i.createdAt.isAfter(todayStart) && 
                   i.createdAt.isBefore(todayEnd) &&
                   i.status != InvoiceStatus.cancelled;
          }).toList();

          final cancelledInvoices = provider.invoices.where((i) {
            return i.createdAt.isAfter(todayStart) && 
                   i.createdAt.isBefore(todayEnd) &&
                   i.status == InvoiceStatus.cancelled;
          }).toList();

          // --- Logic Calculation Start ---
          
          double totalSales = 0;
          Map<String, double> paymentModes = {};
          
          // Category Breakdown
          double serviceSales = 0; int serviceCount = 0;
          double productSales = 0; int productCount = 0;
          double membershipSales = 0; int membershipCount = 0;

          // Bill Type Breakdown
          double regularSales = 0; int regularCount = 0;
          double advanceSales = 0; int advanceCount = 0;

          // Item Breakdown Split
          Map<String, Map<String, dynamic>> serviceStats = {};
          Map<String, Map<String, dynamic>> productStats = {};

          for (var inv in todayInvoices) {
            totalSales += inv.totalAmount;

            // Category Split
            if (inv.type == InvoiceType.service) { serviceSales += inv.totalAmount; serviceCount++; }
            else if (inv.type == InvoiceType.product) { productSales += inv.totalAmount; productCount++; }
            else if (inv.type == InvoiceType.membership) { membershipSales += inv.totalAmount; membershipCount++; }

            // Bill Type Split
            if (inv.billType == 'ADVANCE') { advanceSales += inv.totalAmount; advanceCount++; }
            else { regularSales += inv.totalAmount; regularCount++; }

            // Payment Aggregation
            for (var payment in inv.payments) {
               final amount = payment.amount;
               final mode = payment.mode.toUpperCase();
               paymentModes[mode] = (paymentModes[mode] ?? 0) + amount;
            }

            // Item Aggregation Split
            for (var item in inv.items) {
               Map<String, Map<String, dynamic>> targetMap;
               // Check type. If it's explicitly PRODUCT, goes to product stats.
               // Defaults to Service if SERVICE or null/other (safe fallback for salon context)
               if (item.itemType == 'PRODUCT') {
                 targetMap = productStats;
               } else {
                 targetMap = serviceStats;
               }
               
               if (!targetMap.containsKey(item.name)) {
                 targetMap[item.name] = {'qty': 0.0, 'amount': 0.0};
               }
               targetMap[item.name]!['qty'] += item.quantity;
               targetMap[item.name]!['amount'] += item.total;
            }
          }
          
          double totalCollected = paymentModes.values.fold(0, (sum, val) => sum + val);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date: ${DateFormat('dd MMM yyyy').format(now)}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                
                // 1. Key Metrics Row
                Row(
                  children: [
                    _buildMetricCard('Total Sales', '₹${totalSales.toStringAsFixed(2)}', Colors.blue),
                    const SizedBox(width: 16),
                    _buildMetricCard('Total Collected', '₹${totalCollected.toStringAsFixed(2)}', Colors.green),
                    const SizedBox(width: 16),
                    _buildMetricCard('Invoices', '${todayInvoices.length}', Colors.orange),
                    const SizedBox(width: 16),
                     _buildMetricCard('Cancelled', '${cancelledInvoices.length}', Colors.red),
                  ],
                ),
                const SizedBox(height: 32),

                // 2. Category & Bill Type Split
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Breakdown
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sales by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          _buildBreakdownRow('Services', serviceCount, serviceSales, Icons.content_cut),
                          _buildBreakdownRow('Products', productCount, productSales, Icons.inventory_2_outlined),
                          _buildBreakdownRow('Memberships', membershipCount, membershipSales, Icons.card_membership),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Bill Type & Payment Breakdown
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           const Text('Bill Type Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                           const SizedBox(height: 16),
                           Container(
                             padding: const EdgeInsets.all(16),
                             decoration: BoxDecoration(
                               color: Colors.grey.shade50,
                               borderRadius: BorderRadius.circular(12),
                               border: Border.all(color: Colors.grey.shade200),
                             ),
                             child: Column(
                               children: [
                                 _buildCompactRow('Regular Bills', regularCount, regularSales),
                                 const Divider(),
                                 _buildCompactRow('Advance Receipts', advanceCount, advanceSales),
                               ],
                             ),
                           ),
                           const SizedBox(height: 24),
                           const Text('Payment Modes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                           const SizedBox(height: 16),
                           Wrap(
                             spacing: 12,
                             runSpacing: 12,
                             children: paymentModes.entries.map((e) => Chip(
                               avatar: Icon(_getIconForMode(e.key), size: 16, color: Colors.white),
                               label: Text('${e.key}: ₹${e.value.toStringAsFixed(0)}'),
                               backgroundColor: Colors.blueGrey.shade700,
                               labelStyle: const TextStyle(color: Colors.white),
                             )).toList(),
                           )
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),

                // 3. Services Performance
                if (serviceStats.isNotEmpty) ...[
                  const Text('Services Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildItemTable(serviceStats),
                  const SizedBox(height: 32),
                ],

                // 4. Product Sales
                if (productStats.isNotEmpty) ...[
                  const Text('Product Sales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildItemTable(productStats),
                  const SizedBox(height: 32),
                ],

                const SizedBox(height: 32),
                
                // AI Insights Stub
                Container(
                   width: double.infinity,
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     gradient: LinearGradient(colors: [Colors.purple.shade50, Colors.blue.shade50]),
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: Colors.purple.shade100),
                   ),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         children: [
                           const Icon(Icons.auto_awesome, color: Colors.purple),
                           const SizedBox(width: 8),
                           const Text('Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple)),
                         ],
                       ),
                       _buildDynamicInsights(todayInvoices, paymentModes, totalSales),
                     ],
                   ),
                ),

              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDynamicInsights(List<Invoice> invoices, Map<String, double> paymentModes, double totalSales) {
    if (invoices.isEmpty) {
      return Text("No sales recorded today to analyze.", style: TextStyle(color: Colors.purple.shade900));
    }

    List<String> insights = [];

    // 1. Analyze Product vs Service Mix
    double productRev = 0;
    double serviceRev = 0;
    for (var inv in invoices) {
      if (inv.type == InvoiceType.product) productRev += inv.totalAmount;
      if (inv.type == InvoiceType.service) serviceRev += inv.totalAmount;
    }

    if (serviceRev > productRev && productRev > 0) {
      insights.add("• Service revenue is leading (Runs ${(serviceRev / totalSales * 100).toInt()}% of total). Consider bundling products with services to boost retail sales.");
    } else if (productRev > serviceRev) {
      insights.add("• High retail demand today! Products contributed ${(productRev / totalSales * 100).toInt()}% of revenue.");
    }

    // 2. Analyze Average Ticket Size
    final avgTicket = totalSales / invoices.length;
    if (avgTicket > 2000) {
      insights.add("• High value transactions detected! Avg ticket size is ₹${avgTicket.toStringAsFixed(0)}.");
    }

    // 3. Payment Preference
    String topMode = '';
    double topVal = -1;
    paymentModes.forEach((key, val) {
       if (val > topVal) {
         topVal = val;
         topMode = key;
       }
    });
    
    if (topMode.isNotEmpty) {
      if (topMode.contains('CASH')) {
         insights.add("• Cash Heavy Day: Ensure you have enough change in the drawer for tomorrow.");
      } else if (topMode.contains('UPI')) {
         insights.add("• Digital Payments Dominating: ${((topVal/totalSales)*100).toInt()}% of sales via UPI.");
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: insights.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(s, style: TextStyle(color: Colors.purple.shade900, height: 1.4)),
      )).toList(),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
             const SizedBox(height: 8),
             Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTable(Map<String, Map<String, dynamic>> stats) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
        columns: const [
           DataColumn(label: Text('Item Name')),
           DataColumn(label: Text('Qty'), numeric: true),
           DataColumn(label: Text('Amount'), numeric: true),
        ],
        rows: stats.entries.map((e) {
          final name = e.key;
          final data = e.value;
          return DataRow(cells: [
            DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
            DataCell(Text(data['qty'].toString())),
            DataCell(Text('₹${data['amount'].toStringAsFixed(2)}')),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildBreakdownRow(String title, int count, double amount, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: amount > 0 ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: amount > 0 ? Colors.blue : Colors.grey, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('$count Invoices', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          const Spacer(),
          Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildCompactRow(String title, int count, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$title ($count)', style: const TextStyle(fontSize: 15)),
          Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  IconData _getIconForMode(String mode) {
    if (mode.contains('CASH')) return Icons.payments_outlined;
    if (mode.contains('CARD')) return Icons.credit_card_outlined;
    if (mode.contains('UPI') || mode.contains('ONLINE')) return Icons.qr_code_2_outlined;
    return Icons.attach_money;
  }
}
