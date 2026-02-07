import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pos_models.dart';
import '../providers/pos_provider.dart';
import '../utils/validators.dart';
import '../core/app_theme.dart';

class ServiceFormDialog extends StatefulWidget {
  final Service? service;

  const ServiceFormDialog({super.key, this.service});

  @override
  State<ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _rateController;
  late TextEditingController _hsnController;
  
  double _selectedGst = 0;
  final _gstRates = [0.0, 5.0, 12.0, 18.0, 28.0];
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.service != null;
    _nameController = TextEditingController(text: widget.service?.name ?? '');
    _descriptionController = TextEditingController(text: widget.service?.description ?? '');
    _rateController = TextEditingController(text: widget.service?.rate.toString() ?? '');
    _hsnController = TextEditingController(text: widget.service?.hsnCode ?? '');
    _selectedGst = widget.service?.gstRate ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _rateController.dispose();
    _hsnController.dispose();
    super.dispose();
  }

  void _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    final service = Service(
      id: widget.service?.id,
      name: _nameController.text,
      description: _descriptionController.text,
      rate: double.tryParse(_rateController.text) ?? 0,
      hsnCode: _hsnController.text,
      gstRate: _selectedGst,
    );

    try {
      if (_isEdit) {
        await context.read<POSProvider>().updateService(service);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service updated')));
      } else {
        await context.read<POSProvider>().addService(service);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service added')));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hsnCodes = context.read<POSProvider>().hsnCodes;
    
    // Auto-set GST based on SAC logic
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
                         _isEdit ? 'Edit Service Master' : 'New Service Master',
                         style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                       ),
                       const SizedBox(height: 4),
                       const Text(
                         'Manage service details and pricing',
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
                       // Section 1: Basic Information
                       _buildSectionHeader('Service Details', Icons.miscellaneous_services_outlined),
                       const SizedBox(height: 24),
                       
                       Row(
                         children: [
                           Expanded(
                             child: _buildField(
                               label: 'Service Name',
                               isRequired: true,
                               child: TextFormField(
                                 controller: _nameController,
                                 decoration: _inputDecoration('Enter service name', Icons.cleaning_services),
                                 validator: Validators.required,
                               ),
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 24),
                       
                       // Section 2: Pricing & Tax
                       _buildSectionHeader('Pricing & Tax', Icons.monetization_on_outlined),
                       const SizedBox(height: 24),

                       Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Expanded(
                             flex: 2,
                             child: _buildField(
                               label: 'Rate (₹)',
                               isRequired: true,
                               child: TextFormField(
                                 controller: _rateController,
                                 keyboardType: TextInputType.number,
                                 decoration: _inputDecoration('0.00', Icons.currency_rupee),
                                 validator: Validators.positiveNumber,
                               ),
                             ),
                           ),
                           const SizedBox(width: 24),
                           Expanded(
                             flex: 2,
                             child: _buildField(
                               label: 'SAC / HSN Code',
                               isRequired: true,
                               child: Autocomplete<HsnCode>(
                                 initialValue: TextEditingValue(text: _hsnController.text),
                                 displayStringForOption: (HsnCode option) => option.code,
                                 optionsBuilder: (TextEditingValue textEditingValue) {
                                   if (textEditingValue.text == '') return const Iterable<HsnCode>.empty();
                                   return hsnCodes.where((HsnCode option) => option.code.contains(textEditingValue.text) && option.type == 'SERVICES');
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
                                     decoration: _inputDecoration('Search SAC', Icons.search),
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
                             flex: 1,
                             child: _buildField(
                               label: 'GST Rate',
                               child: DropdownButtonFormField<double>(
                                 isExpanded: true,
                                 value: _gstRates.contains(_selectedGst) ? _selectedGst : 0.0,
                                 decoration: _inputDecoration('', Icons.percent).copyWith(
                                    filled: true,
                                    fillColor: Colors.grey.shade100, // Explicitly disabled look
                                    helperText: 'Auto-set',
                                 ),
                                 items: _gstRates.map((r) => DropdownMenuItem(
                                   value: r, 
                                   child: Text('${r.toInt()}%', style: const TextStyle(fontWeight: FontWeight.w500)),
                                 )).toList(),
                                 onChanged: null, // Read-only
                               ),
                             ),
                           ),
                         ],
                       ),

                       const SizedBox(height: 24),

                       _buildField(
                         label: 'Description',
                         child: TextFormField(
                           controller: _descriptionController,
                           maxLines: 3,
                           decoration: _inputDecoration('Enter service description (optional)', Icons.description_outlined),
                         ),
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
                     onPressed: _saveService,
                     icon: const Icon(Icons.check, size: 18),
                     label: Text(_isEdit ? 'Update Service' : 'Save Service'),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(26), // Approx 0.1 opacity
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title, 
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor)
        ),
      ],
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
