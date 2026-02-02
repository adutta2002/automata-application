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
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'View performance, customer activity, and inventory status.',
              style: TextStyle(fontSize: 16, color: AppTheme.mutedTextColor),
            ),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                // Responsive Grid using MaxCrossAxisExtent
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400, // Max width for each card
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                  ),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    final reports = [
                       _buildReportModel(
                        'Customer Activity',
                        'Detailed analysis of customer visits, spend, and purchase history.',
                        Icons.person_search_outlined,
                        Colors.blue,
                        () => _showReportDialog(context, const CustomerActivityReport()),
                      ),
                       _buildReportModel(
                        'Sales Summary',
                        'General sales performance overview by period and category.',
                        Icons.insert_chart_outlined,
                        Colors.green,
                        () => _showReportDialog(context, const SalesSummaryReport()),
                      ),
                       _buildReportModel(
                        'Inventory Status',
                        'Stock levels, low stock alerts, and valuation.',
                        Icons.inventory_2_outlined,
                        Colors.orange,
                        () => _showReportDialog(context, const InventoryStatusReport()),
                      ),
                    ];
                    return _buildReportCard(context, reports[index]);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, Widget reportWidget) {
    final size = MediaQuery.of(context).size;
    final double dialogWidth = size.width > 1100 ? 1000 : size.width * 0.9;
    final double dialogHeight = size.height > 900 ? 800 : size.height * 0.9;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero, // We handle size manually
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: reportWidget,
            ),
          ),
        );
      },
    );
  }

  _ReportData _buildReportModel(String title, String desc, IconData icon, Color color, VoidCallback onTap) {
    return _ReportData(title, desc, icon, color, onTap);
  }

  Widget _buildReportCard(BuildContext context, _ReportData data) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: data.color.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon, color: data.color, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  data.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.mutedTextColor,
                    height: 1.5,
                  ),
                  overflow: TextOverflow.fade,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'View Report',
                    style: TextStyle(
                      color: data.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: data.color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ReportData(this.title, this.description, this.icon, this.color, this.onTap);
}
