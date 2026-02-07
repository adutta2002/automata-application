import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../utils/validators.dart';
import '../core/app_theme.dart';

class UserFormDialog extends StatefulWidget {
  final User? user;

  const UserFormDialog({super.key, this.user});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late UserRole _selectedRole;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.user != null;
    _fullNameController = TextEditingController(text: widget.user?.fullName ?? '');
    _usernameController = TextEditingController(text: widget.user?.username ?? '');
    _selectedRole = widget.user?.role ?? UserRole.posUser;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = context.read<UserProvider>();
    String? error;

    if (_isEdit) {
      final updatedUser = widget.user!.copyWith(
        fullName: _fullNameController.text,
        username: _usernameController.text,
        role: _selectedRole,
      );
      error = await userProvider.updateUser(updatedUser);
    } else {
      final newUser = User(
        username: _usernameController.text,
        passwordHash: '', // Set by provider
        fullName: _fullNameController.text,
        role: _selectedRole,
        createdAt: DateTime.now(),
      );
      error = await userProvider.addUser(newUser, _passwordController.text);
    }

    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'User updated successfully' : 'User added successfully')),
        );
        Navigator.pop(context);
      }
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
                         _isEdit ? 'Edit User Profile' : 'New User Profile',
                         style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                       ),
                       const SizedBox(height: 4),
                       const Text(
                         'Manage system users and access roles',
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
                       // Section 1: User Identity
                       _buildSectionHeader('User Identity', Icons.person_outline),
                       const SizedBox(height: 24),
                       
                       Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Expanded(
                             flex: 2,
                             child: _buildField(
                               label: 'Full Name',
                               isRequired: true,
                               child: TextFormField(
                                 controller: _fullNameController,
                                 decoration: _inputDecoration('Enter full name', Icons.badge),
                                 validator: Validators.required,
                               ),
                             ),
                           ),
                           const SizedBox(width: 24),
                           Expanded(
                             flex: 1,
                             child: _buildField(
                               label: 'Username',
                               isRequired: true,
                               child: TextFormField(
                                 controller: _usernameController,
                                 decoration: _inputDecoration('Login ID', Icons.account_circle),
                                 validator: Validators.username,
                               ),
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 32),

                       // Section 2: Security & Access
                       _buildSectionHeader('Security & Access', Icons.security),
                       const SizedBox(height: 24),

                       Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Expanded(
                             child: _buildField(
                               label: 'User Role',
                               isRequired: true,
                               child: DropdownButtonFormField<UserRole>(
                                 isExpanded: true,
                                 value: _selectedRole,
                                 decoration: _inputDecoration('', Icons.admin_panel_settings),
                                 items: UserRole.values.map((role) {
                                   return DropdownMenuItem(
                                     value: role,
                                     child: Text(role == UserRole.admin ? 'Administrator' : 'POS User'),
                                   );
                                 }).toList(),
                                 onChanged: (val) => setState(() => _selectedRole = val!),
                               ),
                             ),
                           ),
                           const SizedBox(width: 24),
                           Expanded(
                             child: _buildField(
                               label: _isEdit ? 'New Password' : 'Password',
                               isRequired: !_isEdit,
                               child: TextFormField(
                                 controller: _passwordController,
                                 obscureText: true,
                                 decoration: _inputDecoration('Min 6 data', Icons.lock_outline),
                                 validator: (val) {
                                   if (!_isEdit && (val == null || val.isEmpty)) return 'Required';
                                   if (val != null && val.isNotEmpty) return Validators.minLength(val, 6);
                                   return null;
                                 },
                               ),
                             ),
                           ),
                           const SizedBox(width: 24),
                           Expanded(
                             child: _buildField(
                               label: 'Confirm Password',
                               isRequired: !_isEdit, 
                               child: TextFormField(
                                 controller: _confirmPasswordController,
                                 obscureText: true,
                                 decoration: _inputDecoration('Repeat password', Icons.lock_reset),
                                 validator: (val) {
                                   if (_passwordController.text.isNotEmpty && val != _passwordController.text) {
                                     return 'Mismatch';
                                   }
                                   return null;
                                 },
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
                     onPressed: _saveUser,
                     icon: const Icon(Icons.check, size: 18),
                     label: Text(_isEdit ? 'Update User' : 'Create User'),
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
