import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/pos_models.dart';
import '../providers/pos_provider.dart';
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
    _selectedType = widget.hsn?.type ?? 'GOODS';
    _effectiveFrom = widget.hsn?.effectiveFrom;
    _effectiveTo = widget.hsn?.effectiveTo;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _rateController.dispose();
    super.dispose();
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
        width: 500,
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
                                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'GST Rate (%)',
                              child: TextFormField(
                                controller: _rateController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 18.0',
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
