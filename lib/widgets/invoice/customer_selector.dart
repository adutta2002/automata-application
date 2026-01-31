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
  // We need Controllers for Email/Address as they are simple text fields
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // For Autocomplete, we manage the text via the provided controllers in fieldViewBuilder,
  // but we store the current text to sync between fields if needed or to Create New.
  String _currentName = '';
  String _currentPhone = '';
  
  // To avoid recursive updates when selecting
  bool _isInternalUpdate = false;

  @override
  void didUpdateWidget(covariant CustomerSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCustomer != oldWidget.selectedCustomer && !_isInternalUpdate) {
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
      _currentName = c.name;
      _currentPhone = c.phone;
      if (_emailCtrl.text != c.email) _emailCtrl.text = c.email;
      if (_addressCtrl.text != c.address) _addressCtrl.text = c.address;
    } else {
      _currentName = '';
      _currentPhone = '';
      _emailCtrl.clear();
      _addressCtrl.clear();
    }
    // Note: Autocomplete text controllers are updated via key/rebuild or external control 
    // but RawAutocomplete makes it hard to externally set text without a controller.
    // For simplicity, we rely on the parent rebuilding this widget or Key based updates 
    // if we really need to force reset. However, keeping it simple:
    // If we receive a new customer from parent, we want the visible fields to update.
    // The easiest way with standard Autocomplete is to use a unique Key when the external selection changes 
    // if the selection is significantly different.
    // Alternatively, we use TextEditingControllers for the Autocomplete fields too.
  }

  // Helper to notify parent of changes (treated as New/Manual Customer)
  void _notifyChange({String? name, String? phone, String? email, String? address}) {
    _isInternalUpdate = true; // Prevent internal loop
    
    final newName = name ?? _currentName;
    final newPhone = phone ?? _currentPhone;
    final newEmail = email ?? _emailCtrl.text;
    final newAddress = address ?? _addressCtrl.text;

    // Update local state
    _currentName = newName;
    _currentPhone = newPhone;

    widget.onSelected(Customer(
      id: null, // New/Modified is always null ID until saved
      name: newName,
      phone: newPhone,
      email: newEmail,
      address: newAddress,
      createdAt: DateTime.now(),
    ));

    _isInternalUpdate = false;
  }

  void _onCustomerSelected(Customer c) {
    _isInternalUpdate = true;
    _currentName = c.name;
    _currentPhone = c.phone;
    _emailCtrl.text = c.email;
    _addressCtrl.text = c.address;
    widget.onSelected(c); // Pass the EXISTING customer with ID
    _isInternalUpdate = false;
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
          _buildHeader(),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildNameAutocomplete()),
              const SizedBox(width: 12),
              Expanded(child: _buildPhoneAutocomplete()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email', isDense: true, border: OutlineInputBorder()),
                  onChanged: (val) => _notifyChange(email: val),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address', isDense: true, border: OutlineInputBorder()),
                  onChanged: (val) => _notifyChange(address: val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
     return Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
         const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
         if (widget.selectedCustomer?.id != null)
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
             decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
             child: const Text('Existing', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
           )
         else if (_currentName.isNotEmpty || _currentPhone.isNotEmpty)
            Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
             decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
             child: const Text('New / Unsaved', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
           ),
       ],
     );
  }

  Widget _buildNameAutocomplete() {
    return LayoutBuilder(builder: (context, constraints) {
      return RawAutocomplete<Customer>(
        key: ValueKey('Name_${widget.selectedCustomer?.id ?? "new"}'), // Reset when selection changes externally
        initialValue: TextEditingValue(text: _currentName),
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) return const Iterable<Customer>.empty();
          return widget.customers.where((c) => c.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
        },
        displayStringForOption: (Customer option) => option.name,
        onSelected: _onCustomerSelected,
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          // Sync controller with state if initialValue didn't catch it
          if (controller.text != _currentName && !_isInternalUpdate) {
             controller.text = _currentName;
          }
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Search or Enter Name',
              isDense: true,
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.search, size: 16),
            ),
            onChanged: (val) {
               _notifyChange(name: val);
            },
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
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      dense: true,
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
    });
  }

  Widget _buildPhoneAutocomplete() {
    return LayoutBuilder(builder: (context, constraints) {
      return RawAutocomplete<Customer>(
        key: ValueKey('Phone_${widget.selectedCustomer?.id ?? "new"}'),
        initialValue: TextEditingValue(text: _currentPhone),
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) return const Iterable<Customer>.empty();
          return widget.customers.where((c) => c.phone.contains(textEditingValue.text));
        },
        displayStringForOption: (Customer option) => option.phone,
        onSelected: _onCustomerSelected,
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
           if (controller.text != _currentPhone && !_isInternalUpdate) {
             controller.text = _currentPhone;
          }
          return TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone', 
              hintText: 'Search or Enter Phone',
              isDense: true, 
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.phone, size: 16),
            ),
            onChanged: (val) {
               _notifyChange(phone: val);
            },
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
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      dense: true,
                      title: Text(option.phone, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(option.name),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
