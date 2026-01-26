import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pos_models.dart';
import '../providers/pos_provider.dart';
import '../core/app_theme.dart';
import 'membership_plan_form_screen.dart';
import '../widgets/common/pagination_controls.dart';

class MembershipPlansScreen extends StatefulWidget {
  const MembershipPlansScreen({super.key});

  @override
  State<MembershipPlansScreen> createState() => _MembershipPlansScreenState();
}

class _MembershipPlansScreenState extends State<MembershipPlansScreen> {
  String _searchQuery = '';
  // Filters
  String _selectedDiscountType = 'All';
  int? _filterDuration;

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
          Expanded(child: _buildMembershipTable()),
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
            'Membership Plans',
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
                  builder: (context) => const MembershipPlanFormDialog(),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Plan'),
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
    // Collect available durations from provider
    final plans = context.read<POSProvider>().membershipPlans;
    final durations = [null, ...plans.map((e) => e.durationMonths).toSet().toList()..sort()];

    // Temp state
    String tempDiscount = _selectedDiscountType;
    int? tempDuration = _filterDuration;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Plans'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Discount Type', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: tempDiscount,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All')),
                  DropdownMenuItem(value: 'FLAT', child: Text('Flat Amount')),
                  DropdownMenuItem(value: 'PERCENTAGE', child: Text('Percentage')),
                ],
                onChanged: (val) => setState(() => tempDiscount = val!),
              ),
              const SizedBox(height: 16),
              const Text('Duration (Months)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
               DropdownButtonFormField<int?>(
                value: tempDuration,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                items: durations.map((d) {
                  return DropdownMenuItem(
                    value: d,
                    child: Text(d == null ? 'All' : '$d Months'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => tempDuration = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  tempDiscount = 'All';
                  tempDuration = null;
                });
              },
              child: const Text('Reset'),
            ),
            ElevatedButton(
              onPressed: () {
                this.setState(() {
                  _selectedDiscountType = tempDiscount;
                  _filterDuration = tempDuration;
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

    if (_selectedDiscountType != 'All') {
      filters.add(_buildFilterChip(
        label: 'Type: ${_selectedDiscountType == 'FLAT' ? 'Flat' : 'Percentage'}',
        onDeleted: () => setState(() { _selectedDiscountType = 'All'; _currentPage = 1; }),
      ));
    }

    if (_filterDuration != null) {
      filters.add(_buildFilterChip(
        label: 'Duration: ${_filterDuration} Months',
        onDeleted: () => setState(() { _filterDuration = null; _currentPage = 1; }),
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
                   _selectedDiscountType = 'All';
                   _filterDuration = null;
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
          hintText: 'Search membership plans...',
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

  Widget _buildMembershipTable() {
    return Consumer<POSProvider>(
      builder: (context, provider, child) {
        // 1. Filter
        final filteredPlans = provider.membershipPlans.where((p) {
          final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesDiscount = _selectedDiscountType == 'All' || p.discountType == _selectedDiscountType;
          final matchesDuration = _filterDuration == null || p.durationMonths == _filterDuration;

          return matchesSearch && matchesDiscount && matchesDuration;
        }).toList();

        if (filteredPlans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.card_membership_outlined, size: 64, color: AppTheme.mutedTextColor),
                const SizedBox(height: 16),
                Text(
                  'No membership plans found',
                  style: TextStyle(fontSize: 16, color: AppTheme.mutedTextColor),
                ),
              ],
            ),
          );
        }

        // 2. Paginate
        final startIndex = (_currentPage - 1) * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage < filteredPlans.length) 
            ? startIndex + _itemsPerPage 
            : filteredPlans.length;
            
        final paginatedPlans = filteredPlans.sublist(startIndex, endIndex);

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
                  itemCount: paginatedPlans.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: AppTheme.tableBorderColor,
                  ),
                  itemBuilder: (context, index) {
                    final plan = paginatedPlans[index];
                    return _buildTableRow(plan, index);
                  },
                ),
              ),
              PaginationControls(
                currentPage: _currentPage,
                totalItems: filteredPlans.length,
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
              'Plan Name',
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
              'Price & Duration',
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
              'Benefits',
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

  Widget _buildTableRow(MembershipPlan plan, int index) {
    final colors = [
      Colors.amber,
      Colors.grey,
      Colors.blue,
      Colors.indigo,
    ];
    final color = colors[plan.name.hashCode % colors.length];

    return Material(
      color: index.isEven ? AppTheme.tableRowEvenColor : AppTheme.tableRowOddColor,
      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (context) => MembershipPlanFormDialog(plan: plan),
        ),
        hoverColor: AppTheme.tableHoverColor,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // Plan with avatar
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
                        child: Text(
                          plan.name[0].toUpperCase(),
                          style: TextStyle(
                            color: color.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        plan.name,
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
              // Price & Duration
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${plan.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.textColor,
                      ),
                    ),
                    Text(
                      '${plan.durationMonths} Months',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.mutedTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Benefits
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(
                        'Benefit: ${plan.discountType == 'FLAT' ? '₹' : ''}${plan.discountValue}${plan.discountType == 'PERCENTAGE' ? '%' : ''} Off',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                    if (plan.benefits.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          plan.benefits,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.mutedTextColor,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              // GST
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      '${plan.gstRate.toInt()}%',
                      style: TextStyle(
                        color: Colors.blue.shade900,
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
                        builder: (context) => MembershipPlanFormDialog(plan: plan),
                      ),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: Colors.red,
                      onPressed: () => _confirmDelete(plan),
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

  void _confirmDelete(MembershipPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${plan.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<POSProvider>().deleteMembershipPlan(plan.id!);
              Navigator.pop(context);
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
