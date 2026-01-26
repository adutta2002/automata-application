import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/pos_models.dart';
import '../../providers/pos_provider.dart';
import '../../providers/tab_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/app_theme.dart';
import '../../widgets/invoice/customer_selector.dart';
import '../../widgets/invoice/invoice_item_tile.dart';
import '../../widgets/invoice/invoice_summary_pane.dart';
import '../invoices_screen.dart';

class ServiceInvoiceScreen extends StatefulWidget {
  final String? tabId;
  final Invoice? existingInvoice;
  const ServiceInvoiceScreen({super.key, this.tabId, this.existingInvoice});

  @override
  State<ServiceInvoiceScreen> createState() => _ServiceInvoiceScreenState();
}

class _ServiceInvoiceScreenState extends State<ServiceInvoiceScreen> {
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

  // HSN-wise tax breakdown for display
  Map<String, HsnTaxBreakdown> _hsnBreakdown = {};

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _isTaxInclusive = settings.serviceTaxInclusive;

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
    _billDiscountInput = inv.discountAmount; 
    _paymentMode = inv.paymentMode ?? 'CASH';
    _advanceAdjustedAmount = inv.advanceAdjustedAmount;
    _isBillDiscountPercentage = false;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _calculateTotals();
    });
  }

  void _calculateTotals() {
    // ... (logic structure preserved) ...
    double tempSubTotal = 0;
    double tempTax = 0;
    
    // Step 1: Calculate base amounts for each item (without tax)
    List<InvoiceItem> updatedItems = [];
    
    // Group items by HSN code and calculate totals per HSN
    Map<String, double> hsnTotals = {}; // HSN -> total base amount
    Map<String, double> hsnGstRates = {}; // HSN -> GST rate
    Map<String, List<int>> hsnItemIndices = {}; // HSN -> item indices
    
    for (int i = 0; i < _items.length; i++) {
      var item = _items[i];
      double rate = item.rate;
      double quantity = item.quantity;
      double discount = item.discount;
      
      // Calculate line amount (before tax logic)
      double lineAmount = (rate * quantity) - discount;
      if (lineAmount < 0) lineAmount = 0;
      
      double itemBase = 0;
      if (_isTaxInclusive) {
        // Line Amount includes Tax - extract base
        double gstPercent = item.gstRate;
        itemBase = lineAmount / (1 + (gstPercent / 100));
      } else {
        // Line Amount is Base
        itemBase = lineAmount;
      }
      
      String hsn = item.hsnCode ?? 'NO_HSN';
      
      hsnTotals[hsn] = (hsnTotals[hsn] ?? 0) + itemBase;
      hsnGstRates[hsn] = item.gstRate; // All items with same HSN should have same GST rate
      hsnItemIndices[hsn] = [...(hsnItemIndices[hsn] ?? []), i];
      
      tempSubTotal += itemBase;
    }
    
    // Step 2: Calculate GST per HSN group
    _hsnBreakdown = {};
    
    for (var entry in hsnTotals.entries) {
      String hsn = entry.key;
      double hsnBaseTotal = entry.value;
      double gstRate = hsnGstRates[hsn] ?? 0;
      
      double hsnTax = hsnBaseTotal * (gstRate / 100);
      double cgst = hsnTax / 2;
      double sgst = hsnTax / 2;
      
      tempTax += hsnTax;
      
      _hsnBreakdown[hsn] = HsnTaxBreakdown(
        hsnCode: hsn == 'NO_HSN' ? 'Others' : hsn,
        baseAmount: hsnBaseTotal,
        gstRate: gstRate,
        cgst: cgst,
        sgst: sgst,
        totalTax: hsnTax,
      );
    }
    
    // Step 3: Distribute tax back to items proportionally within each HSN group
    for (var entry in hsnItemIndices.entries) {
      String hsn = entry.key;
      List<int> indices = entry.value;
      double hsnBaseTotal = hsnTotals[hsn]!;
      var breakdown = _hsnBreakdown[hsn]!;
      
      for (int i in indices) {
        var item = _items[i];
        double rate = item.rate;
        double quantity = item.quantity;
        double discount = item.discount;
        
        double lineAmount = (rate * quantity) - discount;
        if (lineAmount < 0) lineAmount = 0;
        
        double itemBase = 0;
        if (_isTaxInclusive) {
          double gstPercent = item.gstRate;
          itemBase = lineAmount / (1 + (gstPercent / 100));
        } else {
          itemBase = lineAmount;
        }
        
        // Proportional tax distribution
        double proportion = hsnBaseTotal > 0 ? (itemBase / hsnBaseTotal) : 0;
        double itemCgst = breakdown.cgst * proportion;
        double itemSgst = breakdown.sgst * proportion;
        double itemTax = itemCgst + itemSgst;
        double itemTotal = itemBase + itemTax;
        
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
          gstRate: item.gstRate,
          cgst: itemCgst,
          sgst: itemSgst,
          igst: 0,
        ));
      }
    }
    
    // Sort updated items to match original order
    updatedItems.sort((a, b) {
      int aIndex = _items.indexWhere((item) => item.itemId == a.itemId);
      int bIndex = _items.indexWhere((item) => item.itemId == b.itemId);
      return aIndex.compareTo(bIndex);
    });

    _items = updatedItems;
    _subTotal = tempSubTotal;
    _tax = tempTax;

    // Bill Discount
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
    
    // Check expiry
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
        title: Text(widget.existingInvoice != null ? 'Edit Service Invoice #${widget.existingInvoice!.invoiceNumber}' : 'Create Service Invoice'),
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
          bool isWide = constraints.maxWidth >= 1000;

          if (isWide) {
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
                            setState(() {
                              _selectedCustomer = c;
                              _advanceAdjustedAmount = 0;
                            });
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
             // Stacked View (Tablet/Mobile)
             return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
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
                            setState(() {
                              _selectedCustomer = c;
                              _advanceAdjustedAmount = 0;
                            });
                            _checkMembership(c);
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildItemsSection(),
                        const SizedBox(height: 24),
                        const Divider(),
                        _buildSummaryPane(),
                        const SizedBox(height: 60), // Space for fab or bottom actions if any
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

  Widget _summaryRow(String label, double value, {bool isBold = false, double? fontSize}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize)),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize ?? (isBold ? 24 : 14),
              color: isBold ? AppTheme.primaryColor : AppTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Row(
              children: [
                Text('Tax Inclusive: ${_isTaxInclusive ? "Yes" : "No"}', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _showServiceSelectionDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Service'),
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
            Icon(Icons.build_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No services added', style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(int index) {
    final item = _items[index];
    return InvoiceItemTile(
      item: item,
      showQtyControls: false,
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

  void _showServiceSelectionDialog() {
    final services = context.read<POSProvider>().services;
    showDialog(
      context: context,
      builder: (context) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = services.where((s) => s.name.toLowerCase().contains(query.toLowerCase())).toList();
            return AlertDialog(
              title: const Text('Select Service'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(hintText: 'Search services...', prefixIcon: Icon(Icons.search)),
                      onChanged: (val) => setDialogState(() => query = val),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: filtered.isEmpty 
                        ? const Center(child: Text('No services match'))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final s = filtered[index];
                              return ListTile(
                                title: Text(s.name),
                                subtitle: Text(
                                  'HSN: ${s.hsnCode ?? 'N/A'} | GST: ${s.gstRate.toStringAsFixed(0)}%',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                trailing: Text('₹${s.rate.toStringAsFixed(2)}'),
                                onTap: () {
                                  setState(() {
                                    _items.add(InvoiceItem(
                                      itemId: s.id!,
                                      itemType: 'SERVICE',
                                      name: s.name,
                                      quantity: 1,
                                      rate: s.rate,
                                      discount: 0,
                                      total: 0,
                                      hsnCode: s.hsnCode,
                                      gstRate: s.gstRate,
                                    ));
                                    _calculateTotals();
                                  });
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
                _hsnBreakdown.clear();
              });
            },
            child: const Text('Yes, Clear'),
          ),
        ],
      ),
    );
  }

  void _submitInvoice(InvoiceStatus status) async {
    if (_items.isEmpty) return;

    // Auto-create customer if needed
    if (_selectedCustomer != null && _selectedCustomer!.id == null) {
      final newCustomer = await context.read<POSProvider>().addCustomer(_selectedCustomer!);
      setState(() {
        _selectedCustomer = newCustomer;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('New customer "${newCustomer.name}" created')));
    }

    final branchId = context.read<SettingsProvider>().currentBranchId;

    final invoice = Invoice(
      id: widget.existingInvoice?.id,
      invoiceNumber: widget.existingInvoice?.invoiceNumber ?? context.read<POSProvider>().generateInvoiceNumber(),
      customerId: _selectedCustomer?.id,
      branchId: branchId,
      type: InvoiceType.service,
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
    
    if (widget.existingInvoice != null) {
       await context.read<POSProvider>().updateInvoice(invoice);
    } else {
       await context.read<POSProvider>().createInvoice(invoice);
    }
    
    if (mounted) {
       final tabProvider = context.read<TabProvider>();
       
       if (widget.tabId != null) {
         tabProvider.removeTab(widget.tabId!);
       }

       if (tabProvider.hasTab('invoices')) {
         tabProvider.setActiveTab('invoices');
       } else {
         tabProvider.addTab(
           TabItem(
             id: 'invoices',
             title: 'Invoices',
             widget: const InvoicesScreen(),
             type: TabType.invoices,
           ),
         );
       }
       
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
         content: Text('Invoice ${status == InvoiceStatus.hold ? 'Held' : (widget.existingInvoice != null ? 'Updated' : 'Created')} Successfully'), 
         backgroundColor: status == InvoiceStatus.hold ? Colors.orange : Colors.green
       ));
    }
  }
}
