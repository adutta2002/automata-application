import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pos_models.dart';
import '../providers/pos_provider.dart';
import '../utils/validators.dart';
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
  late TextEditingController _mrpController; // New MRP Field
  
  double _selectedGst = 0;
  final _gstRates = [0.0, 5.0, 12.0, 18.0, 28.0];
  bool _isEdit = false;
  
  // New Fields State
  bool _isStockTracking = true;
  String _selectedCategory = 'General';
  String _selectedUnit = 'PCS';

  final List<String> _categories = ['General', 'Grocery', 'Electronics', 'Apparel', 'Pharma', 'Others'];
  final List<String> _units = ['PCS', 'KG', 'LTR', 'BOX', 'PACK', 'DOZEN'];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.product != null;
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _skuController = TextEditingController(text: widget.product?.sku ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stockQuantity.toString() ?? '0');
    _hsnController = TextEditingController(text: widget.product?.hsnCode ?? '');
    _mrpController = TextEditingController(text: widget.product?.mrp.toString() ?? '');
    _selectedGst = widget.product?.gstRate ?? 0;
    _isStockTracking = widget.product?.isStockTracking ?? true;
    _selectedCategory = widget.product?.category ?? 'General';
    _selectedUnit = widget.product?.unit ?? 'PCS';

    // Ensure category/unit are valid defaults
    if (!_categories.contains(_selectedCategory)) _categories.add(_selectedCategory);
    if (!_units.contains(_selectedUnit)) _units.add(_selectedUnit);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _hsnController.dispose();
    _mrpController.dispose();
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
      stockQuantity: _isStockTracking ? (double.tryParse(_stockController.text) ?? 0) : 0,
      hsnCode: _hsnController.text,
      gstRate: _selectedGst,
      unit: _selectedUnit,
      category: _selectedCategory,
      mrp: double.tryParse(_mrpController.text) ?? 0,
      isStockTracking: _isStockTracking,
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
    
    // Auto-set GST based on HSN logic
    try {
      final matchingHsn = hsnCodes.firstWhere(
        (h) => h.code.trim().toLowerCase() == _hsnController.text.trim().toLowerCase(),
      );
      if (_gstRates.contains(matchingHsn.gstRate)) {
        if (_selectedGst != matchingHsn.gstRate) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedGst = matchingHsn.gstRate);
           });
        }
      }
    } catch (_) {}

    final screenSize = MediaQuery.of(context).size;

    return Dialog(
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
       backgroundColor: Colors.white,
       elevation: 8,
       insetPadding: const EdgeInsets.all(16),
       child: Container(
         width: screenSize.width > 900 ? 900 : screenSize.width * 0.95,
         constraints: BoxConstraints(maxHeight: screenSize.height * 0.9),
         child: Column(
           children: [
             // Header with Gradient
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
               decoration: BoxDecoration(
                 gradient: LinearGradient(
                   colors: [AppTheme.primaryColor.withAlpha(20), Colors.white],
                   begin: Alignment.topCenter,
                   end: Alignment.bottomCenter,
                 ),
                 borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                 border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         _isEdit ? 'Edit Product Master' : 'New Product Master',
                         style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                       ),
                       const SizedBox(height: 4),
                       const Text(
                         'Enter product details properly for accurate inventory',
                         style: TextStyle(fontSize: 14, color: Colors.grey),
                       ),
                     ],
                   ),
                   IconButton(
                     onPressed: () => Navigator.pop(context),
                     icon: const Icon(Icons.close, color: Colors.grey),
                     style: IconButton.styleFrom(
                       backgroundColor: Colors.white,
                       hoverColor: Colors.grey.shade100,
                     ),
                   ),
                 ],
               ),
             ),

             Expanded(
               child: SingleChildScrollView(
                 padding: const EdgeInsets.all(32),
                 child: Form(
                   key: _formKey,
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       // ROW 1: Name & Category
                       Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Expanded(
                             flex: 2,
                             child: _buildField(
                               label: 'Product Name',
                               isRequired: true,
                               child: TextFormField(
                                 controller: _nameController,
                                 decoration: _inputDecoration('Enter product name', Icons.inventory_2_outlined),
                                 validator: Validators.required,
                               ),
                             ),
                           ),
                           const SizedBox(width: 24),
                           Expanded(
                             flex: 1,
                             child: _buildField(
                               label: 'Category',
                               isRequired: true,
                               child: DropdownButtonFormField<String>(
                                 isExpanded: true,
                                 value: _selectedCategory,
                                 decoration: _inputDecoration('', Icons.category_outlined),
                                 items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                 onChanged: (val) => setState(() => _selectedCategory = val!),
                               ),
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 24),

                       // ROW 2: SKU & Maintain Stock
                       Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Expanded(
                             flex: 2,
                             child: _buildField(
                               label: 'SKU / Barcode',
                               child: TextFormField(
                                 controller: _skuController,
                                 decoration: _inputDecoration('Scan or enter', Icons.qr_code_scanner),
                               ),
                             ),
                           ),
                           const SizedBox(width: 24),
                           Expanded(
                             flex: 1,
                             child: Padding(
                               padding: const EdgeInsets.only(top: 28), // Align with input
                               child: CheckboxListTile(
                                 title: const Text('Maintain Stock', style: TextStyle(fontWeight: FontWeight.w600)),
                                 value: _isStockTracking,
                                 activeColor: AppTheme.primaryColor,
                                 contentPadding: EdgeInsets.zero,
                                 controlAffinity: ListTileControlAffinity.leading,
                                 onChanged: (val) => setState(() => _isStockTracking = val!),
                               ),
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 24),

                       // ROW 3: Stock & Unit (Conditional)
                       if (_isStockTracking) ...[
                         Row(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Expanded(
                               child: _buildField(
                                 label: 'Stock Quantity',
                                 child: TextFormField(
                                   controller: _stockController,
                                   keyboardType: TextInputType.number,
                                   decoration: _inputDecoration('0', Icons.warehouse_outlined),
                                   validator: Validators.nonNegativeNumber,
                                 ),
                               ),
                             ),
                             const SizedBox(width: 24),
                             Expanded(
                               child: _buildField(
                                 label: 'Unit',
                                 child: DropdownButtonFormField<String>(
                                   value: _selectedUnit,
                                   decoration: _inputDecoration('', Icons.scale_outlined),
                                   items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                                   onChanged: (val) => setState(() => _selectedUnit = val!),
                                 ),
                               ),
                             ),
                           ],
                         ),
                         const SizedBox(height: 24),
                       ],

                       // ROW 4: HSN & GST
                       Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Expanded(
                             child: _buildField(
                               label: 'HSN Code',
                               isRequired: true,
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
                                     decoration: _inputDecoration('Search HSN', Icons.search),
                                     onChanged: (val) {
                                       _hsnController.text = val;
                                       setState(() {}); 
                                     },
                                   );
                                 },
                               ),
                             ),
                           ),
                           const SizedBox(width: 24),
                           Expanded(
                             child: _buildField(
                               label: 'GST Rate (auto)',
                               child: DropdownButtonFormField<double>(
                                 value: _gstRates.contains(_selectedGst) ? _selectedGst : 0.0,
                                 decoration: _inputDecoration('', Icons.percent).copyWith(
                                    filled: true,
                                    fillColor: Colors.grey.shade100, // Explicitly disabled look
                                 ),
                                 items: _gstRates.map((r) => DropdownMenuItem(
                                   value: r, 
                                   child: Text('${r.toInt()}% GST', style: const TextStyle(fontWeight: FontWeight.w500)),
                                 )).toList(),
                                 onChanged: null, // Read-only
                               ),
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 24),

                       // ROW 5: MRP & Selling Price
                       Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Expanded(
                             child: _buildField(
                               label: 'MRP (₹)',
                               isRequired: true,
                               child: TextFormField(
                                 controller: _mrpController,
                                 keyboardType: TextInputType.number,
                                 decoration: _inputDecoration('0.00', Icons.sell_outlined),
                                 validator: Validators.positiveNumber,
                               ),
                             ),
                           ),
                           const SizedBox(width: 24),
                           Expanded(
                             child: _buildField(
                               label: 'Selling Price (₹)',
                               isRequired: true,
                               child: TextFormField(
                                 controller: _priceController,
                                 keyboardType: TextInputType.number,
                                 decoration: _inputDecoration('0.00', Icons.currency_rupee),
                                 validator: Validators.positiveNumber,
                               ),
                             ),
                           ),
                         ],
                       ),

                     ],
                   ),
                 ),
               ),
             ),

             // Footer
             Container(
               padding: const EdgeInsets.all(24),
               decoration: BoxDecoration(
                 color: Colors.grey.shade50,
                 borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                 border: Border(top: BorderSide(color: Colors.grey.shade200)),
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.end,
                 children: [
                   OutlinedButton(
                     onPressed: () => Navigator.pop(context),
                     style: OutlinedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                       side: BorderSide(color: Colors.grey.shade300),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     ),
                     child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                   ),
                   const SizedBox(width: 16),
                   ElevatedButton.icon(
                     onPressed: _saveProduct,
                     icon: const Icon(Icons.check, size: 18),
                     label: Text(_isEdit ? 'Update Product' : 'Save Product'),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppTheme.primaryColor,
                       foregroundColor: Colors.white,
                       elevation: 2,
                       padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                     ),
                   ),
                 ],
               ),
             ),
           ],
         ),
       ),
    );
  }

  Widget _buildField({required String label, required Widget child, bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textColor)),
            if (isRequired)
              Text(' *', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
    );
  }
}
