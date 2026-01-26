import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'customer_activity_report.dart';
import 'sales_summary_report.dart';
import 'inventory_status_report.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Reports',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                // Determine grid count based on width
                int crossAxisCount = 1;
                if (constraints.maxWidth > 1200) crossAxisCount = 4;
                else if (constraints.maxWidth > 800) crossAxisCount = 3;
                else if (constraints.maxWidth > 600) crossAxisCount = 2;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 1.5,
                  children: [
                    _buildReportCard(
                      context,
                      'Customer Activity',
                      'Detailed analysis of customer visits, spend, and purchase history.',
                      Icons.person_search_outlined,
                      Colors.blue,
                      () => _showReportDialog(context, const CustomerActivityReport()),
                    ),
                     _buildReportCard(
                      context,
                      'Sales Summary',
                      'General sales performance overview by period and category.',
                      Icons.insert_chart_outlined,
                      Colors.green,
                      () => _showReportDialog(context, const SalesSummaryReport()),
                    ),
                     _buildReportCard(
                      context,
                      'Inventory Status',
                      'Stock levels, low stock alerts, and valuation.',
                      Icons.inventory_2_outlined,
                      Colors.orange,
                      () => _showReportDialog(context, const InventoryStatusReport()),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, Widget reportWidget) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: reportWidget, // Reports already wrapped in Container for size control or will adapt
        );
      },
    );
  }

  Widget _buildReportCard(BuildContext context, String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: color.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.mutedTextColor,
                    height: 1.4,
                  ),
                  overflow: TextOverflow.fade,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'View Report',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
