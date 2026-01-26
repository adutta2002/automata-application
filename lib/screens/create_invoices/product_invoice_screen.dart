import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/pos_models.dart';
import '../../providers/pos_provider.dart';
import '../../providers/tab_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/app_theme.dart';
import '../../widgets/invoice/customer_selector.dart';
import '../../widgets/invoice/invoice_summary_pane.dart';
import '../../widgets/invoice/invoice_item_tile.dart';
import '../invoices_screen.dart';
import '../invoice_details_screen.dart';

class ProductInvoiceScreen extends StatefulWidget {
  final String? tabId;
  final Invoice? existingInvoice;
  const ProductInvoiceScreen({super.key, this.tabId, this.existingInvoice});

  @override
  State<ProductInvoiceScreen> createState() => _ProductInvoiceScreenState();
}

class _ProductInvoiceScreenState extends State<ProductInvoiceScreen> {
  Customer? _selectedCustomer;
  List<InvoiceItem> _items = [];
  double _subTotal = 0;
  double _tax = 0;
  double _billDiscount = 0;
  double _totalAmount = 0;
  
  double _billDiscountInput = 0;
  bool _isBillDiscountPercentage = false;
  late bool _isTaxInclusive;
  double _advanceAdjustedAmount = 0;
  String _paymentMode = 'CASH';
  
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _isTaxInclusive = settings.productTaxInclusive;

    if (widget.existingInvoice != null) {
      _loadExistingInvoice();
    }
  }

  void _loadExistingInvoice() {
    final inv = widget.existingInvoice!;
    _selectedCustomer = context.read<POSProvider>().customers.firstWhere(
      (c) => c.id == inv.customerId,
      orElse: () => Customer(name: 'Unknown', phone: '', email: '', address: '', createdAt: DateTime.now())
    );
    _items = List.from(inv.items);
    _selectedDate = inv.createdAt;
    _billDiscountInput = inv.discountAmount; // Assuming flat for simplicity on edit or we need to reverse calc
    _paymentMode = inv.paymentMode ?? 'CASH';
    _advanceAdjustedAmount = inv.advanceAdjustedAmount;
    _isBillDiscountPercentage = false; // Reset to flat to avoid complexity
    
    // Defer calc to end of frame to ensure providers ready if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _calculateTotals();
    });
  }

  double _totalCGST = 0;
  double _totalSGST = 0;
  List<HsnTaxBreakdown> _taxBreakdown = [];

  void _calculateTotals() {
    double tempSubTotal = 0;
    double tempTax = 0;
    double tempTotalCGST = 0;
    double tempTotalSGST = 0;

    List<InvoiceItem> updatedItems = [];
    Map<double, HsnTaxBreakdown> breakdownMap = {};

    for (var item in _items) {
      double rate = item.rate;
      double quantity = item.quantity;
      double discount = item.discount;
      double gstPercent = item.gstRate;

      double lineAmount = (rate * quantity) - discount;
      if (lineAmount < 0) lineAmount = 0;

      double itemTax = 0;
      double itemBase = 0;
      double itemTotal = 0;

      if (_isTaxInclusive) {
        itemBase = lineAmount / (1 + (gstPercent / 100));
        itemTax = lineAmount - itemBase;
        itemTotal = lineAmount;
      } else {
        itemBase = lineAmount;
        itemTax = itemBase * (gstPercent / 100);
        itemTotal = itemBase + itemTax;
      }

      double cgst = itemTax / 2;
      double sgst = itemTax / 2;

      tempSubTotal += itemBase;
      tempTax += itemTax;
      tempTotalCGST += cgst;
      tempTotalSGST += sgst;

      if (!breakdownMap.containsKey(gstPercent)) {
        breakdownMap[gstPercent] = HsnTaxBreakdown(
          hsnCode: 'GST ${gstPercent.toInt()}%',
          baseAmount: 0,
          gstRate: gstPercent,
          cgst: 0,
          sgst: 0,
          totalTax: 0,
        );
      }
      final existing = breakdownMap[gstPercent]!;
      breakdownMap[gstPercent] = HsnTaxBreakdown(
        hsnCode: existing.hsnCode,
        baseAmount: existing.baseAmount + itemBase,
        gstRate: existing.gstRate,
        cgst: existing.cgst + cgst,
        sgst: existing.sgst + sgst,
        totalTax: existing.totalTax + itemTax,
      );

      updatedItems.add(InvoiceItem(
        id: item.id,
        invoiceId: item.invoiceId,
        itemId: item.itemId,
        itemType: item.itemType,
        name: item.name,
        quantity: quantity,
        rate: rate,
        discount: discount,
        total: itemTotal,
        hsnCode: item.hsnCode,
        gstRate: gstPercent,
        cgst: cgst,
        sgst: sgst,
        igst: 0,
      ));
    }

    _items = updatedItems;
    _subTotal = tempSubTotal;
    _tax = tempTax;
    _totalCGST = tempTotalCGST;
    _totalSGST = tempTotalSGST;
    _taxBreakdown = breakdownMap.values.toList()..sort((a, b) => a.gstRate.compareTo(b.gstRate));

    if (_isBillDiscountPercentage) {
      _billDiscount = (_subTotal + _tax) * (_billDiscountInput / 100);
    } else {
      _billDiscount = _billDiscountInput;
    }

    _totalAmount = (_subTotal + _tax) - _billDiscount;
    if(_totalAmount < 0) _totalAmount = 0;

    // Validate Advance Adjustment
    if (_selectedCustomer != null && _advanceAdjustedAmount > 0) {
      if (_advanceAdjustedAmount > _totalAmount) {
        _advanceAdjustedAmount = _totalAmount;
      }
      if (_advanceAdjustedAmount > _selectedCustomer!.advanceBalance) {
        _advanceAdjustedAmount = _selectedCustomer!.advanceBalance;
      }
    } else {
      _advanceAdjustedAmount = 0;
    }

    setState(() {});
  }

  void _checkMembership(Customer? customer) {
    if (customer == null || customer.membershipPlanId == null) return;
    
    if (customer.membershipExpiry != null && customer.membershipExpiry!.isBefore(DateTime.now())) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membership Expired! No discount applied.')));
       return;
    }

    final plans = context.read<POSProvider>().membershipPlans;
    try {
      final plan = plans.firstWhere((p) => p.id == customer.membershipPlanId);
      
      if (plan.discountValue > 0) {
        setState(() {
          _billDiscountInput = plan.discountValue;
          _isBillDiscountPercentage = plan.discountType == 'PERCENTAGE';
        });
        _calculateTotals();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Applied Membership Discount: ${plan.name} (${plan.discountType == 'FLAT' ? '₹' : ''}${plan.discountValue}${plan.discountType == 'PERCENTAGE' ? '%' : ''})'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      // Plan might have been deleted
    }
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          final time = await showTimePicker(
             context: context,
             initialTime: TimeOfDay.fromDateTime(_selectedDate),
          );
          if (time != null) {
            setState(() {
              _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
            });
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(DateFormat('dd MMM yyyy, hh:mm a').format(_selectedDate)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingInvoice != null ? 'Edit Product Invoice #${widget.existingInvoice!.invoiceNumber}' : 'Create Product Invoice'),
        automaticallyImplyLeading: false, 
        actions: [
          if (widget.tabId != null)
             TextButton.icon(
              onPressed: () => context.read<TabProvider>().removeTab(widget.tabId!),
              icon: const Icon(Icons.close, color: Colors.black87),
              label: const Text('Close Tab', style: TextStyle(color: Colors.black87)),
            ),
          if (_items.isNotEmpty || _selectedCustomer != null)
            TextButton.icon(
              onPressed: _cleanForm,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1000) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: _buildDateSelector(),
                          ),
                          const SizedBox(height: 16),
                          CustomerSelector(
                            selectedCustomer: _selectedCustomer,
                            customers: context.watch<POSProvider>().customers,
                            onSelected: (c) {
                              setState(() => _selectedCustomer = c);
                              _checkMembership(c);
                            },
                          ),
                          const SizedBox(height: 32),
                          _buildItemsSection(),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Container(
                    width: 400,
                    padding: const EdgeInsets.all(32),
                    child: SingleChildScrollView(child: _buildSummaryPane()),
                  ),
                ],
              );
          } else {
             return SingleChildScrollView(
               padding: const EdgeInsets.all(16),
               child: Column(
                 children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomerSelector(
                            selectedCustomer: _selectedCustomer,
                            customers: context.watch<POSProvider>().customers,
                            onSelected: (c) {
                              setState(() => _selectedCustomer = c);
                              _checkMembership(c);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildDateSelector(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildItemsSection(),
                    const SizedBox(height: 24),
                    const Divider(),
                    _buildSummaryPane(),
                    const SizedBox(height: 60),
                 ],
               ),
             );
          }
        },
      ),
    );
  }

  Widget _buildSummaryPane() {
    return InvoiceSummaryPane(
      selectedCustomer: _selectedCustomer,
      subTotal: _subTotal,
      tax: _tax,
      discount: _billDiscount,
      discountInput: _billDiscountInput,
      isDiscountPercentage: _isBillDiscountPercentage,
      isReady: _items.isNotEmpty,
      paymentMode: _paymentMode,
      // Pass Advance Parameters
      availableAdvance: _selectedCustomer?.advanceBalance ?? 0,
      advanceAdjustedAmount: _advanceAdjustedAmount,
      onAdvanceAdjusted: (val) {
        setState(() {
          _advanceAdjustedAmount = val;
        });
        _calculateTotals();
      },
      onPaymentModeChanged: (val) => setState(() => _paymentMode = val),
      onSave: () => _submitInvoice(InvoiceStatus.active),
      onHold: () => _submitInvoice(InvoiceStatus.hold),
      onDiscountChanged: (val, isPercentage) {
        setState(() {
          _billDiscountInput = val;
          _isBillDiscountPercentage = isPercentage;
        });
        _calculateTotals();
      },
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Row(
              children: [
                Text('Tax Inclusive: ${_isTaxInclusive ? "Yes" : "No"}', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _showProductSelectionDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade50, foregroundColor: Colors.green),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_items.isEmpty)
          _buildEmptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _buildItemTile(index),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No products added', style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(int index) {
    final item = _items[index];
    return InvoiceItemTile(
      item: item,
      showQtyControls: true,
      onRemove: () {
        setState(() => _items.removeAt(index));
        _calculateTotals();
      },
      onChanged: (newItem) {
        setState(() {
          _items[index] = newItem;
        });
        _calculateTotals();
      },
    );
  }

  void _showProductSelectionDialog() {
    final products = context.read<POSProvider>().products;
    showDialog(
      context: context,
      builder: (context) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = products.where((p) => p.name.toLowerCase().contains(query.toLowerCase()) || p.sku.contains(query)).toList();
            return AlertDialog(
              title: const Text('Select Product'),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(hintText: 'Search by name or SKU...', prefixIcon: Icon(Icons.search)),
                      onChanged: (val) => setDialogState(() => query = val),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 400,
                      child: filtered.isEmpty 
                        ? const Center(child: Text('No products found'))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final p = filtered[index];
                              return ListTile(
                                title: Text(p.name),
                                subtitle: Text('Stock: ${p.stockQuantity.toInt()} units'),
                                trailing: Text('₹${p.price.toStringAsFixed(2)}'),
                                isThreeLine: true,
                                onTap: () {
                                  _addProductToInvoice(p);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _addProductToInvoice(Product p) {
    setState(() {
      final existingIndex = _items.indexWhere((item) => item.itemId == p.id);
      if (existingIndex != -1) {
        _items[existingIndex] = _items[existingIndex].copyWith(quantity: _items[existingIndex].quantity + 1);
      } else {
        _items.add(InvoiceItem(
          itemId: p.id!,
          itemType: 'PRODUCT',
          name: p.name,
          quantity: 1,
          rate: p.price,
          discount: 0,
          total: 0,
          hsnCode: p.hsnCode,
          gstRate: p.gstRate,
        ));
      }
      _calculateTotals();
    });
  }

  void _cleanForm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Invoice?'),
        content: const Text('Are you sure you want to clear all items and customer details?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedCustomer = null;
                _items.clear();
                _subTotal = 0;
                _tax = 0;
                _billDiscount = 0;
                _billDiscountInput = 0;
                _totalAmount = 0;
                _advanceAdjustedAmount = 0;
                _paymentMode = 'CASH';
              });
            },
            child: const Text('Yes, Clear'),
          ),
        ],
      ),
    );
  }

  void _submitInvoice(InvoiceStatus status) async {
    try {
      if (_selectedCustomer != null && _selectedCustomer!.id == null) {
        final newCustomer = await context.read<POSProvider>().addCustomer(_selectedCustomer!);
        setState(() {
          _selectedCustomer = newCustomer;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('New customer "${newCustomer.name}" created')));
      }

      final branchId = context.read<SettingsProvider>().currentBranchId;

      final invoice = Invoice(
        id: widget.existingInvoice?.id, // Preserve ID if editing
        invoiceNumber: widget.existingInvoice?.invoiceNumber ?? context.read<POSProvider>().generateInvoiceNumber(),
        customerId: _selectedCustomer?.id,
        branchId: branchId,
        type: InvoiceType.product,
        subTotal: _subTotal,
        taxAmount: _tax,
        discountAmount: _billDiscount,
        totalAmount: _totalAmount,
        advanceAdjustedAmount: _advanceAdjustedAmount,
        paymentMode: _paymentMode, 
        status: status,
        createdAt: _selectedDate,
        items: _items,
      );
      
      int? createdId;
      if (widget.existingInvoice != null) {
         await context.read<POSProvider>().updateInvoice(invoice);
         createdId = widget.existingInvoice!.id;
      } else {
         createdId = await context.read<POSProvider>().createInvoice(invoice);
      }
      
      if (mounted && createdId != null) {
        final tabProvider = context.read<TabProvider>();
        
        // Close the current tab (create/edit screen)
        if (widget.tabId != null) {
          tabProvider.removeTab(widget.tabId!);
        }

        // Open Invoice Details in a new tab (or replace current if we could, but we closed it)
        // Check if details tab exists? No, usually unique or generic. 
        // Let's assume we open a new tab "Invoice #Nr"
        
        final detailsTabId = 'invoice_details_$createdId';
        if (tabProvider.hasTab(detailsTabId)) {
          tabProvider.setActiveTab(detailsTabId);
        } else {
          tabProvider.addTab(
            TabItem(
              id: detailsTabId,
              title: 'Invoice #${invoice.invoiceNumber}',
              widget: InvoiceDetailsScreen(invoiceId: createdId), // Assuming ID ctor exists, let's verify
              type: TabType.invoiceDetails,
            ),
          );
        }

         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
           content: Text('Invoice ${status == InvoiceStatus.hold ? 'Held' : (widget.existingInvoice != null ? 'Updated' : 'Created')} Successfully'), 
           backgroundColor: status == InvoiceStatus.hold ? Colors.orange : Colors.green
         ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString().replaceAll("Exception:", "").trim()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ));
      }
    }
  }
}
