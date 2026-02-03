import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/pos_provider.dart';
import '../providers/tab_provider.dart';
import '../providers/auth_provider.dart';
import '../models/pos_models.dart';
import '../core/app_theme.dart';
import 'create_invoices/service_invoice_screen.dart';
import 'create_invoices/product_invoice_screen.dart';

import 'create_invoices/membership_invoice_screen.dart';
import 'invoice_details_screen.dart';
import '../providers/settings_provider.dart';
import '../services/export_service.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import 'dart:async';
import '../widgets/common/pagination_controls.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  String _searchQuery = '';
  // Filters
  String _filterStatus = 'ALL';
  String _filterBillType = 'ALL';
  DateTime? _filterDateFrom;
  DateTime? _filterDateTo;
  InvoiceType? _filterType;

  final ExportService _exportService = ExportService();
  final _dateFormatter = DateFormat('dd MMM yyyy');
  
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
          Expanded(child: _buildInvoiceTable()),
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
            'Invoices',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          Row(
            children: [
              _buildFilterButton(),
              const SizedBox(width: 16),
              _buildInvoiceActionButtons(context),
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
      label: const Text('Filters'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.mutedTextColor,
        side: BorderSide(color: AppTheme.tableBorderColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _showFilterDialog() {
    // Temporary variables to hold state within dialog
    DateTime? tempFrom = _filterDateFrom;
    DateTime? tempTo = _filterDateTo;
    InvoiceType? tempType = _filterType;
    String tempStatus = _filterStatus;
    String tempBillType = _filterBillType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Invoices'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: tempFrom ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) setState(() => tempFrom = date);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'From',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: Text(
                              tempFrom != null ? _dateFormatter.format(tempFrom!) : 'Select',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                         child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: tempTo ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) setState(() => tempTo = date);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'To',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: Text(
                              tempTo != null ? _dateFormatter.format(tempTo!) : 'Select',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('Invoice Type', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<InvoiceType?>(
                    value: tempType,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Types')),
                      ...InvoiceType.values
                        .where((t) => t != InvoiceType.advance) // Exclude Advance from Type
                        .map((t) => DropdownMenuItem(
                          value: t, 
                          child: Text(t.name.toUpperCase()),
                        )),
                    ],
                    onChanged: (val) => setState(() => tempType = val),
                  ),
                  const SizedBox(height: 16),

                  const Text('Bill Type', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: tempBillType,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    items: ['ALL', 'REGULAR', 'ADVANCE']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) => setState(() => tempBillType = val!),
                  ),
                  const SizedBox(height: 16),

                  const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: tempStatus,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    items: ['ALL', 'COMPLETED', 'PARTIAL', 'CANCELLED']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) => setState(() => tempStatus = val!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
             TextButton(
              onPressed: () {
                setState(() {
                  tempFrom = null;
                  tempTo = null;
                  tempType = null;
                  tempStatus = 'ALL';
                  tempBillType = 'ALL';
                });
              },
              child: const Text('Reset'),
            ),
            ElevatedButton(
              onPressed: () {
                this.setState(() {
                  _filterDateFrom = tempFrom;
                  _filterDateTo = tempTo;
                  _filterType = tempType;
                  _filterStatus = tempStatus;
                  _filterBillType = tempBillType;
                  _currentPage = 1;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    final filters = <Widget>[];

    if (_filterDateFrom != null || _filterDateTo != null) {
      String label = 'Date: ';
      if (_filterDateFrom != null && _filterDateTo != null) {
        label += '${_dateFormatter.format(_filterDateFrom!)} - ${_dateFormatter.format(_filterDateTo!)}';
      } else if (_filterDateFrom != null) {
        label += 'From ${_dateFormatter.format(_filterDateFrom!)}';
      } else if (_filterDateTo != null) {
        label += 'To ${_dateFormatter.format(_filterDateTo!)}';
      }
      filters.add(_buildFilterChip(
        label: label, 
        onDeleted: () => setState(() { _filterDateFrom = null; _filterDateTo = null; _currentPage = 1; }),
      ));
    }

    if (_filterType != null) {
      filters.add(_buildFilterChip(
        label: 'Type: ${_filterType!.name.toUpperCase()}',
        onDeleted: () => setState(() { _filterType = null; _currentPage = 1; }),
      ));
    }

    if (_filterBillType != 'ALL') {
      filters.add(_buildFilterChip(
        label: 'Bill Type: $_filterBillType',
        onDeleted: () => setState(() { _filterBillType = 'ALL'; _currentPage = 1; }),
      ));
    }

    if (_filterStatus != 'ALL') {
      filters.add(_buildFilterChip(
        label: 'Status: $_filterStatus',
        onDeleted: () => setState(() { _filterStatus = 'ALL'; _currentPage = 1; }),
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
                   _filterDateFrom = null;
                   _filterDateTo = null;
                   _filterType = null;
                   _filterStatus = 'ALL';
                   _filterBillType = 'ALL';
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

  Widget _buildInvoiceActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          context,
          label: 'Product',
          icon: Icons.shopping_bag_outlined,
          color: Colors.green,
          onPressed: () => _navigateToCreateScreen(context, InvoiceType.product),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          context,
          label: 'Service',
          icon: Icons.build_outlined,
          color: Colors.blue,
          onPressed: () => _navigateToCreateScreen(context, InvoiceType.service),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          context,
          label: 'Membership',
          icon: Icons.card_membership_outlined,
          color: Colors.purple,
          onPressed: () => _navigateToCreateScreen(context, InvoiceType.membership),
        ),

      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Debounce search
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: TextField(
        onChanged: (val) {
          setState(() => _searchQuery = val);
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
             context.read<POSProvider>().searchInvoices(val);
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by Invoice No, Customer Name or Phone...',
          prefixIcon: Icon(Icons.search, color: AppTheme.mutedTextColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() => _searchQuery = '');
                    context.read<POSProvider>().searchInvoices('');
                  },
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

  Widget _buildInvoiceTable() {
    return Consumer<POSProvider>(
      builder: (context, provider, child) {
        // 1. Filter (Search is now handled by Provider, so we only filter Status/Type/Date here)
        final filteredInvoices = provider.invoices.where((i) {
          // final matchesSearch = i.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase()); // Handled by DB
          final matchesStatus = _filterStatus == 'ALL' || i.status.name.toUpperCase() == _filterStatus;
          final matchesType = _filterType == null || i.type == _filterType;
          final matchesBillType = _filterBillType == 'ALL' || i.billType == _filterBillType;
          
          bool matchesDate = true;
          if (_filterDateFrom != null) {
            matchesDate = matchesDate && i.createdAt.isAfter(_filterDateFrom!.subtract(const Duration(seconds: 1)));
          }
          if (_filterDateTo != null) {
            matchesDate = matchesDate && i.createdAt.isBefore(_filterDateTo!.add(const Duration(days: 1)));
          }

          return matchesStatus && matchesType && matchesBillType && matchesDate;
        }).toList();

        if (filteredInvoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.mutedTextColor),
                const SizedBox(height: 16),
                Text(
                  'No invoices found',
                  style: TextStyle(fontSize: 16, color: AppTheme.mutedTextColor),
                ),
              ],
            ),
          );
        }

        // 2. Paginate
        final startIndex = (_currentPage - 1) * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage < filteredInvoices.length) 
            ? startIndex + _itemsPerPage 
            : filteredInvoices.length;
            
        final paginatedInvoices = filteredInvoices.sublist(startIndex, endIndex);


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
                  itemCount: paginatedInvoices.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: AppTheme.tableBorderColor,
                  ),
                  itemBuilder: (context, index) {
                    final invoice = paginatedInvoices[index];
                    return _buildTableRow(invoice, index);
                  },
                ),
              ),
              PaginationControls(
                currentPage: _currentPage,
                totalItems: filteredInvoices.length,
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
              'Invoice No',
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
              'Date & Time',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.textColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Expanded(
            flex: 1,
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
            flex: 1,
            child: Text(
              'Total',
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
            flex: 1,
            child: Text(
              'Status',
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

  Widget _buildTableRow(Invoice invoice, int index) {
    return Material(
      color: index.isEven ? AppTheme.tableRowEvenColor : AppTheme.tableRowOddColor,
      child: InkWell(
        onTap: () => _viewInvoiceDetails(invoice),
        hoverColor: AppTheme.tableHoverColor,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // Invoice No
              Expanded(
                flex: 2,
                child: Text(
                  invoice.invoiceNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textColor,
                  ),
                ),
              ),
              // Date & Time
              Expanded(
                flex: 2,
                child: Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(invoice.createdAt),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.mutedTextColor,
                  ),
                ),
              ),
              // Type
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(invoice.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _getTypeColor(invoice.type).withOpacity(0.3)),
                    ),
                    child: Text(
                      invoice.type.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getTypeColor(invoice.type),
                      ),
                    ),
                  ),
                ),
              ),
              // Total
              Expanded(
                flex: 1,
                child: Text(
                  '₹${invoice.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.textColor,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              // Status
              Expanded(
                flex: 1,
                child: Center(
                  child: _buildStatusBadge(invoice.status),
                ),
              ),
              // Actions
              SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      color: Colors.blue,
                      onPressed: () => _viewInvoiceDetails(invoice),
                      tooltip: 'View',
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      onSelected: (val) {
                        if (val == 'print') _printInvoice(invoice);
                        if (val == 'cancel') _showCancelDialog(context, invoice.id!);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'print', child: Text('Print')),
                        if (invoice.status == InvoiceStatus.completed || invoice.status == InvoiceStatus.active)
                          const PopupMenuItem(
                            value: 'cancel', 
                            child: Text('Cancel Invoice', style: TextStyle(color: Colors.red)),
                          ),
                      ],
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

  Color _getTypeColor(InvoiceType type) {
    switch (type) {
      case InvoiceType.service: return Colors.blue;
      case InvoiceType.product: return Colors.green;
      case InvoiceType.advance: return Colors.orange;
      case InvoiceType.membership: return Colors.purple;
    }
  }

  Widget _buildStatusBadge(InvoiceStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case InvoiceStatus.active:
        color = Colors.green;
        text = 'ACTIVE';
        break;
      case InvoiceStatus.cancelled:
        color = Colors.red;
        text = 'CANCELLED';
        break;
      case InvoiceStatus.hold:
        color = Colors.orange;
        text = 'ON HOLD';
        break;
      case InvoiceStatus.partial:
        color = Colors.deepOrange;
        text = 'PARTIAL';
        break;
      case InvoiceStatus.completed:
        color = Colors.green;
        text = 'COMPLETED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color.withOpacity(1), // Opacity of 1 (opaque) but using base color
        ),
      ),
    );
  }

  void _navigateToCreateScreen(BuildContext context, InvoiceType type) {
    final tabId = '${type.name}_${DateTime.now().millisecondsSinceEpoch}';
    Widget screen;
    String title;
    
    switch (type) {
      case InvoiceType.service: 
        screen = ServiceInvoiceScreen(tabId: tabId); 
        title = 'Service Inv';
        break;
      case InvoiceType.product: 
        screen = ProductInvoiceScreen(tabId: tabId); 
        title = 'Product Inv';
        break;

      case InvoiceType.membership: 
        screen = MembershipInvoiceScreen(tabId: tabId); 
        title = 'Membership';
        break;
      case InvoiceType.advance:
        return; // No longer supported via this button
    }

    context.read<TabProvider>().addTab(
      TabItem(
        id: tabId,
        title: title,
        widget: screen,
        type: _TypeToTabType(type),
      ),
    );
  }

  TabType _TypeToTabType(InvoiceType type) {
    switch (type) {
      case InvoiceType.service: return TabType.serviceInvoice;
      case InvoiceType.product: return TabType.productInvoice;

      case InvoiceType.membership: return TabType.membership;
      default: return TabType.invoices;
    }
  }

  void _viewInvoiceDetails(Invoice invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => InvoiceDetailsScreen(invoice: invoice)),
    );
  }

  void _printInvoice(Invoice invoice) async {
    final provider = context.read<POSProvider>();
    final branch = provider.getBranchById(invoice.branchId);
    
    final authProvider = context.read<AuthProvider>();
    final cashierName = authProvider.currentUser?.fullName;
    final printerType = context.read<SettingsProvider>().printerType;
    
    await Printing.layoutPdf(
      onLayout: (format) async {
        final path = await _exportService.generateInvoicePDF(
          invoice, 
          branch: branch,
          cashierName: cashierName,
          printerType: printerType,
        );
        final file = File(path);
        return await file.readAsBytes();
      },
    );
  }

  void _showCancelDialog(BuildContext context, int invoiceId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Invoice'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason for cancellation'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<POSProvider>().cancelInvoice(invoiceId, reasonController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Confirm Cancellation'),
          ),
        ],
      ),
    );
  }
}
