import 'package:flutter/material.dart';
import '../../models/pos_models.dart';
import '../../core/app_theme.dart';

class InvoiceSummaryPane extends StatefulWidget {
  final Customer? selectedCustomer;
  final double subTotal;
  final double cgst;
  final double sgst;
  final double igst;
  final double tax;
  final double discount;
  final bool isReady;
  final double availableAdvance;
  final double advanceAdjustedAmount;
  final Function(double)? onAdvanceAdjusted;
  final VoidCallback onSave;
  final Function(double, bool) onDiscountChanged;
  final List<HsnTaxBreakdown>? taxBreakdown;
  final double discountInput; 
  final bool isDiscountPercentage;
  final String paymentMode;
  final Function(String) onPaymentModeChanged;

  const InvoiceSummaryPane({
    super.key,
    this.selectedCustomer,
    required this.subTotal,
    required this.tax, // Total Tax
    this.cgst = 0,
    this.sgst = 0,
    this.igst = 0,
    this.taxBreakdown,
    required this.discountInput,
    required this.isDiscountPercentage,
    required this.discount,
    required this.isReady,
    required this.onSave,
    required this.onDiscountChanged,
    this.availableAdvance = 0,
    this.advanceAdjustedAmount = 0,
    this.onAdvanceAdjusted,
    this.paymentMode = 'CASH',
    required this.onPaymentModeChanged,
    this.onHold,
  });

  final VoidCallback? onHold;

  @override
  State<InvoiceSummaryPane> createState() => _InvoiceSummaryPaneState();
}

class _InvoiceSummaryPaneState extends State<InvoiceSummaryPane> {
  final _discountCtrl = TextEditingController();
  bool _isPercentage = false;

  @override
  void initState() {
    super.initState();
    _discountCtrl.text = '0';
  }

  @override
  void didUpdateWidget(InvoiceSummaryPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.discountInput != oldWidget.discountInput || widget.isDiscountPercentage != oldWidget.isDiscountPercentage) {
       _discountCtrl.text = widget.discountInput == 0 ? '0' : widget.discountInput.toStringAsFixed(widget.isDiscountPercentage ? 0 : 2);
       if (widget.isDiscountPercentage != _isPercentage) {
          _isPercentage = widget.isDiscountPercentage;
       }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Total calculation: Subtotal - BillDiscount + Tax - AdvanceAdjustment
    final total = widget.subTotal + widget.tax - widget.discount - widget.advanceAdjustedAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ... (Existing Header and Customer Card - Unchanged) ...
        const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        const SizedBox(height: 24),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6), 
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.indigo.withOpacity(0.1)),
          ),
          child: widget.selectedCustomer != null 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BILLING TO', 
                    style: TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.w600, 
                      color: Colors.indigo, 
                      letterSpacing: 1.2
                    )
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.selectedCustomer!.name, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)
                  ),
                  const SizedBox(height: 4),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.selectedCustomer!.phone, 
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14)
                      ),
                      if (widget.selectedCustomer!.advanceBalance > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Adv: ₹${widget.selectedCustomer!.advanceBalance.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green.shade800),
                          ),
                        ),
                    ],
                  ),
                ],
              )
            : const Center(
                child: Text('No Customer Selected', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ),
        ),
        
        const SizedBox(height: 32),
        
        // Subtotal
        _summaryRow('Subtotal', widget.subTotal),
        const SizedBox(height: 12),
        
        // Bill Discount
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Bill Discount', style: TextStyle(fontSize: 15, color: Colors.black87)),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 36,
                  child: TextField(
                    controller: _discountCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.indigo)),
                    ),
                    onChanged: (val) {
                      final v = double.tryParse(val) ?? 0;
                      widget.onDiscountChanged(v, _isPercentage);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 36,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    children: [
                      _buildToggleButton('%', _isPercentage),
                      _buildToggleButton('₹', !_isPercentage),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        // NEW: Advance Adjustment Row
        if (widget.availableAdvance > 0) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: widget.advanceAdjustedAmount > 0,
                onChanged: (val) {
                  if (val == true) {
                     // Auto-fill with max possible amount when checked (optional, but helpful)
                     double maxAdjust = widget.availableAdvance;
                     double currentTotal = widget.subTotal + widget.tax - widget.discount;
                     if (maxAdjust > currentTotal) maxAdjust = currentTotal;
                     widget.onAdvanceAdjusted?.call(maxAdjust);
                  } else {
                     widget.onAdvanceAdjusted?.call(0);
                  }
                },
              ),
              const Text('Adjust from Advance', style: TextStyle(fontSize: 15, color: Colors.green)),
              const Spacer(),
              if (widget.advanceAdjustedAmount > 0)
                SizedBox(
                  width: 140,
                  height: 36,
                  child: TextField(
                    controller: TextEditingController(text: widget.advanceAdjustedAmount.toStringAsFixed(2))
                      ..selection = TextSelection.fromPosition(TextPosition(offset: widget.advanceAdjustedAmount.toStringAsFixed(2).length)),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.end,
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                    onChanged: (val) {
                      final v = double.tryParse(val) ?? 0;
                      widget.onAdvanceAdjusted?.call(v);
                    },
                  ),
                ),
            ],
          ),
        ],

        const SizedBox(height: 24),

        // Tax Breakdown
        const Text('Tax Breakdown', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
        const Divider(height: 24),
        
        if (widget.taxBreakdown != null && widget.taxBreakdown!.isNotEmpty) ...[
          ...widget.taxBreakdown!.map((bd) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${bd.hsnCode}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  Text(
                    '₹${bd.totalTax.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }),
        ] else if (widget.tax > 0) ...[
           _summaryRow('Tax', widget.tax, fontSize: 13, color: Colors.grey.shade700),
        ] else ...[
           const Text('No tax applied', style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic)),
        ],

        const Divider(height: 32),
        
        // Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Text(
              '₹${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5C5CFF), // Bright Blue-Purple from screenshot
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        
        // Payment Mode
        const Text('Payment Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildPaymentModeChip('CASH', Icons.money),
            const SizedBox(width: 8),
            _buildPaymentModeChip('UPI', Icons.qr_code),
            const SizedBox(width: 8),
            _buildPaymentModeChip('CARD', Icons.credit_card),
          ],
        ),

        const SizedBox(height: 24),
        
        // Save Button
        // Save Button
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.isReady ? widget.onHold : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.orange.shade700),
                  foregroundColor: Colors.orange.shade800,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('HOLD INVOICE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: widget.isReady ? widget.onSave : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: const Text(
                  'SAVE & PRINT', 
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _isPercentage = text == '%';
          });
          // Re-trigger calculation
           final v = double.tryParse(_discountCtrl.text) ?? 0;
           widget.onDiscountChanged(v, _isPercentage);
        }
      },
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0E0FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.indigo : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isBold = false, double? fontSize, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize ?? 15, color: color ?? Colors.black87)),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize ?? (isBold ? 24 : 15),
              color: color ?? (isBold ? AppTheme.primaryColor : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentModeChip(String mode, IconData icon) {
    final isSelected = widget.paymentMode == mode;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onPaymentModeChanged(mode),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(icon, size: 20, color: isSelected ? Colors.white : AppTheme.primaryColor),
                const SizedBox(height: 4),
                Text(
                  mode,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
