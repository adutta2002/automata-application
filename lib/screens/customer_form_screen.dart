import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pos_models.dart';
import '../providers/pos_provider.dart';
import '../utils/validators.dart';
import '../core/app_theme.dart';

class CustomerFormDialog extends StatefulWidget {
  final Customer? customer;

  const CustomerFormDialog({super.key, this.customer});

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _dobController;
  late TextEditingController _doaController;
  String? _gender;
  String? _selectedState;
  DateTime? _dob;
  DateTime? _doa;
  bool _isEdit = false;

  final List<String> _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh', 'Goa', 'Gujarat', 
    'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 
    'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 
    'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal', 
    'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra and Nagar Haveli and Daman and Diu', 
    'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Lakshadweep', 'Puducherry'
  ];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.customer != null;
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(text: widget.customer?.phone ?? '');
    _emailController = TextEditingController(text: widget.customer?.email ?? '');
    _addressController = TextEditingController(text: widget.customer?.address ?? '');
    _dob = widget.customer?.dob;
    _doa = widget.customer?.doa;
    _gender = widget.customer?.gender;
    _selectedState = widget.customer?.state;
    _dobController = TextEditingController(text: _dob != null ? _dob!.toIso8601String().split('T')[0] : '');
    _doaController = TextEditingController(text: _doa != null ? _doa!.toIso8601String().split('T')[0] : '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _doaController.dispose();
    super.dispose();
  }

  void _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    final customer = Customer(
      id: widget.customer?.id,
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      address: _addressController.text,
      createdAt: widget.customer?.createdAt ?? DateTime.now(),
      gender: _gender,
      dob: _dob,
      doa: _doa,
      state: _selectedState,
    );

    try {
      if (_isEdit) {
        await context.read<POSProvider>().updateCustomer(customer);
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer updated')));
      } else {
        await context.read<POSProvider>().addCustomer(customer);
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer added')));
      }
      if(mounted) Navigator.pop(context);
    } catch (e) {
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
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
                         _isEdit ? 'Edit Customer' : 'New Customer Profile',
                         style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                       ),
                       const SizedBox(height: 4),
                       const Text(
                         'Manage customer information and preferences',
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
                       // Section 1: Personal Information
                       _buildSectionHeader('Personal Information', Icons.person_outline),
                       const SizedBox(height: 24),
                       
                       Row(
                         children: [
                           Expanded(
                             flex: 2,
                             child: _buildField(
                               label: 'Full Name',
                               isRequired: true,
                               child: TextFormField(
                                 controller: _nameController,
                                 decoration: _inputDecoration('Enter full name', Icons.person),
                                 validator: Validators.required,
                               ),
                             ),
                           ),
                           const SizedBox(width: 24),
                           Expanded(
                             flex: 1,
                             child: _buildField(
                               label: 'Gender',
                               child: DropdownButtonFormField<String>(
                                 isExpanded: true,
                                 value: _gender,
                                 decoration: _inputDecoration('Select', Icons.wc),
                                 items: ['Male', 'Female', 'Other']
                                     .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                     .toList(),
                                 onChanged: (val) => setState(() => _gender = val),
                               ),
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 24),

                       Row(
                         children: [
                           Expanded(
                             child: _buildField(
                               label: 'Phone Number',
                               isRequired: true,
                               child: TextFormField(
                                 controller: _phoneController,
                                 keyboardType: TextInputType.phone,
                                 decoration: _inputDecoration('Enter phone number', Icons.phone),
                                 validator: Validators.phone,
                               ),
                             ),
                           ),
                           const SizedBox(width: 24),
                           Expanded(
                             child: _buildField(
                               label: 'Email Address',
                               child: TextFormField(
                                 controller: _emailController,
                                 keyboardType: TextInputType.emailAddress,
                                 decoration: _inputDecoration('Enter email address', Icons.email),
                                 validator: Validators.email,
                               ),
                             ),
                           ),
                         ],
                       ),
                       
                       const SizedBox(height: 32),
                       // Section 2: Important Dates
                       _buildSectionHeader('Important Dates', Icons.calendar_today_outlined),
                       const SizedBox(height: 24),

                       Row(
                         children: [
                           Expanded(
                             child: _buildField(
                               label: 'Date of Birth',
                               child: TextFormField(
                                 controller: _dobController,
                                 readOnly: true,
                                 decoration: _inputDecoration('YYYY-MM-DD', Icons.cake),
                                 onTap: () async {
                                   final date = await showDatePicker(
                                     context: context,
                                     initialDate: _dob ?? DateTime(2000),
                                     firstDate: DateTime(1900),
                                     lastDate: DateTime.now(),
                                   );
                                   if (date != null) {
                                     setState(() {
                                       _dob = date;
                                       _dobController.text = date.toIso8601String().split('T')[0];
                                     });
                                   }
                                 },
                               ),
                             ),
                           ),
                           const SizedBox(width: 24),
                           Expanded(
                             child: _buildField(
                               label: 'Anniversary Date',
                               child: TextFormField(
                                 controller: _doaController,
                                 readOnly: true,
                                 decoration: _inputDecoration('YYYY-MM-DD', Icons.favorite),
                                 onTap: () async {
                                   final date = await showDatePicker(
                                     context: context,
                                     initialDate: _doa ?? DateTime.now(),
                                     firstDate: DateTime(1900),
                                     lastDate: DateTime.now(),
                                   );
                                   if (date != null) {
                                     setState(() {
                                       _doa = date;
                                       _doaController.text = date.toIso8601String().split('T')[0];
                                     });
                                   }
                                 },
                               ),
                             ),
                           ),
                         ],
                       ),

                       const SizedBox(height: 32),
                       // Section 3: Address
                       _buildSectionHeader('Address & Location', Icons.location_on_outlined),
                       const SizedBox(height: 24),

                       Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Expanded(
                             flex: 2,
                             child: _buildField(
                               label: 'Full Address',
                               child: TextFormField(
                                 controller: _addressController,
                                 maxLines: 2,
                                 decoration: _inputDecoration('Enter street address, landmark, etc.', Icons.home),
                               ),
                             ),
                           ),
                           const SizedBox(width: 24),
                           Expanded(
                             flex: 1,
                             child: _buildField(
                               label: 'State',
                               child: DropdownButtonFormField<String>(
                                 isExpanded: true,
                                 value: _selectedState,
                                 decoration: _inputDecoration('Select State', Icons.map),
                                 items: _indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                 onChanged: (val) => setState(() => _selectedState = val),
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
                     onPressed: _saveCustomer,
                     icon: const Icon(Icons.check, size: 18),
                     label: Text(_isEdit ? 'Update Customer' : 'Save Customer'),
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
