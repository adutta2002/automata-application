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
  });

  @override
  State<InvoiceItemTile> createState() => _InvoiceItemTileState();
}

class _InvoiceItemTileState extends State<InvoiceItemTile> {
  late TextEditingController _discountCtrl;
  final FocusNode _discountFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _discountCtrl = TextEditingController(
      text: widget.item.discount == 0 ? '' : widget.item.discount.toString(),
    );
    // Listen to focus changes if needed, but onChanged handles immediate updates.
  }

  @override
  void didUpdateWidget(InvoiceItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the discount value changed externally and it's NOT what is currently in the text field, update it.
    // This handles scenarios where logic might reset discount, but we guard against cursor jumps while typing.
    final parsed = double.tryParse(_discountCtrl.text) ?? 0;
    if (widget.item.discount != parsed && !_discountFocus.hasFocus) {
       _discountCtrl.text = widget.item.discount == 0 ? '' : widget.item.discount.toString();
    }
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    _discountFocus.dispose();
    super.dispose();
  }

  void _onDiscountChanged(String val) {
    final d = double.tryParse(val) ?? 0;
    // Notify parent immediately. Parent will rebuild tile.
    // didUpdateWidget will see the new value matches parsed value -> No text update -> Cursor stable.
    widget.onChanged(widget.item.copyWith(discount: d));
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

            // Item Discount Input
            SizedBox(
              width: 80,
              child: TextField(
                controller: _discountCtrl,
                focusNode: _discountFocus,
                decoration: const InputDecoration(
                  labelText: 'Disc.',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                onChanged: _onDiscountChanged,
              ),
            ),
            const SizedBox(width: 16),
            
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
                  if (widget.item.discount > 0)
                    Text(
                      '-₹${widget.item.discount.toStringAsFixed(0)} disc',
                      style: const TextStyle(fontSize: 10, color: Colors.green),
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
