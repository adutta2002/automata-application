import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pos_models.dart';
import '../providers/pos_provider.dart';
import '../core/app_theme.dart';

class ProductFormDialog extends StatefulWidget {
  final Product? product;

  const ProductFormDialog({super.key, this.product});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _hsnController;
  
  double _selectedGst = 0;
  final _gstRates = [0.0, 5.0, 12.0, 18.0, 28.0];
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.product != null;
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _skuController = TextEditingController(text: widget.product?.sku ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stockQuantity.toString() ?? '');
    _hsnController = TextEditingController(text: widget.product?.hsnCode ?? '');
    _selectedGst = widget.product?.gstRate ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _hsnController.dispose();
    super.dispose();
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final product = Product(
      id: widget.product?.id,
      name: _nameController.text,
      sku: _skuController.text,
      barcode: _skuController.text,
      price: double.tryParse(_priceController.text) ?? 0,
      stockQuantity: double.tryParse(_stockController.text) ?? 0,
      hsnCode: _hsnController.text,
      gstRate: _selectedGst,
      unit: widget.product?.unit ?? 'Unit',
      category: widget.product?.category ?? 'General',
    );

    try {
      if (_isEdit) {
        await context.read<POSProvider>().updateProduct(product);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product updated')));
      } else {
        await context.read<POSProvider>().addProduct(product);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added')));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hsnCodes = context.read<POSProvider>().hsnCodes;

    return Dialog(
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
       child: Container(
         width: 700,
         padding: const EdgeInsets.all(24),
         decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(16),
         ),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(
                   _isEdit ? 'Edit Product' : 'Add New Product',
                   style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                 ),
                 IconButton(
                   onPressed: () => Navigator.pop(context),
                   icon: const Icon(Icons.close),
                 ),
               ],
             ),
             const Divider(height: 32),
             Flexible(
               child: SingleChildScrollView(
                 child: Form(
                   key: _formKey,
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       _buildField(
                         label: 'Product Name',
                         child: TextFormField(
                           controller: _nameController,
                           decoration: const InputDecoration(
                             hintText: 'Enter product name', 
                             border: OutlineInputBorder(),
                             contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                           ),
                           validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                         ),
                       ),
                       const SizedBox(height: 16),
                       Row(
                         children: [
                           Expanded(
                             child: _buildField(
                               label: 'SKU / Barcode',
                               child: TextFormField(
                                 controller: _skuController,
                                 decoration: const InputDecoration(
                                   hintText: 'Enter SKU', 
                                   border: OutlineInputBorder(),
                                   contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                 ),
                               ),
                             ),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: _buildField(
                               label: 'HSN Code',
                               child: Autocomplete<HsnCode>(
                                 initialValue: TextEditingValue(text: _hsnController.text),
                                 displayStringForOption: (HsnCode option) => option.code,
                                 optionsBuilder: (TextEditingValue textEditingValue) {
                                   if (textEditingValue.text == '') return const Iterable<HsnCode>.empty();
                                   return hsnCodes.where((HsnCode option) => option.code.contains(textEditingValue.text) && option.type == 'GOODS');
                                 },
                                 onSelected: (HsnCode selection) {
                                    _hsnController.text = selection.code;
                                    setState(() {
                                      if (_gstRates.contains(selection.gstRate)) {
                                        _selectedGst = selection.gstRate;
                                      }
                                    });
                                 },
                                 fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                                   if (textEditingController.text.isEmpty && _hsnController.text.isNotEmpty) {
                                     textEditingController.text = _hsnController.text;
                                   }
                                   return TextFormField(
                                     controller: textEditingController,
                                     focusNode: focusNode,
                                     decoration: const InputDecoration(
                                        hintText: 'Search HSN', 
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                     ),
                                     onChanged: (val) => _hsnController.text = val,
                                   );
                                 },
                               ),
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 16),
                       Row(
                         children: [
                           Expanded(
                             child: _buildField(
                               label: 'Price (₹)',
                               child: TextFormField(
                                 controller: _priceController,
                                 keyboardType: TextInputType.number,
                                 decoration: const InputDecoration(
                                   hintText: '0.00', 
                                   border: OutlineInputBorder(),
                                   contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                 ),
                                 validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                               ),
                             ),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: _buildField(
                               label: 'Stock Quantity',
                               child: TextFormField(
                                 controller: _stockController,
                                 keyboardType: TextInputType.number,
                                 decoration: const InputDecoration(
                                   hintText: '0', 
                                   border: OutlineInputBorder(),
                                   contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                 ),
                               ),
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 16),
                       _buildField(
                         label: 'GST Rate',
                         child: DropdownButtonFormField<double>(
                           value: _gstRates.contains(_selectedGst) ? _selectedGst : 0.0,
                           decoration: const InputDecoration(
                             border: OutlineInputBorder(),
                             contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                           ),
                           items: _gstRates.map((r) => DropdownMenuItem(value: r, child: Text('${r.toInt()}%'))).toList(),
                           onChanged: (val) => setState(() => _selectedGst = val!),
                         ),
                       ),
                     ],
                   ),
                 ),
               ),
             ),
             const SizedBox(height: 24),
             Row(
               mainAxisAlignment: MainAxisAlignment.end,
               children: [
                 TextButton(
                   onPressed: () => Navigator.pop(context),
                   child: const Text('Cancel'),
                 ),
                 const SizedBox(width: 16),
                 ElevatedButton(
                   onPressed: _saveProduct,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppTheme.primaryColor,
                     foregroundColor: Colors.white,
                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                   ),
                   child: Text(_isEdit ? 'Update' : 'Save'),
                 ),
               ],
             ),
           ],
         ),
       ),
    );
  }

  Widget _buildField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
