import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/pos_models.dart';
import '../providers/pos_provider.dart';
import '../providers/auth_provider.dart';
import '../core/app_theme.dart';
import '../providers/settings_provider.dart';
import '../services/export_service.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'dart:typed_data';
import '../providers/tab_provider.dart';
import 'create_invoices/service_invoice_screen.dart';
import 'create_invoices/product_invoice_screen.dart';
import 'create_invoices/advance_invoice_screen.dart';
import 'create_invoices/membership_invoice_screen.dart';

class InvoiceDetailsScreen extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDetailsScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<POSProvider>().customers.firstWhere(
      (c) => c.id == invoice.customerId,
      orElse: () => Customer(name: 'Walk-in Customer', phone: 'N/A', email: '', address: '', createdAt: DateTime.now()),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Invoice #${invoice.invoiceNumber}'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textColor,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: OutlinedButton.icon(
              onPressed: () => _handlePreview(context),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Preview Layout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: () => _handlePrint(context),
              icon: const Icon(Icons.print, size: 18),
              label: const Text('Print / Download'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),

          if (invoice.status == InvoiceStatus.hold) ...[
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton.icon(
                onPressed: () => _handleEdit(context),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit Invoice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT PANE: Items (Takes remaining space)
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Expanded(child: _buildItemsCard()), // Make items card take full height
                ],
              ),
            ),
             
            const SizedBox(width: 24),

            // RIGHT PANE: Summary Sidebar
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildStatusBanner(),
                  const SizedBox(height: 12),
                  
                  // Scrollable Middle Section (Customer + Details)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildCard(
                            title: 'Customer Details',
                            icon: Icons.person_outline,
                            child: _buildCustomerContent(customer),
                          ),
                          const SizedBox(height: 12),
                          _buildCard(
                            title: 'Invoice Details', 
                            icon: Icons.receipt_long_outlined,
                            child: _buildMetaContent(context),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  
                  // Fixed Bottom Section (Totals)
                  _buildTotalsCard(),
                  
                  if (invoice.status == InvoiceStatus.cancelled) ...[
                    const SizedBox(height: 12),
                    _buildCancellationCard(),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    MaterialColor color;
    String text;
    IconData icon;

    switch (invoice.status) {
      case InvoiceStatus.active:
        color = Colors.green;
        text = 'Active Invoice';
        icon = Icons.check_circle_outline;
        break;
      case InvoiceStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled Invoice';
        icon = Icons.cancel_outlined;
        break;
      case InvoiceStatus.hold:
        color = Colors.orange;
        text = 'Invoice On Hold';
        icon = Icons.pause_circle_outline;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.shade600,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
           BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 text,
                 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
               ),
               Text(
                 'Created on ${DateFormat('dd MMM yyyy, hh:mm a').format(invoice.createdAt)}',
                 style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
               ),
             ],
           ),
           Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
             child: Icon(icon, color: Colors.white, size: 28),
           )
        ],
      ),
    );
  }

  Widget _buildCustomerContent(Customer customer) {
    final name = customer.name.isNotEmpty ? customer.name : 'Unknown Customer';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(initial, style: TextStyle(color: AppTheme.primaryColor)),
                  radius: 20,
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                     if (customer.phone.isNotEmpty)
                        Text(customer.phone, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                   ],
                 ),
               )
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          
          if (customer.email.isNotEmpty) ...[
             _buildDetailRow(Icons.email_outlined, customer.email),
             const SizedBox(height: 8),
          ],
            
          if (customer.address.isNotEmpty) ...[
            _buildDetailRow(Icons.location_on_outlined, customer.address),
            const SizedBox(height: 8),
          ],
          
          _buildDetailRow(Icons.info_outline, 'Type: ${customer.membershipPlanId != null ? "Member" : "Regular"}'),
        ],
    );
  }

  Widget _buildMetaContent(BuildContext context) {
    final branch = context.read<POSProvider>().getBranchById(invoice.branchId);
    return Column(
      children: [
        _buildMetaRow('Invoice #', invoice.invoiceNumber, isBold: true),
        _buildMetaRow('Type', invoice.type.name.toUpperCase()),
        _buildMetaRow('Branch', branch?.name ?? 'Main Branch'),
        if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
          const Divider(),
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Row(children: [Icon(Icons.note_alt_outlined, size: 16, color: Colors.grey), SizedBox(width: 8), Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))]),
          ),
          Text(invoice.notes!, style: const TextStyle(fontStyle: FontStyle.italic)),
        ]
      ],
    );
  }

  Widget _buildItemsCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Purchased Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            
            // Table Header
            Row(
              children: const [
                Expanded(flex: 4, child: Text('ITEM', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))),
                Expanded(flex: 1, child: Text('QTY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))),
                Expanded(flex: 2, child: Text('RATE', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))),
                Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))),
              ],
            ),
            const Divider(),
            
            // Scrollable List
            Expanded(
              child: ListView.separated(
                itemCount: invoice.items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                   final item = invoice.items[index];
                   final base = item.rate * item.quantity - item.discount;
                   return Padding(
                     padding: const EdgeInsets.symmetric(vertical: 12),
                     child: Row(
                       children: [
                         Expanded(
                           flex: 4,
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                               if(item.gstRate > 0)
                                 Text('${item.itemType} | GST ${item.gstRate.toInt()}%', style: TextStyle(fontSize: 11, color: Colors.grey.shade600))
                             ],
                           ),
                         ),
                         Expanded(flex: 1, child: Text(item.quantity.toStringAsFixed(0))),
                         Expanded(flex: 2, child: Text('₹${item.rate.toStringAsFixed(2)}', textAlign: TextAlign.right)),
                         Expanded(flex: 2, child: Text('₹${base.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
                       ],
                     ),
                   );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard() {
    return _buildCard(
      title: 'Payment Summary',
      icon: Icons.payments_outlined,
      child: Column(
        children: [
           _buildSummaryRow('Subtotal', invoice.subTotal),
           _buildSummaryRow('Tax (GST)', invoice.taxAmount),
           _buildSummaryRow('Discount', invoice.discountAmount, isNegative: true),
           const Divider(height: 32),
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
               Text('₹${invoice.totalAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppTheme.primaryColor)),
             ],
           ),
           const SizedBox(height: 12),
           Container(
             width: double.infinity,
             padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
             decoration: BoxDecoration(
               color: Colors.blue.shade50,
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: Colors.blue.shade100),
             ),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Text('Paid Via', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                 Text(invoice.paymentMode ?? 'CASH', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
               ],
             ),
           ),

           if (invoice.advanceAdjustedAmount > 0) ...[
             const SizedBox(height: 16),
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   const Text('Advance Adjusted', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                   Text('- ₹${invoice.advanceAdjustedAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                 ],
               ),
             )
           ],
        ],
      ),
    );
  }

  Widget _buildCancellationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 8), Text('Cancellation Reason', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16))]),
          const SizedBox(height: 8),
          Text(invoice.cancellationReason ?? 'No reason provided.', style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  // Helpers
  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, size: 20, color: Colors.grey), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade700))),
      ],
    );
  }

  Widget _buildMetaRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            '${isNegative ? "- " : ""}₹${value.toStringAsFixed(2)}', 
            style: TextStyle(fontWeight: FontWeight.w600, color: isNegative ? Colors.red : Colors.black)
          ),
        ],
      ),
    );
  }

  Widget _buildTaxBreakdown() {
     if (invoice.taxAmount <= 0) return const SizedBox.shrink();
     
     // Aggregate Tax by Rate
     Map<double, double> taxMap = {};
     for (var item in invoice.items) {
       taxMap[item.gstRate] = (taxMap[item.gstRate] ?? 0) + (item.cgst + item.sgst);
     }
     
     return Container(
       margin: const EdgeInsets.only(top: 8),
       padding: const EdgeInsets.all(12),
       decoration: BoxDecoration(
         color: Colors.grey.shade50,
         borderRadius: BorderRadius.circular(8),
         border: Border.all(color: Colors.grey.shade200),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           const Text('Tax Analysis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
           const SizedBox(height: 8),
           ...taxMap.entries.map((e) {
             return Padding(
               padding: const EdgeInsets.symmetric(vertical: 2),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text('GST ${e.key.toInt()}%', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                   Text('₹${e.value.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                 ],
               ),
             );
           }),
         ],
       ),
     );
  }

  void _handlePreview(BuildContext context) {
    final exportService = ExportService();
    final provider = context.read<POSProvider>();
    final branch = provider.getBranchById(invoice.branchId);
    final printerType = context.read<SettingsProvider>().printerType;
    final cashierName = context.read<AuthProvider>().currentUser?.fullName;

    showDialog(
      context: context,
      builder: (ctx) {
        final size = MediaQuery.of(ctx).size;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: size.width * 0.8,
            height: size.height * 0.9,
            padding: const EdgeInsets.all(16),
            child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Invoice Preview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              Expanded(
                child: PdfPreview(
                  build: (format) async {
                     final path = await exportService.generateInvoicePDF(
                        invoice,
                        branch: branch,
                        cashierName: cashierName,
                        printerType: printerType,
                     );
                     return File(path).readAsBytes();
                  },
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  allowSharing: false,
                  allowPrinting: true,
                  initialPageFormat: printerType == 'A4' ? PdfPageFormat.a4 : PdfPageFormat.roll80,
                  maxPageWidth: printerType == 'A4' ? 700 : 350,
                  pdfPreviewPageDecoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(2, 2))],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      },
    );
  }

  void _handlePrint(BuildContext context) async {
    final exportService = ExportService();
    final provider = context.read<POSProvider>();
    final branch = provider.getBranchById(invoice.branchId);
    final printerType = context.read<SettingsProvider>().printerType;
    final cashierName = context.read<AuthProvider>().currentUser?.fullName;

    await Printing.layoutPdf(
      onLayout: (format) async {
        final path = await exportService.generateInvoicePDF(
          invoice,
          branch: branch,
          cashierName: cashierName,
          printerType: printerType,
        );
        return File(path).readAsBytes();
      },
      name: 'Invoice_${invoice.invoiceNumber}',
    );
  }

  void _handleEdit(BuildContext context) {
    // Navigate to Create Screen with existing invoice
    // This requires us to use the TabProvider to open the screen in a new tab (or reuse)
    // We map InvoiceType to the Screen Widget and Tab details
    
    final tabId = 'edit_${invoice.invoiceNumber}';
    Widget screen;
    String title;
    
    switch (invoice.type) {
      case InvoiceType.service: 
        screen = ServiceInvoiceScreen(tabId: tabId, existingInvoice: invoice); 
        title = 'Edit Service Inv';
        break;
      case InvoiceType.product: 
        screen = ProductInvoiceScreen(tabId: tabId, existingInvoice: invoice); 
        title = 'Edit Product Inv';
        break;
      case InvoiceType.advance: 
        screen = AdvancePaymentScreen(tabId: tabId, existingInvoice: invoice); 
        title = 'Edit Advance';
        break;
      case InvoiceType.membership: 
        screen = MembershipInvoiceScreen(tabId: tabId, existingInvoice: invoice); 
        title = 'Edit Membership';
        break;
    }

    // Close details screen first? Or keep it open? 
    // Usually better to close details or just push the tab.
    // If we are in the "Invoices" tab, we can just add a new tab.
    
    context.read<TabProvider>().addTab(
      TabItem(
        id: tabId,
        title: title,
        widget: screen,
        type: _TypeToTabType(invoice.type),
      ),
    );
    
    // Check if we can switch to that tab automatically. 
    // The TabProvider usually notifies listeners, but the main layout might need to switch index.
    // Assuming the main scaffold listens to tab changes and switches.
    // However, if we are in a modal or pushed route (InvoiceDetailsScreen), we might need to pop.
    Navigator.pop(context); 
  }

  TabType _TypeToTabType(InvoiceType type) {
    switch (type) {
      case InvoiceType.service: return TabType.serviceInvoice;
      case InvoiceType.product: return TabType.productInvoice;
      case InvoiceType.advance: return TabType.advance;
      case InvoiceType.membership: return TabType.membership;
    }
  }
}
