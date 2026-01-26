import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pos_models.dart';
import '../providers/pos_provider.dart';
import '../core/app_theme.dart';

class MembershipPlanFormDialog extends StatefulWidget {
  final MembershipPlan? plan;

  const MembershipPlanFormDialog({super.key, this.plan});

  @override
  State<MembershipPlanFormDialog> createState() => _MembershipPlanFormDialogState();
}

class _MembershipPlanFormDialogState extends State<MembershipPlanFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;
  late TextEditingController _discountValController;
  late TextEditingController _gstController;
  late TextEditingController _benefitsController;
  late TextEditingController _hsnController;
  
  String _selectedDiscountType = 'FLAT';
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.plan != null;
    _nameController = TextEditingController(text: widget.plan?.name ?? '');
    _priceController = TextEditingController(text: widget.plan?.price.toString() ?? '');
    _durationController = TextEditingController(text: widget.plan?.durationMonths.toString() ?? '');
    _discountValController = TextEditingController(text: widget.plan?.discountValue.toString() ?? '0.0');
    _gstController = TextEditingController(text: widget.plan?.gstRate.toString() ?? '18.0');
    _benefitsController = TextEditingController(text: widget.plan?.benefits ?? '');
    _hsnController = TextEditingController(text: widget.plan?.hsnCode ?? '');
    _selectedDiscountType = widget.plan?.discountType ?? 'FLAT';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _discountValController.dispose();
    _gstController.dispose();
    _benefitsController.dispose();
    _hsnController.dispose();
    super.dispose();
  }

  void _savePlan() {
    if (!_formKey.currentState!.validate()) return;

    final plan = MembershipPlan(
      id: widget.plan?.id,
      name: _nameController.text,
      price: double.tryParse(_priceController.text) ?? 0,
      durationMonths: int.tryParse(_durationController.text) ?? 0,
      discountType: _selectedDiscountType,
      discountValue: double.tryParse(_discountValController.text) ?? 0,
      gstRate: double.tryParse(_gstController.text) ?? 18,
      benefits: _benefitsController.text,
      hsnCode: _hsnController.text,
    );

    if (_isEdit) {
      context.read<POSProvider>().updateMembershipPlan(plan);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membership plan updated')));
    } else {
      context.read<POSProvider>().addMembershipPlan(plan);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membership plan added')));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
                   _isEdit ? 'Edit Membership Plan' : 'Add New Membership Plan',
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
                         label: 'Plan Name',
                         child: TextFormField(
                           controller: _nameController,
                           decoration: const InputDecoration(
                             hintText: 'e.g. Gold, Annual', 
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
                               label: 'Duration (Months)',
                               child: TextFormField(
                                 controller: _durationController,
                                 keyboardType: TextInputType.number,
                                 decoration: const InputDecoration(
                                   hintText: '12', 
                                   border: OutlineInputBorder(),
                                   contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                 ),
                                 validator: (val) => val == null || val.isEmpty ? 'Required' : null,
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
                               label: 'Discount Type',
                               child: DropdownButtonFormField<String>(
                                 value: _selectedDiscountType,
                                 decoration: const InputDecoration(
                                   border: OutlineInputBorder(),
                                   contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                 ),
                                 items: const [
                                   DropdownMenuItem(value: 'FLAT', child: Text('Flat (₹)')),
                                   DropdownMenuItem(value: 'PERCENTAGE', child: Text('Percentage (%)')),
                                 ],
                                 onChanged: (val) => setState(() => _selectedDiscountType = val!),
                               ),
                             ),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: _buildField(
                               label: 'Discount Value',
                               child: TextFormField(
                                 controller: _discountValController,
                                 keyboardType: TextInputType.number,
                                 decoration: const InputDecoration(
                                   hintText: '0.0', 
                                   border: OutlineInputBorder(),
                                   contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                 ),
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
                                label: 'HSN Code',
                                child: Consumer<POSProvider>(
                                  builder: (context, provider, child) {
                                    return Autocomplete<HsnCode>(
                                      initialValue: TextEditingValue(text: _hsnController.text),
                                      displayStringForOption: (HsnCode option) => option.code,
                                      optionsBuilder: (TextEditingValue textEditingValue) {
                                        if (textEditingValue.text == '') return const Iterable<HsnCode>.empty();
                                        return provider.hsnCodes.where((HsnCode option) => option.code.contains(textEditingValue.text));
                                      },
                                      onSelected: (HsnCode selection) {
                                        _hsnController.text = selection.code;
                                        _gstController.text = selection.gstRate.toString();
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
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildField(
                                label: 'GST Rate (%)',
                                child: TextFormField(
                                  controller: _gstController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: '18.0', 
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
                         label: 'Other Benefits',
                         child: TextFormField(
                           controller: _benefitsController,
                           maxLines: 3,
                           decoration: const InputDecoration(
                             hintText: 'Enter benefits...', 
                             border: OutlineInputBorder(),
                             contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                           ),
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
                   onPressed: _savePlan,
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
