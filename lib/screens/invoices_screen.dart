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
  static const int _itemsPerPage = 10;

  // Debounce search
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildActiveFilters(), // Moved here
          _buildSearchAndFilter(), // Replaces _buildToolbar
          Expanded(child: _buildInvoiceList()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
               _buildCreateActionButton(
                label: 'Product Bill',
                icon: Icons.shopping_bag_outlined,
                color: Colors.green.shade600, 
                onPressed: () => _navigateToCreateScreen(context, InvoiceType.product),
              ),
               const SizedBox(width: 8),
               _buildCreateActionButton(
                label: 'Service Bill',
                icon: Icons.build_outlined,
                color: Colors.blue.shade600, 
                onPressed: () => _navigateToCreateScreen(context, InvoiceType.service),
              ),
               const SizedBox(width: 8),
               _buildCreateActionButton(
                label: 'Membership',
                icon: Icons.card_membership,
                color: Colors.purple.shade600, 
                onPressed: () => _navigateToCreateScreen(context, InvoiceType.membership),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreateActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildCreateButton({
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        elevation: 2,
        shadowColor: color.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
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
              onChanged: (val) {
                setState(() => _searchQuery = val);
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                    context.read<POSProvider>().searchInvoices(val);
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by Invoice No, Customer, Phone...',
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
          ),
          const SizedBox(width: 16),
          _buildFilterButton(),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _filterDateFrom != null || _filterDateTo != null || _filterType != null || _filterBillType != 'ALL' || _filterStatus != 'ALL';
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

  Widget _buildInvoiceList() {
    return Consumer<POSProvider>(
      builder: (context, provider, child) {
        // 1. Filter
        final filteredInvoices = provider.invoices.where((i) {
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
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No invoices found',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        // 2. Paginate
        final startIndex = (_currentPage - 1) * _itemsPerPage;
        if (startIndex >= filteredInvoices.length && _currentPage > 1) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() => _currentPage = 1);
             });
             return const SizedBox.shrink();
        }

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
                    color: AppTheme.tableBorderColor
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
          topRight: Radius.circular(12)
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('Invoice No', flex: 2),
          _buildHeaderCell('Date & Time', flex: 2),
          _buildHeaderCell('Type', flex: 1, align: TextAlign.center),
          _buildHeaderCell('Amount', flex: 1, align: TextAlign.right),
          _buildHeaderCell('Status', flex: 1, align: TextAlign.center),
          const SizedBox(width: 80, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textColor), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, {required int flex, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: AppTheme.textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTableRow(Invoice invoice, int index) {
    // Determine colors based on type
    final typeColors = _getTypeColor(invoice.type);
    
    return Material(
      color: index.isEven ? AppTheme.tableRowEvenColor : AppTheme.tableRowOddColor,
      child: InkWell(
        onTap: () => _viewInvoiceDetails(invoice),
        hoverColor: AppTheme.tableHoverColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.invoiceNumber,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textColor),
                    ),
                    if (invoice.billType == 'ADVANCE')
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Container(
                           padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                           decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(4)),
                           child: Text('ADVANCE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.purple.shade700)),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(invoice.createdAt),
                  style: TextStyle(fontSize: 13, color: AppTheme.mutedTextColor),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColors.background,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      invoice.type.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: typeColors.text,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '₹${invoice.totalAmount.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textColor),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(child: _buildStatusBadge(invoice.status)),
              ),
               SizedBox(
                width: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.visibility_outlined, size: 18, color: AppTheme.mutedTextColor),
                      onPressed: () => _viewInvoiceDetails(invoice),
                      tooltip: 'View Details',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 18, color: AppTheme.mutedTextColor),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (val) {
                        if (val == 'print') _printInvoice(invoice);
                        if (val == 'cancel') _showCancelDialog(context, invoice.id!);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'print',
                          child: Row(
                            children: [
                              Icon(Icons.print_outlined, size: 18),
                               SizedBox(width: 8),
                              Text('Print'),
                            ],
                          ),
                        ),
                        if (invoice.status == InvoiceStatus.completed || invoice.status == InvoiceStatus.active)
                           PopupMenuItem(
                            value: 'cancel', 
                            child: Row(
                              children: [
                                Icon(Icons.cancel_outlined, size: 18, color: Colors.red.shade400),
                                 const SizedBox(width: 8),
                                Text('Cancel Invoice', style: TextStyle(color: Colors.red.shade400)),
                              ],
                            ),
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
  
  ({Color background, Color text}) _getTypeColor(InvoiceType type) {
    switch (type) {
      case InvoiceType.service: return (background: Colors.blue.shade50, text: Colors.blue.shade700);
      case InvoiceType.product: return (background: Colors.green.shade50, text: Colors.green.shade700);
      case InvoiceType.advance: return (background: Colors.orange.shade50, text: Colors.orange.shade700);
      case InvoiceType.membership: return (background: Colors.purple.shade50, text: Colors.purple.shade700);
    }
  }

  Widget _buildStatusBadge(InvoiceStatus status) {
    Color bg;
    Color text;
    String label;
    
    switch (status) {
      case InvoiceStatus.active:
      case InvoiceStatus.completed:
        bg = Colors.green.shade50;
        text = Colors.green.shade700;
        label = 'COMPLETED';
        break;
      case InvoiceStatus.cancelled:
        bg = Colors.red.shade50;
        text = Colors.red.shade700;
        label = 'CANCELLED';
        break;
      case InvoiceStatus.hold:
        bg = Colors.orange.shade50;
        text = Colors.orange.shade700;
        label = 'ON HOLD';
        break;
      case InvoiceStatus.partial:
        bg = Colors.amber.shade50;
        text = Colors.amber.shade800; // Darker for visibility
        label = 'PARTIAL';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: bg.withOpacity(0.5)), 
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }

  // Active Filters Widgets
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
        label: 'Bill: $_filterBillType',
        onDeleted: () => setState(() { _filterBillType = 'ALL'; _currentPage = 1; }),
      ));
    }

    if (_filterStatus != 'ALL') {
      filters.add(_buildFilterChip(
        label: 'Status: $_filterStatus',
        onDeleted: () => setState(() { _filterStatus = 'ALL'; _currentPage = 1; }),
      ));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 8),
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
      labelStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  // Dialogs & Actions
  void _navigateToCreateScreen(BuildContext context, InvoiceType type) {
    String tabId = 'create_invoice_${type.name}_${DateTime.now().millisecondsSinceEpoch}';
    String title = 'New Invoice';
    Widget screen;

    switch (type) {
      case InvoiceType.product:
        title = 'New Product Bill';
        screen = ProductInvoiceScreen(tabId: tabId);
        break;
      case InvoiceType.service:
        title = 'New Service Bill';
        screen = ServiceInvoiceScreen(tabId: tabId);
        break;
      case InvoiceType.membership:
        title = 'New Membership';
        screen = MembershipInvoiceScreen(tabId: tabId);
        break;
      default:
        return;
    }

    context.read<TabProvider>().addTab(
      TabItem(id: tabId, title: title, widget: screen, type: TabType.createInvoice),
    );
  }

  void _viewInvoiceDetails(Invoice invoice) {
    final tabId = 'invoice_details_${invoice.id}';
    final tabProvider = context.read<TabProvider>();
    
    if (tabProvider.hasTab(tabId)) {
      tabProvider.setActiveTab(tabId);
    } else {
      tabProvider.addTab(
        TabItem(
          id: tabId,
          title: 'Invoice #${invoice.invoiceNumber}',
          widget: InvoiceDetailsScreen(invoiceId: invoice.id!),
          type: TabType.invoiceDetails,
        ),
      );
    }
  }

  void _showFilterDialog() {
    DateTime? tempFrom = _filterDateFrom;
    DateTime? tempTo = _filterDateTo;
    InvoiceType? tempType = _filterType;
    String tempStatus = _filterStatus;
    String tempBillType = _filterBillType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                            decoration:  InputDecoration(labelText: 'From', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                            child: Text(tempFrom != null ? _dateFormatter.format(tempFrom!) : 'Select'),
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
                            decoration: InputDecoration(labelText: 'To', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                             child: Text(tempTo != null ? _dateFormatter.format(tempTo!) : 'Select'),
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
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Types')),
                      ...InvoiceType.values
                        .where((t) => t != InvoiceType.advance)
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()))),
                    ],
                    onChanged: (val) => setState(() => tempType = val),
                  ),
                  const SizedBox(height: 16),

                  const Text('Bill Type', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: tempBillType,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12)),
                    items: ['ALL', 'REGULAR', 'ADVANCE'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => tempBillType = val!),
                  ),
                  const SizedBox(height: 16),

                  const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: tempStatus,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12)),
                    items: ['ALL', 'COMPLETED', 'PARTIAL', 'CANCELLED', 'HOLD'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), 
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, int invoiceId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Invoice'),
        content: const Text('Are you sure you want to cancel this invoice? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<POSProvider>().cancelInvoice(invoiceId, 'Cancelled by user');
    }
  }

  Future<void> _printInvoice(Invoice invoice) async {
       // TODO: Re-enable printing once dependencies are sorted
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Printing feature coming soon')));
  }
}
