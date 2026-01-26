import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/pos_provider.dart';
import '../../models/pos_models.dart';
import '../../core/app_theme.dart';

class InventoryStatusReport extends StatefulWidget {
  const InventoryStatusReport({super.key});

  @override
  State<InventoryStatusReport> createState() => _InventoryStatusReportState();
}

class _InventoryStatusReportState extends State<InventoryStatusReport> {
  String _searchQuery = '';
  bool _showLowStockOnly = false;
  Map<String, dynamic> _summary = {};
  List<Product> _products = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _loadData() {
    _loadSummary();
    _performSearch();
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await context.read<POSProvider>().getInventorySummary();
      if (mounted) setState(() => _summary = summary);
    } catch (e) {
      debugPrint('Error loading inventory summary: $e');
    }
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    try {
      final products = await context.read<POSProvider>().searchInventory(
        query: _searchQuery,
        lowStockOnly: _showLowStockOnly,
      );
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching inventory: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String val) {
    _searchQuery = val;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _performSearch);
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
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildFilters(),
          const SizedBox(height: 16),
          Expanded(child: _buildInventoryTable()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Inventory Status Report',
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

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Total Items',
            (_summary['totalItems'] ?? 0).toString(),
            Icons.inventory_2,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Stock Value (Selling)',
            '₹${NumberFormat('#,##,###').format(_summary['totalValue'] ?? 0)}',
            Icons.monetization_on,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Low Stock Alerts',
            (_summary['lowStockCount'] ?? 0).toString(),
            Icons.warning,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.mutedTextColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: _onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Search products...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
          ),
        ),
        const SizedBox(width: 16),
        FilterChip(
          label: const Text('Low Stock Only'),
          selected: _showLowStockOnly,
          onSelected: (val) {
            setState(() => _showLowStockOnly = val);
            _performSearch();
          },
          selectedColor: Colors.red.withOpacity(0.2),
          checkmarkColor: Colors.red,
          labelStyle: TextStyle(color: _showLowStockOnly ? Colors.red : null),
        ),
      ],
    );
  }

  Widget _buildInventoryTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.separated(
              itemCount: _products.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final product = _products[index];
                return _buildTableRow(product);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Product',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(
              'Stock',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'Price',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              'Value',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(Product product) {
    bool isLowStock = product.stockQuantity < 10;

    return Container(
      color: isLowStock ? Colors.red.withOpacity(0.05) : null,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (isLowStock) ...[
                  const Icon(Icons.warning, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: Text(product.sku)),
          Expanded(
            child: Text(
              '${product.stockQuantity.toInt()}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isLowStock ? Colors.red : null,
              ),
            ),
          ),
          Expanded(
            child: Text('₹${product.price}', textAlign: TextAlign.right),
          ),
          Expanded(
            child: Text(
              '₹${NumberFormat('#,##,###').format(product.price * product.stockQuantity)}',
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
