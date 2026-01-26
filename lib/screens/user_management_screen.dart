import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../core/app_theme.dart';
import 'package:intl/intl.dart';
import 'user_form_screen.dart';
import '../widgets/common/pagination_controls.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _searchQuery = '';
  // Filters
  UserRole? _filterRole;
  bool? _filterIsActive;

  int _currentPage = 1;
  static const int _itemsPerPage = 4;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<UserProvider>().loadUsers());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildActiveFilters(),
          _buildSearchBar(),
          Expanded(child: _buildUserTable()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.tableBorderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'User Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          Row(
            children: [
              _buildFilterButton(),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const UserFormDialog(),
                ),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Add User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
     return OutlinedButton.icon(
      onPressed: _showFilterDialog,
      icon: const Icon(Icons.filter_list, size: 18),
      label: const Text('Filter'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.mutedTextColor,
        side: BorderSide(color: AppTheme.tableBorderColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

   void _showFilterDialog() {
    // Temp state
    UserRole? tempRole = _filterRole;
    bool? tempActive = _filterIsActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Users'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Role', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<UserRole?>(
                value: tempRole,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                   ...UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r == UserRole.admin ? 'Admin' : 'POS User'))),
                ],
                onChanged: (val) => setState(() => tempRole = val),
              ),
              const SizedBox(height: 16),
              const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<bool?>(
                value: tempActive,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: true, child: Text('Active')),
                  DropdownMenuItem(value: false, child: Text('Inactive')),
                ],
                onChanged: (val) => setState(() => tempActive = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  tempRole = null;
                  tempActive = null;
                });
              },
              child: const Text('Reset'),
            ),
             ElevatedButton(
              onPressed: () {
                this.setState(() {
                  _filterRole = tempRole;
                  _filterIsActive = tempActive;
                  _currentPage = 1; 
                });
                Navigator.pop(context);
              },
               style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    final filters = <Widget>[];

    if (_filterRole != null) {
      filters.add(_buildFilterChip(
        label: 'Role: ${_filterRole == UserRole.admin ? 'Admin' : 'POS User'}',
        onDeleted: () => setState(() { _filterRole = null; _currentPage = 1; }),
      ));
    }

    if (_filterIsActive != null) {
      filters.add(_buildFilterChip(
        label: 'Status: ${_filterIsActive! ? 'Active' : 'Inactive'}',
        onDeleted: () => setState(() { _filterIsActive = null; _currentPage = 1; }),
      ));
    }

    if (filters.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: Text(
              'Active Filters:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.mutedTextColor,
              ),
            ),
          ),
          ...filters,
          if (filters.isNotEmpty)
             TextButton(
               onPressed: () {
                 setState(() {
                   _filterRole = null;
                   _filterIsActive = null;
                   _currentPage = 1;
                 });
               },
               style: TextButton.styleFrom(
                 foregroundColor: Colors.red,
                 padding: const EdgeInsets.symmetric(horizontal: 8),
                 minimumSize: Size.zero,
                 tapTargetSize: MaterialTapTargetSize.shrinkWrap,
               ),
               child: const Text('Clear All', style: TextStyle(fontSize: 12)),
             ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onDeleted}) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDeleted,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(color: AppTheme.primaryColor),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: TextField(
        onChanged: (val) => setState(() {
          _searchQuery = val;
          _currentPage = 1;
        }),
        decoration: InputDecoration(
          hintText: 'Search users by name or username...',
          prefixIcon: Icon(Icons.search, color: AppTheme.mutedTextColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() {
                    _searchQuery = '';
                    _currentPage = 1;
                  }),
                )
              : null,
          filled: true,
          fillColor: AppTheme.backgroundColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppTheme.tableBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppTheme.tableBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTable() {
    return Consumer<UserProvider>(
      builder: (context, provider, child) {
        // 1. Filter
        final filteredUsers = provider.users.where((u) {
          final matchesSearch = u.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 u.username.toLowerCase().contains(_searchQuery.toLowerCase());
          
          final matchesRole = _filterRole == null || u.role == _filterRole;
          final matchesStatus = _filterIsActive == null || u.isActive == _filterIsActive;

          return matchesSearch && matchesRole && matchesStatus;
        }).toList();

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: AppTheme.mutedTextColor),
                const SizedBox(height: 16),
                Text(
                  'No users found',
                  style: TextStyle(fontSize: 16, color: AppTheme.mutedTextColor),
                ),
              ],
            ),
          );
        }

        // 2. Paginate
        final startIndex = (_currentPage - 1) * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage < filteredUsers.length) 
            ? startIndex + _itemsPerPage 
            : filteredUsers.length;
            
        final paginatedUsers = filteredUsers.sublist(startIndex, endIndex);

        return Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.tableBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildTableHeader(),
              Expanded(
                child: ListView.separated(
                  itemCount: paginatedUsers.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: AppTheme.tableBorderColor,
                  ),
                  itemBuilder: (context, index) {
                    final user = paginatedUsers[index];
                    return _buildTableRow(user, index);
                  },
                ),
              ),
              PaginationControls(
                currentPage: _currentPage,
                totalItems: filteredUsers.length,
                itemsPerPage: _itemsPerPage,
                onPageChanged: (page) => setState(() => _currentPage = page),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.tableHeaderColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: Text(
              'User',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.textColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'Username',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.textColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Role',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.textColor,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Expanded(
            child: Text(
              'Status',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.textColor,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'Last Login',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.textColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(
            width: 120,
            child: Text(
              'Actions',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.textColor,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(User user, int index) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    final isCurrentUser = currentUser?.id == user.id;

    return Material(
      color: index.isEven ? AppTheme.tableRowEvenColor : AppTheme.tableRowOddColor,
      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (context) => UserFormDialog(user: user),
        ),
        hoverColor: AppTheme.tableHoverColor,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // User with avatar
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: user.isActive ? AppTheme.primaryColor : Colors.grey.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: user.isActive ? AppTheme.primaryColor.withOpacity(0.3) : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          user.fullName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppTheme.textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCurrentUser) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Text(
                                    'YOU',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Username
              Expanded(
                flex: 2,
                child: Text(
                  user.username,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.mutedTextColor,
                  ),
                ),
              ),
              // Role
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.role == UserRole.admin
                          ? Colors.purple.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: user.role == UserRole.admin
                            ? Colors.purple.shade200
                            : Colors.blue.shade200,
                      ),
                    ),
                    child: Text(
                      user.role == UserRole.admin ? 'ADMIN' : 'POS USER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: user.role == UserRole.admin
                            ? Colors.purple.shade900
                            : Colors.blue.shade900,
                      ),
                    ),
                  ),
                ),
              ),
              // Status
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.isActive ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: user.isActive ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Text(
                      user.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: user.isActive ? Colors.green.shade900 : Colors.red.shade900,
                      ),
                    ),
                  ),
                ),
              ),
              // Last Login
              Expanded(
                flex: 2,
                child: Text(
                  user.lastLogin != null
                      ? DateFormat('dd MMM, HH:mm').format(user.lastLogin!)
                      : 'Never',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedTextColor,
                  ),
                ),
              ),
              // Actions
              SizedBox(
                width: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: Colors.blue,
                      onPressed: () => showDialog(
                        context: context,
                        builder: (context) => UserFormDialog(user: user),
                      ),
                      tooltip: 'Edit',
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      tooltip: 'More actions',
                      onSelected: (value) {
                        switch (value) {
                          case 'toggle':
                            _toggleUserStatus(user);
                            break;
                          case 'reset':
                            _showResetPasswordDialog(user);
                            break;
                          case 'delete':
                            _confirmDelete(user);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(user.isActive ? 'Deactivate' : 'Activate'),
                        ),
                        const PopupMenuItem(
                          value: 'reset',
                          child: Text('Reset Password'),
                        ),
                        if (!isCurrentUser)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _toggleUserStatus(User user) async {
    final error = await context.read<UserProvider>().toggleUserStatus(user.id!);
    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ${user.isActive ? 'deactivated' : 'activated'}')),
        );
      }
    }
  }

  void _showResetPasswordDialog(User user) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password for ${user.fullName}'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(),
            helperText: 'Minimum 6 characters',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final error = await context.read<UserProvider>().resetPassword(
                    user.id!,
                    passwordController.text,
                  );

              if (context.mounted) {
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset successfully')),
                  );
                }
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete user "${user.fullName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final error = await context.read<UserProvider>().deleteUser(user.id!);

              if (context.mounted) {
                Navigator.pop(context);
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User deleted')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
