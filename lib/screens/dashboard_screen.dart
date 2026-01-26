import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/pos_provider.dart';
import '../core/app_theme.dart';
import '../models/pos_models.dart';
import '../core/responsive_layout.dart';
import '../widgets/dashboard/sales_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // Refresh global initial data (branches, etc)
    await context.read<POSProvider>().loadInitialData();
    // Fetch dashboard specific stats
    try {
      final stats = await context.read<POSProvider>().getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch(e) {
      debugPrint('Error loading dashboard stats: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200), // Increased max width
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildStatsGrid(),
                const SizedBox(height: 24),
                
                // Adaptive layout for Chart & Recent Invoices
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Using ResponsiveLayout breakdown or custom check here
                    if (constraints.maxWidth >= 900) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: const SalesChart()),
                          const SizedBox(width: 24),
                          Expanded(flex: 1, child: _buildRecentInvoices()),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          const SalesChart(),
                          const SizedBox(height: 24),
                          _buildRecentInvoices(),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
          style: TextStyle(
            color: AppTheme.mutedTextColor,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: ResponsiveLayout.getGridCrossAxisCount(context),
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          // Relaxed aspect ratio slightly to prevent overflow
          childAspectRatio: ResponsiveLayout.isMobile(context) ? 2.2 : 1.8, 
          children: [
            _buildStatCard(
              'Total Revenue',
              '₹${NumberFormat('#,##,###.##').format(_stats['totalRevenue'] ?? 0)}',
              Icons.payments_outlined,
              Colors.blue,
            ),
            _buildStatCard(
              'Total Invoices',
              (_stats['totalInvoices'] ?? 0).toString(),
              Icons.receipt_outlined,
              Colors.orange,
            ),
            _buildStatCard(
              'Active Memberships',
              (_stats['activeMemberships'] ?? 0).toString(),
              Icons.card_membership_outlined,
              Colors.purple,
            ),
            _buildStatCard(
              'Low Stock Alerts',
              (_stats['lowStockItems'] ?? 0).toString(),
              Icons.warning_amber_outlined,
              Colors.red,
            ),
          ],
        );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12), // Further reduced padding to prevent overflow
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20), // Slightly smaller icon
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20, // Reduced font size
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.mutedTextColor,
                    fontSize: 12, // Reduced subtitle
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentInvoices() {
    final recentInvoicesRaw = _stats['recentInvoices'];
    final recentInvoices = (recentInvoicesRaw as List?)?.cast<Invoice>() ?? <Invoice>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Make it wrap content to align nicely
          children: [
            const Text(
              'Recent Invoices',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (recentInvoices.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text('No invoices found'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentInvoices.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final invoice = recentInvoices[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: _getInvoiceTypeColor(invoice.type).withOpacity(0.1),
                      child: Icon(
                        _getInvoiceTypeIcon(invoice.type),
                        color: _getInvoiceTypeColor(invoice.type),
                        size: 18,
                      ),
                    ),
                    title: Text(invoice.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(DateFormat('dd MMM').format(invoice.createdAt)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${invoice.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                         Text(
                          invoice.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            color: invoice.status == InvoiceStatus.active ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }


  IconData _getInvoiceTypeIcon(InvoiceType type) {
    switch (type) {
      case InvoiceType.service: return Icons.build_outlined;
      case InvoiceType.product: return Icons.shopping_bag_outlined;
      case InvoiceType.advance: return Icons.payments_outlined;
      case InvoiceType.membership: return Icons.card_membership_outlined;
    }
  }

  Color _getInvoiceTypeColor(InvoiceType type) {
    switch (type) {
      case InvoiceType.service: return Colors.blue;
      case InvoiceType.product: return Colors.green;
      case InvoiceType.advance: return Colors.orange;
      case InvoiceType.membership: return Colors.purple;
    }
  }
}
