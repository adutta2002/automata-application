import 'package:flutter/material.dart';
import '../../models/pos_models.dart';
import '../../core/app_theme.dart';

class InvoiceItemTile extends StatefulWidget {
  final InvoiceItem item;
  final ValueChanged<InvoiceItem> onChanged; // Parent handles recalculation
  final VoidCallback onRemove;
  final bool showQtyControls;

  const InvoiceItemTile({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onRemove,
    this.showQtyControls = false,
    this.isRateEditable = false,
    this.showRateEditor = false,
    this.onRateChanged,
  });

  final bool isRateEditable;
  final bool showRateEditor;
  final ValueChanged<String>? onRateChanged;

  @override
  State<InvoiceItemTile> createState() => _InvoiceItemTileState();
}

class _InvoiceItemTileState extends State<InvoiceItemTile> {
  late TextEditingController _rateCtrl;
  final FocusNode _rateFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _rateCtrl = TextEditingController(text: widget.item.rate.toString());
  }

  @override
  void didUpdateWidget(InvoiceItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.rate != double.tryParse(_rateCtrl.text) && !_rateFocus.hasFocus) {
      _rateCtrl.text = widget.item.rate.toString();
    }
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    _rateFocus.dispose();
    super.dispose();
  }

  void _onQtyChanged(double newQty) {
    if (newQty < 1) return;
    widget.onChanged(widget.item.copyWith(quantity: newQty));
  }

  @override
  Widget build(BuildContext context) {
    // Calculate base amount (before tax) for display
    final baseAmount = (widget.item.rate * widget.item.quantity) - widget.item.discount;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      // If Rate Editor is NOT shown in main row, show it here as text
                      if (!widget.showRateEditor)
                        Text(
                          '₹${widget.item.rate.toStringAsFixed(2)}',
                          style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 12),
                        ),
                      if (widget.item.gstRate > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'GST ${widget.item.gstRate.toInt()}%',
                            style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
                          ),
                        ),
                        // Added Tax Amount Display
                        const SizedBox(width: 4),
                        Text(
                          '(₹${(widget.item.cgst + widget.item.sgst).toStringAsFixed(2)})',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        ),
                      ],
                      if (widget.item.hsnCode != null && widget.item.hsnCode!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          'HSN: ${widget.item.hsnCode}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            if (widget.showQtyControls) ...[
              Row(
                children: [
                  InkWell(
                    onTap: () => _onQtyChanged(widget.item.quantity - 1),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.remove, color: Colors.red, size: 18),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(widget.item.quantity.toInt().toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(width: 8),
                   InkWell(
                    onTap: () => _onQtyChanged(widget.item.quantity + 1),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: Colors.green, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
            ] else 
              const SizedBox.shrink(),

            if (widget.showRateEditor) ...[
               SizedBox(
                width: 80,
                child: TextField(
                  enabled: widget.isRateEditable,
                  controller: _rateCtrl,
                  focusNode: _rateFocus,
                  decoration: const InputDecoration(
                    labelText: 'Rate',
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: widget.onRateChanged,
                ),
              ),
              const SizedBox(width: 16),
            ],
            
            // Amount (before tax)
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${baseAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            
            IconButton(
              onPressed: widget.onRemove,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
