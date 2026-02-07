import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/pos_models.dart';
import '../providers/pos_provider.dart';
import '../utils/validators.dart';
import '../core/app_theme.dart';

class HsnFormDialog extends StatefulWidget {
  final HsnCode? hsn;

  const HsnFormDialog({super.key, this.hsn});

  @override
  State<HsnFormDialog> createState() => _HsnFormDialogState();
}

class _HsnFormDialogState extends State<HsnFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _descriptionController;
  late TextEditingController _rateController;
  late TextEditingController _cgstController;
  late TextEditingController _sgstController;
  late TextEditingController _igstController;

  
  String _selectedType = 'GOODS';
  DateTime? _effectiveFrom;
  DateTime? _effectiveTo;
  bool _isEdit = false;
  final _dateFormatter = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _isEdit = widget.hsn != null;
    _codeController = TextEditingController(text: widget.hsn?.code ?? '');
    _descriptionController = TextEditingController(text: widget.hsn?.description ?? '');
    _rateController = TextEditingController(text: widget.hsn?.gstRate.toString() ?? '');
    
    _cgstController = TextEditingController(text: widget.hsn?.cgstRate.toString() ?? '');
    _sgstController = TextEditingController(text: widget.hsn?.sgstRate.toString() ?? '');
    _igstController = TextEditingController(text: widget.hsn?.igstRate.toString() ?? '');

    _selectedType = widget.hsn?.type ?? 'GOODS';
    _effectiveFrom = widget.hsn?.effectiveFrom;
    _effectiveTo = widget.hsn?.effectiveTo;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _rateController.dispose();
    _cgstController.dispose();
    _sgstController.dispose();
    _igstController.dispose();

    super.dispose();
  }

  void _onTotalRateChanged(String val) {
    final total = double.tryParse(val) ?? 0;
    final half = total / 2;
    _cgstController.text = half.toStringAsFixed(2);
    _sgstController.text = half.toStringAsFixed(2);
    _igstController.text = total.toStringAsFixed(2);
    // Cess remains as is or 0
  }

  void _onComponentRateChanged() {
    // Optional: Auto-calculate total if components change? 
    // For now let's keep it simple: Total drives components by default, but components can be edited manually.
    // If components are edited, maybe we should update total?
    final cgst = double.tryParse(_cgstController.text) ?? 0;
    final sgst = double.tryParse(_sgstController.text) ?? 0;
    final total = cgst + sgst;
    if (_rateController.text != total.toString()) {
       _rateController.text = total.toStringAsFixed(2);
       // IGST is NOT calculated from CGST+SGST as per user request
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _effectiveFrom : _effectiveTo) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _effectiveFrom = picked;
        } else {
          _effectiveTo = picked;
        }
      });
    }
  }

  void _saveHsn() {
    if (!_formKey.currentState!.validate()) return;

    final hsn = HsnCode(
      id: widget.hsn?.id,
      code: _codeController.text,
      description: _descriptionController.text,
      gstRate: double.tryParse(_rateController.text) ?? 0,
      cgstRate: double.tryParse(_cgstController.text) ?? 0,
      sgstRate: double.tryParse(_sgstController.text) ?? 0,
      igstRate: double.tryParse(_igstController.text) ?? 0,
      cessRate: 0.0, // CESS Removed
      type: _selectedType,
      effectiveFrom: _effectiveFrom,
      effectiveTo: _effectiveTo,
    );

    if (_isEdit) {
      context.read<POSProvider>().updateHsnCode(hsn);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('HSN/SAC updated')));
    } else {
      context.read<POSProvider>().addHsnCode(hsn);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('HSN/SAC added')));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
                         _isEdit ? 'Edit HSN/SAC Master' : 'New HSN/SAC Master',
                         style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                       ),
                       const SizedBox(height: 4),
                       const Text(
                         'Manage tax codes and GST rates',
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
                       // Section 1: Basic Info
                       _buildSectionHeader('HSN/SAC Details', Icons.description_outlined),
                       const SizedBox(height: 24),

                       Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Expanded(
                             flex: 2,
                             child: _buildField(
                               label: 'HSN/SAC Code',
                               isRequired: true,
                               child: TextFormField(
                                 controller: _codeController,
                                 decoration: _inputDecoration('Enter code', Icons.tag),
                                 validator: Validators.required,
                               ),
                             ),
                           ),
                           const SizedBox(width: 24),
                           Expanded(
                             flex: 1,
                             child: _buildField(
                               label: 'Type',
                               child: DropdownButtonFormField<String>(
                                 isExpanded: true,
                                 value: _selectedType,
                                 decoration: _inputDecoration('', Icons.category),
                                 items: const [
                                   DropdownMenuItem(value: 'GOODS', child: Text('Product (Goods)')),
                                   DropdownMenuItem(value: 'SERVICES', child: Text('Service')),
                                 ],
                                 onChanged: (val) => setState(() => _selectedType = val!),
                               ),
                             ),
                           ),
                           const SizedBox(width: 24),
                           Expanded(
                             flex: 1,
                             child: _buildField(
                               label: 'Total GST (%)',
                               isRequired: true,
                               child: TextFormField(
                                 controller: _rateController,
                                 keyboardType: TextInputType.number,
                                 decoration: _inputDecoration('18.0', Icons.percent),
                                 onChanged: _onTotalRateChanged,
                                 validator: (val) => Validators.required(val) ?? Validators.nonNegativeNumber(val),
                               ),
                             ),
                           ),
                         ],
                       ),
                       
                       const SizedBox(height: 24),
                       
                       // Section 2: Tax Breakdown
                       _buildSectionHeader('Tax Breakdown (Configurable)', Icons.pie_chart_outline),
                       const SizedBox(height: 24),

                       Container(
                         padding: const EdgeInsets.all(20),
                         decoration: BoxDecoration(
                           color: Colors.grey.shade50,
                           borderRadius: BorderRadius.circular(12),
                           border: Border.all(color: Colors.grey.shade200),
                         ),
                         child: Row(
                           children: [
                             Expanded(
                               child: _buildField(
                                 label: 'CGST %',
                                 child: TextFormField(
                                   controller: _cgstController,
                                   keyboardType: TextInputType.number,
                                   onChanged: (_) => _onComponentRateChanged(),
                                   decoration: _inputDecoration('0', Icons.percent).copyWith(fillColor: Colors.white),
                                 ),
                               ),
                             ),
                             const SizedBox(width: 16),
                             Expanded(
                               child: _buildField(
                                 label: 'SGST %',
                                 child: TextFormField(
                                   controller: _sgstController,
                                   keyboardType: TextInputType.number,
                                   onChanged: (_) => _onComponentRateChanged(),
                                   decoration: _inputDecoration('0', Icons.percent).copyWith(fillColor: Colors.white),
                                 ),
                               ),
                             ),
                             const SizedBox(width: 16),
                             Expanded(
                               child: _buildField(
                                 label: 'IGST %',
                                 child: TextFormField(
                                   controller: _igstController,
                                   keyboardType: TextInputType.number,
                                   decoration: _inputDecoration('0', Icons.percent).copyWith(fillColor: Colors.white),
                                 ),
                               ),
                             ),
                           ],
                         ),
                       ),

                       const SizedBox(height: 32),
                       
                       // Section 3: Additional Info
                       _buildSectionHeader('Additional Information', Icons.info_outline),
                       const SizedBox(height: 24),

                       _buildField(
                         label: 'Description',
                         child: TextFormField(
                           controller: _descriptionController,
                           maxLines: 2,
                           decoration: _inputDecoration('Enter short description', Icons.description),
                         ),
                       ),
                       const SizedBox(height: 24),
                       
                       Row(
                         children: [
                           Expanded(
                             child: _buildField(
                               label: 'Effective From',
                               child: InkWell(
                                 onTap: () => _selectDate(context, true),
                                 child: Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                   decoration: BoxDecoration(
                                     border: Border.all(color: Colors.grey.shade300),
                                     borderRadius: BorderRadius.circular(8),
                                     color: Colors.white,
                                   ),
                                   child: Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       Text(
                                         _effectiveFrom != null ? _dateFormatter.format(_effectiveFrom!) : 'Select Date',
                                         style: TextStyle(color: _effectiveFrom != null ? AppTheme.textColor : Colors.grey.shade400, fontSize: 14),
                                       ),
                                       Icon(Icons.calendar_today, color: Colors.grey.shade400, size: 20),
                                     ],
                                   ),
                                 ),
                               ),
                             ),
                           ),
                           const SizedBox(width: 24),
                           Expanded(
                             child: _buildField(
                               label: 'Effective To',
                               child: InkWell(
                                 onTap: () => _selectDate(context, false),
                                 child: Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                   decoration: BoxDecoration(
                                     border: Border.all(color: Colors.grey.shade300),
                                     borderRadius: BorderRadius.circular(8),
                                     color: Colors.white,
                                   ),
                                   child: Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       Text(
                                         _effectiveTo != null ? _dateFormatter.format(_effectiveTo!) : 'Select Date',
                                         style: TextStyle(color: _effectiveTo != null ? AppTheme.textColor : Colors.grey.shade400, fontSize: 14),
                                       ),
                                       Icon(Icons.calendar_today, color: Colors.grey.shade400, size: 20),
                                     ],
                                   ),
                                 ),
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
                     onPressed: _saveHsn,
                     icon: const Icon(Icons.check, size: 18),
                     label: Text(_isEdit ? 'Update Details' : 'Save Details'),
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
