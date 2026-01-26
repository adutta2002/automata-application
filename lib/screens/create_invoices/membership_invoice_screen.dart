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
import '../invoices_screen.dart';
import '../invoice_details_screen.dart';

class MembershipInvoiceScreen extends StatefulWidget {
  final String? tabId;
  final Invoice? existingInvoice;
  const MembershipInvoiceScreen({super.key, this.tabId, this.existingInvoice});

  @override
  State<MembershipInvoiceScreen> createState() => _MembershipInvoiceScreenState();
}

class _MembershipInvoiceScreenState extends State<MembershipInvoiceScreen> {
  Customer? _selectedCustomer;
  MembershipPlan? _selectedPlan;
  
  double _billDiscount = 0;
  double _billDiscountInput = 0;
  bool _isBillDiscountPercentage = false;
  String _paymentMode = 'CASH';
  
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
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
    
    // Find selected plan
    try {
      if (inv.items.isNotEmpty) {
         final itemId = inv.items.first.itemId;
         _selectedPlan = context.read<POSProvider>().membershipPlans.firstWhere((p) => p.id == itemId);
      }
    } catch (_) {}

    _selectedDate = inv.createdAt;
    _billDiscountInput = inv.discountAmount; // Assuming flat
    _billDiscount = inv.discountAmount;
    _paymentMode = inv.paymentMode ?? 'CASH';
    _isBillDiscountPercentage = false;
  }

  void _calculateTotal() {
    if (_selectedPlan == null) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingInvoice != null ? 'Edit Membership #${widget.existingInvoice!.invoiceNumber}' : 'New Membership Registration'),
        automaticallyImplyLeading: false,
        actions: [
          if (widget.tabId != null)
             TextButton.icon(
              onPressed: () => context.read<TabProvider>().removeTab(widget.tabId!),
              icon: const Icon(Icons.close, color: Colors.black87),
              label: const Text('Close Tab', style: TextStyle(color: Colors.black87)),
            ),
          if (_selectedCustomer != null || _selectedPlan != null)
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
                          onSelected: (c) => setState(() => _selectedCustomer = c),
                        ),
                        const SizedBox(height: 32),
                        _buildPlanSelection(),
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: _buildDateSelector(),
                    ),
                    const SizedBox(height: 16),
                    CustomerSelector(
                      selectedCustomer: _selectedCustomer,
                      customers: context.watch<POSProvider>().customers,
                      onSelected: (c) => setState(() => _selectedCustomer = c),
                    ),
                    const SizedBox(height: 24),
                    _buildPlanSelection(),
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

  Widget _buildPlanSelection() {
    final plans = context.watch<POSProvider>().membershipPlans;

    if (plans.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Column(
            children: [
              const Text('No membership plans defined.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () { 
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Go to Settings > Manage Membership Plans to add plans.')));
                },
                child: const Text('Add Plans in Settings'),
              )
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Membership Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            childAspectRatio: 1.1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            final isSelected = _selectedPlan?.id == plan.id;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPlan = plan;
                  _calculateTotal();
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(plan.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? AppTheme.primaryColor : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (plan.discountValue > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                            child: Text('${plan.discountType == 'FLAT' ? '₹' : ''}${plan.discountValue}${plan.discountType == 'PERCENTAGE' ? '%' : ''} OFF', style: TextStyle(fontSize: 10, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${plan.durationMonths} Months', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        plan.benefits.isNotEmpty ? plan.benefits : 'No specific benefits listed.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tax: ${plan.gstRate}%', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            const Text('Price', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                        Text('₹${plan.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryPane() {
    double subTotal = _selectedPlan?.price ?? 0;
    double gstRate = _selectedPlan?.gstRate ?? 18.0;
    
    double taxable = subTotal - _billDiscount;
    if (taxable < 0) taxable = 0;
    
    double tax = taxable * (gstRate / 100);

    return InvoiceSummaryPane(
      selectedCustomer: _selectedCustomer,
      subTotal: subTotal,
      tax: tax,
      discount: _billDiscount,
      discountInput: _billDiscountInput,
      isDiscountPercentage: _isBillDiscountPercentage,
      isReady: _selectedCustomer != null && _selectedPlan != null,
      paymentMode: _paymentMode,
      onPaymentModeChanged: (val) => setState(() => _paymentMode = val),
      onSave: () => _submitMembership(InvoiceStatus.active),
      onHold: () => _submitMembership(InvoiceStatus.hold),
      onDiscountChanged: (val, isPercentage) {
         setState(() {
          _billDiscountInput = val;
          _isBillDiscountPercentage = isPercentage;
        });
        _calculateTotal();
      },
    );
  }

  void _cleanForm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Membership?'),
        content: const Text('Are you sure you want to clear the form?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedCustomer = null;
                _selectedPlan = null;
                _billDiscount = 0;
                _billDiscountInput = 0;
                _paymentMode = 'CASH';
              });
            },
            child: const Text('Yes, Clear'),
          ),
        ],
      ),
    );
  }

  void _submitMembership(InvoiceStatus status) async {
    if (_selectedPlan == null) return;

    // Auto-create customer if needed
    if (_selectedCustomer != null && _selectedCustomer!.id == null) {
      final newCustomer = await context.read<POSProvider>().addCustomer(_selectedCustomer!);
      setState(() {
        _selectedCustomer = newCustomer;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('New customer "${newCustomer.name}" created')));
    }

    final branchId = context.read<SettingsProvider>().currentBranchId;

    double price = _selectedPlan!.price;
    double gstRate = _selectedPlan!.gstRate;
    
    double taxable = price - _billDiscount;
    if (taxable < 0) taxable = 0;
    
    final tax = taxable * (gstRate / 100);
    final total = taxable + tax;

    final invoice = Invoice(
      id: widget.existingInvoice?.id,
      invoiceNumber: widget.existingInvoice?.invoiceNumber ?? context.read<POSProvider>().generateInvoiceNumber(),
      customerId: _selectedCustomer?.id,
      branchId: branchId, 
      type: InvoiceType.membership,
      subTotal: price,
      taxAmount: tax,
      discountAmount: _billDiscount,
      totalAmount: total,
      paymentMode: _paymentMode,
      status: status,
      createdAt: _selectedDate,
      items: [
        InvoiceItem(
          itemId: _selectedPlan!.id ?? 0, 
          itemType: 'MEMBERSHIP',
          name: '${_selectedPlan!.name} - ${_selectedPlan!.durationMonths} Months',
          hsnCode: _selectedPlan!.hsnCode,
          quantity: 1,
          rate: price,
          total: price,
          gstRate: gstRate,
          cgst: tax / 2,
          sgst: tax / 2,
        )
      ],
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
       
       if (widget.tabId != null) {
         tabProvider.removeTab(widget.tabId!);
       }

       final detailsTabId = 'invoice_details_$createdId';
       if (tabProvider.hasTab(detailsTabId)) {
         tabProvider.setActiveTab(detailsTabId);
       } else {
         tabProvider.addTab(
           TabItem(
             id: detailsTabId,
             title: 'Invoice #${invoice.invoiceNumber}',
             widget: InvoiceDetailsScreen(invoiceId: createdId),
             type: TabType.invoiceDetails,
           ),
         );
       }

       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
         content: Text('Membership ${status == InvoiceStatus.hold ? 'Held' : (widget.existingInvoice != null ? 'Updated' : 'Created')} Successfully'), 
         backgroundColor: status == InvoiceStatus.hold ? Colors.orange : Colors.green
       ));
    }
  }
}
