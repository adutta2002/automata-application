import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import '../models/pos_models.dart';
import '../core/app_theme.dart';
import 'product_form_screen.dart';
import '../widgets/common/pagination_controls.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStockStatus = 'All'; // 'All', 'Low Stock', 'In Stock'
  RangeValues? _priceRange;
  
  int _currentPage = 1;
  static const int _itemsPerPage = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildActiveFilters(),
          _buildSearchAndFilter(),
          Expanded(child: _buildProductTable()), 
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.tableBorderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Product List',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          Row(
            children: [
              _buildFilterButton(),
              const SizedBox(width: 12),
              _buildAddProductButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
     return OutlinedButton.icon(
      onPressed: _showFilterDialog,
      icon: const Icon(Icons.filter_list, size: 18),
      label: const Text('Filter'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.mutedTextColor,
        side: BorderSide(color: AppTheme.tableBorderColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _showFilterDialog() {
    final products = context.read<POSProvider>().products;
    final categories = ['All', ...products.map((e) => e.category).toSet().toList()];
    
    // Calculate max price for range slider
    double maxPrice = 0;
    if (products.isNotEmpty) {
      maxPrice = products.map((p) => p.price).reduce((a, b) => a > b ? a : b);
    }
    if (maxPrice == 0) maxPrice = 1000; // Default if no products
    
    // Temp state
    String tempCategory = _selectedCategory;
    String tempStock = _selectedStockStatus;
    RangeValues tempPrice = _priceRange ?? RangeValues(0, maxPrice);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Products'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: categories.contains(tempCategory) ? tempCategory : 'All',
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => tempCategory = val!),
                ),
                const SizedBox(height: 16),
                const Text('Stock Status', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: tempStock,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Low Stock', child: Text('Low Stock (<10)')),
                    DropdownMenuItem(value: 'In Stock', child: Text('In Stock')),
                  ],
                  onChanged: (val) => setState(() => tempStock = val!),
                ),
                const SizedBox(height: 16),
                const Text('Price Range', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('₹${tempPrice.start.toInt()}'),
                    Expanded(
                      child: RangeSlider(
                        values: tempPrice,
                        min: 0,
                        max: maxPrice,
                        divisions: 100,
                        labels: RangeLabels(
                          '₹${tempPrice.start.toInt()}', 
                          '₹${tempPrice.end.toInt()}'
                        ),
                        onChanged: (values) => setState(() => tempPrice = values),
                      ),
                    ),
                    Text('₹${tempPrice.end.toInt()}'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  tempCategory = 'All';
                  tempStock = 'All';
                  tempPrice = RangeValues(0, maxPrice);
                });
              },
              child: const Text('Reset'),
            ),
            ElevatedButton(
              onPressed: () {
                // Apply changes to the main widget state
                this.setState(() {
                  _selectedCategory = tempCategory;
                  _selectedStockStatus = tempStock;
                  _priceRange = tempPrice;
                  _currentPage = 1; // Reset to page 1 on filter
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActiveFilters() {
    final filters = <Widget>[];

    if (_selectedCategory != 'All') {
      filters.add(_buildFilterChip(
        label: 'Category: $_selectedCategory',
        onDeleted: () => setState(() { _selectedCategory = 'All'; _currentPage = 1; }),
      ));
    }

    if (_selectedStockStatus != 'All') {
      filters.add(_buildFilterChip(
        label: 'Stock: $_selectedStockStatus',
        onDeleted: () => setState(() { _selectedStockStatus = 'All'; _currentPage = 1; }),
      ));
    }

    if (_priceRange != null) {
      // Check if range is actually filtering (not 0 to max)
      // Actually we don't easily know max here without recalculating, 
      // but showing it if set is fine. We'll simplify and just show if it was set via dialog.
      // Or we can check if it's different from default, but let's just show it.
      filters.add(_buildFilterChip(
        label: 'Price: ₹${_priceRange!.start.toInt()} - ₹${_priceRange!.end.toInt()}',
        onDeleted: () => setState(() { _priceRange = null; _currentPage = 1; }),
      ));
    }

    if (filters.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: Text(
              'Active Filters:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.mutedTextColor,
              ),
            ),
          ),
          ...filters,
          if (filters.isNotEmpty)
             TextButton(
               onPressed: () {
                 setState(() {
                   _selectedCategory = 'All';
                   _selectedStockStatus = 'All';
                   _priceRange = null;
                   _currentPage = 1;
                 });
               },
               style: TextButton.styleFrom(
                 foregroundColor: Colors.red,
                 padding: const EdgeInsets.symmetric(horizontal: 8),
                 minimumSize: Size.zero,
                 tapTargetSize: MaterialTapTargetSize.shrinkWrap,
               ),
               child: const Text('Clear All', style: TextStyle(fontSize: 12)),
             ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onDeleted}) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDeleted,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(color: AppTheme.primaryColor),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }


  Widget _buildAddProductButton() {
    return ElevatedButton.icon(
      onPressed: () => showDialog(
        context: context,
        builder: (context) => const ProductFormDialog(),
      ),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add Product'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        elevation: 0,
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (val) => setState(() {
                _searchQuery = val;
                _currentPage = 1; // Reset to page 1 on search
              }),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search, color: AppTheme.mutedTextColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _searchQuery = '';
                          _currentPage = 1;
                        }),
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.backgroundColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.tableBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.tableBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTable() {
    return Consumer<POSProvider>(
      builder: (context, provider, child) {
        // 1. Filter
        final filteredProducts = provider.products.where((p) {
          final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 p.sku.toLowerCase().contains(_searchQuery.toLowerCase());
          
          final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
          
          final matchesStock = _selectedStockStatus == 'All' || 
             (_selectedStockStatus == 'Low Stock' && p.stockQuantity < 10) ||
             (_selectedStockStatus == 'In Stock' && p.stockQuantity >= 10);
          
          bool matchesPrice = true;
          if (_priceRange != null) {
            matchesPrice = p.price >= _priceRange!.start && p.price <= _priceRange!.end;
          }

          return matchesSearch && matchesCategory && matchesStock && matchesPrice;
        }).toList();

        if (filteredProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.mutedTextColor),
                const SizedBox(height: 16),
                Text(
                  'No products found',
                  style: TextStyle(fontSize: 16, color: AppTheme.mutedTextColor),
                ),
              ],
            ),
          );
        }

        // 2. Paginate
        final startIndex = (_currentPage - 1) * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage < filteredProducts.length) 
            ? startIndex + _itemsPerPage 
            : filteredProducts.length;
            
        final paginatedProducts = filteredProducts.sublist(startIndex, endIndex);

        return Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.tableBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildTableHeader(),
              Expanded(
                child: ListView.separated(
                  itemCount: paginatedProducts.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: AppTheme.tableBorderColor,
                  ),
                  itemBuilder: (context, index) {
                    final product = paginatedProducts[index];
                    return _buildTableRow(product, index);
                  },
                ),
              ),
              PaginationControls(
                currentPage: _currentPage,
                totalItems: filteredProducts.length,
                itemsPerPage: _itemsPerPage,
                onPageChanged: (page) => setState(() => _currentPage = page),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.tableHeaderColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: Text(
              'Product',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.textColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'Code',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.textColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Category',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.textColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Price',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.textColor,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const Expanded(
            child: Text(
              'HSN',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.textColor,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Expanded(
            child: Text(
              'Stock',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.textColor,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(
            width: 100,
            child: Text(
              'Actions',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.textColor,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(Product product, int index) {
    final isLowStock = product.stockQuantity < 10;
    
    return Material(
      color: index.isEven ? AppTheme.tableRowEvenColor : AppTheme.tableRowOddColor,
      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (context) => ProductFormDialog(product: product),
        ),
        hoverColor: AppTheme.tableHoverColor,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // Product with image
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    _buildProductAvatar(product),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product.unit,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.mutedTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Code
              Expanded(
                flex: 2,
                child: Text(
                  product.sku,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.mutedTextColor,
                  ),
                ),
              ),
              // Category
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.category,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // Price
              Expanded(
                child: Text(
                  '₹${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textColor,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              // HSN
              Expanded(
                child: Text(
                  product.hsnCode ?? '-',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Stock
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLowStock ? Colors.orange.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isLowStock ? Colors.orange : Colors.green,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${product.stockQuantity.toInt()}',
                      style: TextStyle(
                        color: isLowStock ? Colors.orange.shade900 : Colors.green.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              // Actions
              SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: Colors.blue,
                      onPressed: () => showDialog(
                        context: context,
                        builder: (context) => ProductFormDialog(product: product),
                      ),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: Colors.red,
                      onPressed: () => _confirmDelete(context, product),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductAvatar(Product product) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.cyan,
    ];
    final color = colors[product.name.hashCode % colors.length];

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.shade100,
        shape: BoxShape.circle,
        border: Border.all(color: color.shade200, width: 2),
      ),
      child: Center(
        child: Text(
          product.name[0].toUpperCase(),
          style: TextStyle(
            color: color.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<POSProvider>().deleteProduct(product.id!);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Product "${product.name}" deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

}
