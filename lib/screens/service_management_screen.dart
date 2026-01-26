import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import '../models/pos_models.dart';
import '../core/app_theme.dart';
import 'service_form_screen.dart';
import '../widgets/common/pagination_controls.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({super.key});

  @override
  State<ServiceManagementScreen> createState() => _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  String _searchQuery = '';
  // Filters
  double? _filterGstRate;
  RangeValues? _rateRange;
  
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
          _buildSearchBar(),
          Expanded(child: _buildServiceTable()),
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
            'Service List',
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
                  builder: (context) => const ServiceFormDialog(),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Service'),
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
    final services = context.read<POSProvider>().services;
    final gstRates = [0.0, 5.0, 12.0, 18.0, 28.0];
    
    // Calculate max rate
    double maxRate = 0;
    if (services.isNotEmpty) {
      maxRate = services.map((s) => s.rate).reduce((a, b) => a > b ? a : b);
    }
    if (maxRate == 0) maxRate = 5000;

    // Temp state
    double? tempGst = _filterGstRate;
    RangeValues tempRate = _rateRange ?? RangeValues(0, maxRate);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Services'),
          content: SizedBox(
             width: 400,
             child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 16),
                const Text('Service Rate Range', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('₹${tempRate.start.toInt()}'),
                    Expanded(
                      child: RangeSlider(
                        values: tempRate,
                        min: 0,
                        max: maxRate,
                        divisions: 100,
                        labels: RangeLabels(
                          '₹${tempRate.start.toInt()}', 
                          '₹${tempRate.end.toInt()}'
                        ),
                        onChanged: (values) => setState(() => tempRate = values),
                      ),
                    ),
                    Text('₹${tempRate.end.toInt()}'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  tempGst = null;
                  tempRate = RangeValues(0, maxRate);
                });
              },
              child: const Text('Reset'),
            ),
            ElevatedButton(
              onPressed: () {
                this.setState(() {
                  _filterGstRate = tempGst;
                  _rateRange = tempRate;
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

    if (_filterGstRate != null) {
      filters.add(_buildFilterChip(
        label: 'GST: ${_filterGstRate!.toInt()}%',
        onDeleted: () => setState(() { _filterGstRate = null; _currentPage = 1; }),
      ));
    }

    if (_rateRange != null) {
      filters.add(_buildFilterChip(
        label: 'Rate: ₹${_rateRange!.start.toInt()} - ₹${_rateRange!.end.toInt()}',
        onDeleted: () => setState(() { _rateRange = null; _currentPage = 1; }),
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
                   _filterGstRate = null;
                   _rateRange = null;
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
          _currentPage = 1; // Reset to page 1 on search
        }),
        decoration: InputDecoration(
          hintText: 'Search services...',
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

  Widget _buildServiceTable() {
    return Consumer<POSProvider>(
      builder: (context, provider, child) {
        // 1. Filter
        final filteredServices = provider.services.where((s) {
          final matchesSearch = s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 s.description.toLowerCase().contains(_searchQuery.toLowerCase());
          
          final matchesGst = _filterGstRate == null || s.gstRate == _filterGstRate;

          bool matchesRate = true;
          if (_rateRange != null) {
            matchesRate = s.rate >= _rateRange!.start && s.rate <= _rateRange!.end;
          }

          return matchesSearch && matchesGst && matchesRate;
        }).toList();

        if (filteredServices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.miscellaneous_services_outlined, size: 64, color: AppTheme.mutedTextColor),
                const SizedBox(height: 16),
                Text(
                  'No services found',
                  style: TextStyle(fontSize: 16, color: AppTheme.mutedTextColor),
                ),
              ],
            ),
          );
        }

        // 2. Paginate
        final startIndex = (_currentPage - 1) * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage < filteredServices.length) 
            ? startIndex + _itemsPerPage 
            : filteredServices.length;
            
        final paginatedServices = filteredServices.sublist(startIndex, endIndex);

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
                  itemCount: paginatedServices.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: AppTheme.tableBorderColor,
                  ),
                  itemBuilder: (context, index) {
                    final service = paginatedServices[index];
                    return _buildTableRow(service, index);
                  },
                ),
              ),
              PaginationControls(
                currentPage: _currentPage,
                totalItems: filteredServices.length,
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
              'Service',
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
              'Rate',
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
              'GST',
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

  Widget _buildTableRow(Service service, int index) {
    final colors = [
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
    ];
    final color = colors[service.name.hashCode % colors.length];

    return Material(
      color: index.isEven ? AppTheme.tableRowEvenColor : AppTheme.tableRowOddColor,
      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (context) => ServiceFormDialog(service: service),
        ),
        hoverColor: AppTheme.tableHoverColor,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // Service with icon
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(color: color.shade200, width: 2),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.miscellaneous_services,
                          color: color.shade700,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        service.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Description
              Expanded(
                flex: 2,
                child: Text(
                  service.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.mutedTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Rate
              Expanded(
                child: Text(
                  '₹${service.rate.toStringAsFixed(2)}',
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
                  service.hsnCode ?? '-',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // GST
              Expanded(
                child: Center(
                  child: service.gstRate > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            '${service.gstRate.toInt()}%',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : Text(
                          '-',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.mutedTextColor,
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
                        builder: (context) => ServiceFormDialog(service: service),
                      ),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: Colors.red,
                      onPressed: () => _confirmDelete(context, service),
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

  void _confirmDelete(BuildContext context, Service service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${service.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<POSProvider>().deleteService(service.id!);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Service "${service.name}" deleted')),
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
