import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
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
                   _isEdit ? 'Edit User' : 'Add New User',
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
                         label: 'Full Name',
                         child: TextFormField(
                           controller: _fullNameController,
                           decoration: const InputDecoration(
                             hintText: 'Enter full name', 
                             border: OutlineInputBorder(),
                             contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                           ),
                           validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                         ),
                       ),
                       const SizedBox(height: 16),
                       _buildField(
                         label: 'Username',
                         child: TextFormField(
                           controller: _usernameController,
                           decoration: const InputDecoration(
                             hintText: 'Enter username', 
                             border: OutlineInputBorder(),
                             contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                           ),
                           validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                         ),
                       ),
                       const SizedBox(height: 16),
                       _buildField(
                         label: 'User Role',
                         child: DropdownButtonFormField<UserRole>(
                           value: _selectedRole,
                           decoration: const InputDecoration(
                             border: OutlineInputBorder(),
                             contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                           ),
                           items: UserRole.values.map((role) {
                             return DropdownMenuItem(
                               value: role,
                               child: Text(role == UserRole.admin ? 'Admin' : 'POS User'),
                             );
                           }).toList(),
                           onChanged: (val) => setState(() => _selectedRole = val!),
                         ),
                       ),
                       const SizedBox(height: 16),
                       Row(
                         children: [
                           Expanded(
                             child: _buildField(
                               label: _isEdit ? 'Change Password' : 'Password',
                               child: TextFormField(
                                 controller: _passwordController,
                                 obscureText: true,
                                 decoration: const InputDecoration(
                                   hintText: 'Min 6 chars', 
                                   border: OutlineInputBorder(),
                                   contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                 ),
                                 validator: (val) {
                                   if (!_isEdit && (val == null || val.isEmpty)) return 'Required';
                                   if (val != null && val.isNotEmpty && val.length < 6) return 'Mini 6 chars';
                                   return null;
                                 },
                               ),
                             ),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: _buildField(
                               label: 'Confirm Password',
                               child: TextFormField(
                                 controller: _confirmPasswordController,
                                 obscureText: true,
                                 decoration: const InputDecoration(
                                   hintText: 'Repeat password', 
                                   border: OutlineInputBorder(),
                                   contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                 ),
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
                   onPressed: _saveUser,
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
