import 'package:flutter/material.dart';
import '../../models/pos_models.dart';
import '../../core/app_theme.dart';

class CustomerSelector extends StatefulWidget {
  final Customer? selectedCustomer;
  final List<Customer> customers;
  final Function(Customer?) onSelected;

  const CustomerSelector({
    super.key,
    required this.selectedCustomer,
    required this.customers,
    required this.onSelected,
  });

  @override
  State<CustomerSelector> createState() => _CustomerSelectorState();
}

class _CustomerSelectorState extends State<CustomerSelector> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // We keep track if the form is manually being edited to avoid overwriting invalid user input
  // when the parent re-builds vs when we actively select a customer.
  bool _isManuallyEditing = false;

  @override
  void didUpdateWidget(covariant CustomerSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCustomer != oldWidget.selectedCustomer && !_isManuallyEditing) {
      _populateForm(widget.selectedCustomer);
    }
  }

  @override
  void initState() {
    super.initState();
    _populateForm(widget.selectedCustomer);
  }

  void _populateForm(Customer? c) {
    if (c != null) {
      if (_nameCtrl.text != c.name) _nameCtrl.text = c.name;
      if (_phoneCtrl.text != c.phone) _phoneCtrl.text = c.phone;
      if (_emailCtrl.text != c.email) _emailCtrl.text = c.email;
      if (_addressCtrl.text != c.address) _addressCtrl.text = c.address;
    } else {
      // Only clear if we are not manually editing, or force clear if needed?
      // If parent explicitly sets to null, we should probably clear.
      // But we need to distinguish "parent cleared" vs "initial state".
      // Let's assume if the new selectedCustomer is NULL, we clear.
      if (_nameCtrl.text.isNotEmpty) _nameCtrl.clear();
      if (_phoneCtrl.text.isNotEmpty) _phoneCtrl.clear();
      if (_emailCtrl.text.isNotEmpty) _emailCtrl.clear();
      if (_addressCtrl.text.isNotEmpty) _addressCtrl.clear();
    }
  }

  void _onFormChanged() {
    _isManuallyEditing = true;
    final customer = Customer(
      id: null, // Always treat manual edits as a new/unlinked customer entry
      name: _nameCtrl.text,
      phone: _phoneCtrl.text,
      email: _emailCtrl.text,
      address: _addressCtrl.text,
      createdAt: DateTime.now(),
    );
    
    widget.onSelected(customer); 
    _isManuallyEditing = false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchField(),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildForm(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<Customer>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<Customer>.empty();
            }
            final query = textEditingValue.text.toLowerCase();
            return widget.customers.where((c) => 
              c.name.toLowerCase().contains(query) || c.phone.contains(query)
            );
          },
          displayStringForOption: (Customer option) => '${option.name} (${option.phone})',
          onSelected: (Customer selection) {
            _isManuallyEditing = false;
            widget.onSelected(selection);
            // Form is populated via didUpdateWidget -> _populateForm
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Search Customer by Name or Phone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                filled: true,
                fillColor: AppTheme.primaryColor.withOpacity(0.04),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: constraints.maxWidth,
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(option.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(option.phone),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name', isDense: true, border: OutlineInputBorder()),
                onChanged: (_) => _onFormChanged(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone', isDense: true, border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                onChanged: (_) => _onFormChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email', isDense: true, border: OutlineInputBorder()),
                 onChanged: (_) => _onFormChanged(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Address', isDense: true, border: OutlineInputBorder()),
                 onChanged: (_) => _onFormChanged(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
