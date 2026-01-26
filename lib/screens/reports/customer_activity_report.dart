import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/pos_provider.dart';
import '../../models/pos_models.dart';
import '../../core/app_theme.dart';
import '../invoice_details_screen.dart';

class CustomerActivityReport extends StatefulWidget {
  const CustomerActivityReport({super.key});

  @override
  State<CustomerActivityReport> createState() => _CustomerActivityReportState();
}

class _CustomerActivityReportState extends State<CustomerActivityReport> {
  Customer? _selectedCustomer;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  List<Invoice> _reportData = [];
  bool _isLoading = false;

  Future<void> _loadData() async {
    if (_selectedCustomer == null) {
        setState(() => _reportData = []);
        return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await context.read<POSProvider>().getCustomerActivity(_selectedCustomer!.id!, _dateFrom, _dateTo);
      if (mounted) {
        setState(() {
          _reportData = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading customer activity: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 900,
      height: 700,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Customer Activity Report',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilters(),
                        const SizedBox(height: 24),
                        if (_selectedCustomer != null) ...[
                          _buildSummaryCards(),
                          const SizedBox(height: 24),
                          _buildAnalysisSection(),
                          const SizedBox(height: 24),
                          _buildTransactionHistory(),
                        ] else
                          _buildEmptyState(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.person_search, size: 80, color: AppTheme.mutedTextColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Select a customer to view report',
            style: TextStyle(fontSize: 18, color: AppTheme.mutedTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Report Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Consumer<POSProvider>(
                    builder: (context, provider, child) {
                      return Autocomplete<Customer>(
                        displayStringForOption: (Customer c) => '${c.name} (${c.phone})',
                        optionsBuilder: (TextEditingValue textEditingValue) {
                           if (textEditingValue.text.isEmpty) {
                             return const Iterable<Customer>.empty();
                           }
                           return provider.customers.where((Customer c) {
                             return c.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                                    c.phone.contains(textEditingValue.text);
                           });
                        },
                          onSelected: (Customer c) {
                            setState(() {
                              _selectedCustomer = c;
                            });
                            _loadData();
                          },
                        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onEditingComplete: onEditingComplete,
                            decoration: const InputDecoration(
                              labelText: 'Search Customer',
                              hintText: 'Name or Phone',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: _dateFrom != null && _dateTo != null ? DateTimeRange(start: _dateFrom!, end: _dateTo!) : null,
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
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date Range',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.date_range),
                      ),
                      child: Text(
                        _dateFrom != null && _dateTo != null
                            ? '${DateFormat('MMM dd').format(_dateFrom!)} - ${DateFormat('MMM dd').format(_dateTo!)}'
                            : 'All Time',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
                if (_selectedCustomer != null) ...[
                  const SizedBox(width: 16),
                   OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedCustomer = null; 
                        _dateFrom = null;
                        _dateTo = null;
                        _reportData = [];
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    ),
                   ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Replaced by _reportData
  // List<Invoice> _getFilteredInvoices() { ... }

  Widget _buildSummaryCards() {
    final invoices = _reportData;
    final totalVisits = invoices.length;
    final totalSpend = invoices.fold(0.0, (sum, i) => sum + i.totalAmount);
    final avgBasket = totalVisits > 0 ? totalSpend / totalVisits : 0.0;
    
    // Most purchased category
    // This requires iterating line items, which we don't store fully expanded in memory easily without deep inspection.
    // Let's approximate by Invoice Type for now.
    
    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Visits', totalVisits.toString(), Icons.emoji_people, Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Total Spend', '₹${NumberFormat('#,##,###').format(totalSpend)}', Icons.payments, Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Avg. Basket', '₹${NumberFormat('#,##,###').format(avgBasket)}', Icons.shopping_basket, Colors.orange)),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
                Text(title, style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSection() {
    final invoices = _reportData;
    if (invoices.isEmpty) return const SizedBox.shrink();

    // Pie Chart Data: Revenue by Type
    double serviceRevenue = 0;
    double productRevenue = 0;
    double otherRevenue = 0;

    for (var i in invoices) {
      if (i.type == InvoiceType.service) serviceRevenue += i.totalAmount;
      else if (i.type == InvoiceType.product) productRevenue += i.totalAmount;
      else otherRevenue += i.totalAmount;
    }

    final total = serviceRevenue + productRevenue + otherRevenue;

    final sections = [
      if (serviceRevenue > 0)
        PieChartSectionData(
          color: Colors.blue, value: serviceRevenue, title: '${(serviceRevenue/total*100).toInt()}%', radius: 50,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      if (productRevenue > 0)
        PieChartSectionData(
          color: Colors.green, value: productRevenue, title: '${(productRevenue/total*100).toInt()}%', radius: 50,
           titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      if (otherRevenue > 0)
        PieChartSectionData(
          color: Colors.orange, value: otherRevenue, title: '${(otherRevenue/total*100).toInt()}%', radius: 50,
           titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
    ];

    return Card(
       child: Padding(
         padding: const EdgeInsets.all(24),
         child: Row(
           children: [
             Expanded(
               flex: 2,
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text('Purchase Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   const Text('Revenue breakdown by invoice type.', style: TextStyle(color: Colors.grey)),
                   const SizedBox(height: 24),
                   _buildLegendItem(Colors.blue, 'Services', serviceRevenue),
                   const SizedBox(height: 8),
                   _buildLegendItem(Colors.green, 'Products', productRevenue),
                   const SizedBox(height: 8),
                   _buildLegendItem(Colors.orange, 'Others (Membership/Advance)', otherRevenue),
                 ],
               ),
             ),
             Expanded(
               flex: 3,
               child: SizedBox(
                 height: 200,
                 child: PieChart(
                   PieChartData(
                     sections: sections,
                     centerSpaceRadius: 40,
                     sectionsSpace: 2,
                   ),
                 ),
               ),
             ),
           ],
         ),
       ),
    );
  }

  Widget _buildLegendItem(Color color, String label, double value) {
     return Row(
       children: [
         Container(width: 12, height: 12, color: color),
         const SizedBox(width: 8),
         Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
         Text('₹${NumberFormat('#,##,###').format(value)}', style: const TextStyle(fontWeight: FontWeight.bold)),
       ],
     );
  }

  Widget _buildTransactionHistory() {
     final invoices = _reportData.toList()
        ..sort((a,b) => b.createdAt.compareTo(a.createdAt));

     return Card(
       child: Padding(
         padding: const EdgeInsets.all(24),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 16),
             ListView.separated(
               shrinkWrap: true,
               physics: const NeverScrollableScrollPhysics(),
               itemCount: invoices.length,
               separatorBuilder: (_, __) => const Divider(),
               itemBuilder: (context, index) {
                 final invoice = invoices[index];
                 return ListTile(
                   contentPadding: EdgeInsets.zero,
                   leading: Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(
                       color: Colors.grey.shade100,
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Icon(Icons.receipt_long, color: Colors.grey.shade700),
                   ),
                   title: Text(invoice.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                   subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(invoice.createdAt)),
                   trailing: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                        Text(
                         '₹${invoice.totalAmount.toStringAsFixed(2)}',
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                       ),
                       const SizedBox(width: 16),
                       const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                     ],
                   ),
                   onTap: () => Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => InvoiceDetailsScreen(invoice: invoice)),
                   ),
                 );
               },
             ),
           ],
         ),
       ),
     );
  }
}
