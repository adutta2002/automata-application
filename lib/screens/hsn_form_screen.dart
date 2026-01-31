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
  late TextEditingController _cessController;
  
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
    _cessController = TextEditingController(text: widget.hsn?.cessRate.toString() ?? '');

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
    _cessController.dispose();
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
       _igstController.text = total.toStringAsFixed(2); // Usually IGST is sum of CGST+SGST
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
      cessRate: double.tryParse(_cessController.text) ?? 0,
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600, // Slightly wider
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEdit ? 'Edit HSN/SAC' : 'Add New HSN/SAC',
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
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'HSN/SAC Code',
                              child: TextFormField(
                                controller: _codeController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter code',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                validator: Validators.required,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'Total GST Rate (%)',
                              child: TextFormField(
                                controller: _rateController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 18.0',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  suffixText: '%',
                                ),
                                onChanged: _onTotalRateChanged,
                                validator: (val) => Validators.required(val) ?? Validators.nonNegativeNumber(val),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Configurable Split Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             const Text('Tax Breakdown (Configurable)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo)),
                             const SizedBox(height: 12),
                             Row(
                               children: [
                                 Expanded(
                                   child: _buildField(
                                     label: 'CGST %',
                                     child: TextFormField(
                                       controller: _cgstController,
                                       keyboardType: TextInputType.number,
                                       onChanged: (_) => _onComponentRateChanged(),
                                       decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), isDense: true),
                                     ),
                                   ),
                                 ),
                                 const SizedBox(width: 8),
                                 Expanded(
                                   child: _buildField(
                                     label: 'SGST %',
                                     child: TextFormField(
                                       controller: _sgstController,
                                       keyboardType: TextInputType.number,
                                       onChanged: (_) => _onComponentRateChanged(),
                                       decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), isDense: true),
                                     ),
                                   ),
                                 ),
                                 const SizedBox(width: 8),
                                 Expanded(
                                   child: _buildField(
                                     label: 'IGST %',
                                     child: TextFormField(
                                       controller: _igstController,
                                       keyboardType: TextInputType.number,
                                       decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), isDense: true),
                                     ),
                                   ),
                                 ),
                                 const SizedBox(width: 8),
                                 Expanded(
                                   child: _buildField(
                                     label: 'CESS %',
                                     child: TextFormField(
                                       controller: _cessController,
                                       keyboardType: TextInputType.number,
                                       decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), isDense: true),
                                     ),
                                   ),
                                 ),
                               ],
                             ),
                           ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      _buildField(
                        label: 'Type',
                        child: DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'GOODS', child: Text('Product (Goods)')),
                            DropdownMenuItem(value: 'SERVICES', child: Text('Service')),
                          ],
                          onChanged: (val) => setState(() => _selectedType = val!),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        label: 'Description',
                        child: TextFormField(
                          controller: _descriptionController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'Enter short description',
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
                              label: 'Effective From',
                              child: InkWell(
                                onTap: () => _selectDate(context, true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_effectiveFrom != null ? _dateFormatter.format(_effectiveFrom!) : 'Select Date'),
                                      const Icon(Icons.calendar_today, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'Effective To',
                              child: InkWell(
                                onTap: () => _selectDate(context, false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_effectiveTo != null ? _dateFormatter.format(_effectiveTo!) : 'Select Date'),
                                      const Icon(Icons.calendar_today, size: 16),
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
                  onPressed: _saveHsn,
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
