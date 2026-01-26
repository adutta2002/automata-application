import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/pos_provider.dart';
import '../models/pos_models.dart';
import '../core/app_theme.dart';
import 'hsn_form_screen.dart';
import '../widgets/common/pagination_controls.dart';

class HsnManagementScreen extends StatefulWidget {
  const HsnManagementScreen({super.key});

  @override
  State<HsnManagementScreen> createState() => _HsnManagementScreenState();
}

class _HsnManagementScreenState extends State<HsnManagementScreen> {
  String _searchQuery = '';
  // Filters
  String _selectedType = 'All';
  double? _filterGstRate;
  
  int _currentPage = 1;
  static const int _itemsPerPage = 4;
  
  final _dateFormatter = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildActiveFilters(),
          _buildSearchBar(),
          Expanded(child: _buildHsnTable()),
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
            'HSN/SAC Management',
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
              ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const HsnFormDialog(),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add HSN/SAC'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 0,
                ),
              ),
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
    final gstRates = [0.0, 5.0, 12.0, 18.0, 28.0];

    // Temp state
    String tempType = _selectedType;
    double? tempGst = _filterGstRate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter HSN/SAC'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: tempType,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All')),
                  DropdownMenuItem(value: 'GOODS', child: Text('Goods (HSN)')),
                  DropdownMenuItem(value: 'SERVICES', child: Text('Services (SAC)')),
                ],
                onChanged: (val) {
                  setState(() => tempType = val!);
                },
              ),
              const SizedBox(height: 16),
              const Text('GST Rate', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<double?>(
                value: tempGst,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                   ...gstRates.map((r) => DropdownMenuItem(value: r, child: Text('${r.toInt()}%'))),
                ],
                onChanged: (val) {
                  setState(() => tempGst = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  tempType = 'All';
                  tempGst = null;
                });
              },
              child: const Text('Reset'),
            ),
            ElevatedButton(
              onPressed: () {
                this.setState(() {
                  _selectedType = tempType;
                  _filterGstRate = tempGst;
                  _currentPage = 1; 
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

    if (_selectedType != 'All') {
      filters.add(_buildFilterChip(
        label: 'Type: ${_selectedType == 'GOODS' ? 'Goods' : 'Services'}',
        onDeleted: () => setState(() { _selectedType = 'All'; _currentPage = 1; }),
      ));
    }

    if (_filterGstRate != null) {
      filters.add(_buildFilterChip(
        label: 'GST: ${_filterGstRate!.toInt()}%',
        onDeleted: () => setState(() { _filterGstRate = null; _currentPage = 1; }),
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
                   _selectedType = 'All';
                   _filterGstRate = null;
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


  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: TextField(
        onChanged: (val) => setState(() {
          _searchQuery = val;
          _currentPage = 1;
        }),
        decoration: InputDecoration(
          hintText: 'Search HSN codes or description...',
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
    );
  }

  Widget _buildHsnTable() {
    return Consumer<POSProvider>(
      builder: (context, provider, child) {
        // 1. Filter
        final filteredList = provider.hsnCodes.where((hsn) {
          final q = _searchQuery.toLowerCase();
          final matchesSearch = hsn.code.toLowerCase().contains(q) ||
                 hsn.description.toLowerCase().contains(q);
          
          final matchesType = _selectedType == 'All' || hsn.type == _selectedType;
          final matchesGst = _filterGstRate == null || hsn.gstRate == _filterGstRate;

          return matchesSearch && matchesType && matchesGst;
        }).toList();

        if (filteredList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner, size: 64, color: AppTheme.mutedTextColor),
                const SizedBox(height: 16),
                Text(
                  'No HSN codes found',
                  style: TextStyle(fontSize: 16, color: AppTheme.mutedTextColor),
                ),
              ],
            ),
          );
        }

        // 2. Paginate
        final startIndex = (_currentPage - 1) * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage < filteredList.length) 
            ? startIndex + _itemsPerPage 
            : filteredList.length;
            
        final paginatedList = filteredList.sublist(startIndex, endIndex);

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
                  itemCount: paginatedList.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: AppTheme.tableBorderColor,
                  ),
                  itemBuilder: (context, index) {
                    final hsn = paginatedList[index];
                    return _buildTableRow(hsn, index);
                  },
                ),
              ),
              PaginationControls(
                currentPage: _currentPage,
                totalItems: filteredList.length,
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
            flex: 2,
            child: Text(
              'HSN/SAC Code',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.textColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Expanded(
            flex: 3,
            child: Text(
              'Description',
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
              'Type',
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
              'GST Rate',
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
            flex: 2,
            child: Text(
              'Effective Period',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.textColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(
            width: 80,
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

  Widget _buildTableRow(HsnCode hsn, int index) {
    return Material(
      color: index.isEven ? AppTheme.tableRowEvenColor : AppTheme.tableRowOddColor,
      child: InkWell(
        hoverColor: AppTheme.tableHoverColor,
        onTap: () => showDialog(
          context: context,
          builder: (context) => HsnFormDialog(hsn: hsn),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // HSN Code
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: hsn.type == 'GOODS' ? Colors.blue.shade100 : Colors.purple.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hsn.type == 'GOODS' ? Colors.blue.shade200 : Colors.purple.shade200,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        hsn.type == 'GOODS' ? Icons.inventory_2 : Icons.design_services,
                        color: hsn.type == 'GOODS' ? Colors.blue.shade700 : Colors.purple.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        hsn.code,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Description
              Expanded(
                flex: 3,
                child: Text(
                  hsn.description.isEmpty ? '-' : hsn.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.mutedTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Type
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hsn.type == 'GOODS' ? Colors.blue.shade50 : Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: hsn.type == 'GOODS' ? Colors.blue.shade200 : Colors.purple.shade200,
                      ),
                    ),
                    child: Text(
                      hsn.type == 'GOODS' ? 'Goods' : 'Service',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hsn.type == 'GOODS' ? Colors.blue.shade900 : Colors.purple.shade900,
                      ),
                    ),
                  ),
                ),
              ),
              // GST Rate
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      '${hsn.gstRate.toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ),
              ),
              // Effective Period
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From: ${hsn.effectiveFrom != null ? _dateFormatter.format(hsn.effectiveFrom!) : 'Any'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.mutedTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'To: ${hsn.effectiveTo != null ? _dateFormatter.format(hsn.effectiveTo!) : 'Any'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.mutedTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              SizedBox(
                width: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: Colors.blue,
                      onPressed: () => showDialog(
                        context: context,
                        builder: (context) => HsnFormDialog(hsn: hsn),
                      ),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: Colors.red,
                      onPressed: () => _confirmDelete(hsn),
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

  void _confirmDelete(HsnCode hsn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete HSN?'),
        content: Text('Are you sure you want to delete ${hsn.code}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<POSProvider>().deleteHsnCode(hsn.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('HSN code deleted')),
              );
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
