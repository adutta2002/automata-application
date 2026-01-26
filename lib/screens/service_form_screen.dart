import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pos_models.dart';
import '../providers/pos_provider.dart';
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

  void _saveService() {
    if (!_formKey.currentState!.validate()) return;

    final service = Service(
      id: widget.service?.id,
      name: _nameController.text,
      description: _descriptionController.text,
      rate: double.tryParse(_rateController.text) ?? 0,
      hsnCode: _hsnController.text,
      gstRate: _selectedGst,
    );

    if (_isEdit) {
      context.read<POSProvider>().updateService(service);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service updated')));
    } else {
      context.read<POSProvider>().addService(service);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service added')));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final hsnCodes = context.read<POSProvider>().hsnCodes;

    return Dialog(
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
       child: Container(
         width: 600,
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
                   _isEdit ? 'Edit Service' : 'Add New Service',
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
                         label: 'Service Name',
                         child: TextFormField(
                           controller: _nameController,
                           decoration: const InputDecoration(
                             hintText: 'Enter service name', 
                             border: OutlineInputBorder(),
                             contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                           ),
                           validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                         ),
                       ),
                       const SizedBox(height: 16),
                       _buildField(
                         label: 'Description',
                         child: TextFormField(
                           controller: _descriptionController,
                           maxLines: 2,
                           decoration: const InputDecoration(
                             hintText: 'Enter description', 
                             border: OutlineInputBorder(),
                             contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                           ),
                         ),
                       ),
                       const SizedBox(height: 16),
                       Row(
                         children: [
                           Expanded(
                             child: _buildField(
                               label: 'Rate (₹)',
                               child: TextFormField(
                                 controller: _rateController,
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
                               label: 'SAC Code (HSN)',
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
                                     decoration: const InputDecoration(
                                        hintText: 'Search SAC', 
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
                   onPressed: _saveService,
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
