import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pos_models.dart';
import '../providers/pos_provider.dart';
import '../core/app_theme.dart';
import 'customer_form_screen.dart'; // Ensure you have this file
import '../widgets/common/pagination_controls.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _searchQuery = '';
  int _currentPage = 1;
  static const int _itemsPerPage = 10;
  String _filterMembershipStatus = 'All'; // 'All', 'Member', 'Regular'

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
          Expanded(child: _buildCustomerTable()),
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
            'Customer Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          _buildAddCustomerButton(),
        ],
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
                hintText: 'Search by name, phone, or email...',
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
          const SizedBox(width: 16),
          _buildFilterButton(),
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
    String tempStatus = _filterMembershipStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Filter Customers'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Membership Status', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: tempStatus,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Member', child: Text('Member')),
                    DropdownMenuItem(value: 'Regular', child: Text('Regular')),
                  ],
                  onChanged: (val) => setState(() => tempStatus = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                 setState(() => tempStatus = 'All');
              },
              child: const Text('Reset'),
            ),
            ElevatedButton(
              onPressed: () {
                this.setState(() {
                  _filterMembershipStatus = tempStatus;
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

    if (_filterMembershipStatus != 'All') {
      filters.add(_buildFilterChip(
        label: 'Status: $_filterMembershipStatus',
        onDeleted: () => setState(() { _filterMembershipStatus = 'All'; _currentPage = 1; }),
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
             TextButton(
               onPressed: () {
                 setState(() {
                   _filterMembershipStatus = 'All';
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
      backgroundColor: AppTheme.primaryColor.withAlpha(26),
      labelStyle: TextStyle(color: AppTheme.primaryColor),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
  
  Widget _buildAddCustomerButton() {
    return ElevatedButton.icon(
      onPressed: () => showDialog(
        context: context,
        builder: (context) => const CustomerFormDialog(),
      ),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add Customer'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        elevation: 2,
        shadowColor: AppTheme.primaryColor.withAlpha(77),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCustomerTable() {
    return Consumer<POSProvider>(
      builder: (context, provider, child) {
        final filteredCustomers = provider.customers.where((customer) {
          final query = _searchQuery.toLowerCase();
          final matchesQuery = customer.name.toLowerCase().contains(query) ||
                 customer.phone.contains(query) ||
                 (customer.email?.toLowerCase().contains(query) ?? false);
          
          bool matchesMembership = true;
          if (_filterMembershipStatus != 'All') {
            final isMember = customer.isMember;
            if (_filterMembershipStatus == 'Member') matchesMembership = isMember;
            else matchesMembership = !isMember;
          }

          return matchesQuery && matchesMembership;
        }).toList();

        if (filteredCustomers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: AppTheme.mutedTextColor),
                const SizedBox(height: 16),
                Text(
                  'No customers found',
                  style: TextStyle(fontSize: 16, color: AppTheme.mutedTextColor),
                ),
              ],
            ),
          );
        }

        final startIndex = (_currentPage - 1) * _itemsPerPage;
        if (startIndex >= filteredCustomers.length && _currentPage > 1) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() => _currentPage = 1);
             });
             return const SizedBox.shrink();
        }

        final endIndex = (startIndex + _itemsPerPage < filteredCustomers.length)
            ? startIndex + _itemsPerPage
            : filteredCustomers.length;
            
        final paginatedCustomers = filteredCustomers.sublist(startIndex, endIndex);

        return Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.tableBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
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
                  itemCount: paginatedCustomers.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: AppTheme.tableBorderColor),
                  itemBuilder: (context, index) {
                    final customer = paginatedCustomers[index];
                    return _buildTableRow(customer, index);
                  },
                ),
              ),
               PaginationControls(
                currentPage: _currentPage,
                totalItems: filteredCustomers.length,
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
          const Expanded(flex: 2, child: Text('Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textColor))),
          const Expanded(flex: 2, child: Text('Phone', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textColor))),
          const Expanded(flex: 2, child: Text('Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textColor))),
          const Expanded(flex: 2, child: Text('Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textColor))),
          const SizedBox(width: 100, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textColor), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildTableRow(Customer customer, int index) {
    return Material(
      color: index.isEven ? AppTheme.tableRowEvenColor : AppTheme.tableRowOddColor,
      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (context) => CustomerFormDialog(customer: customer),
        ),
        hoverColor: AppTheme.tableHoverColor,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    _buildCustomerAvatar(customer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        customer.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  customer.phone,
                  style: const TextStyle(fontSize: 13, color: AppTheme.mutedTextColor),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  customer.email ?? '-',
                  style: const TextStyle(fontSize: 13, color: AppTheme.mutedTextColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  customer.address ?? '-',
                  style: const TextStyle(fontSize: 13, color: AppTheme.mutedTextColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
                        builder: (context) => CustomerFormDialog(customer: customer),
                      ),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: Colors.red,
                      onPressed: () => _confirmDelete(context, customer),
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

  Widget _buildCustomerAvatar(Customer customer) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Center(
        child: Text(
          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.purple.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete customer "${customer.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await context.read<POSProvider>().deleteCustomer(customer.id!);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Customer "${customer.name}" deleted')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

}
