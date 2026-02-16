import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pos_models.dart';
import '../models/user.dart'; // Added User model
import '../providers/pos_provider.dart';
import '../providers/user_provider.dart'; // Added UserProvider
import '../core/app_theme.dart';
import 'user_form_screen.dart';
import '../widgets/common/pagination_controls.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _searchQuery = '';
  int _currentPage = 1;
  static const int _itemsPerPage = 10;
  UserRole? _filterRole;
  String _filterStatus = 'All'; // 'All', 'True' (Active), 'False' (Inactive)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildActiveFilters(),
          _buildSearchAndFilter(),
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
          _buildAddUserButton(),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (val) => setState(() {
                _searchQuery = val;
                _currentPage = 1; // Reset to page 1 on search
              }),
              decoration: InputDecoration(
                hintText: 'Search by name or username...',
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
          ),
          const SizedBox(width: 16),
          _buildFilterButton(),
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
    UserRole? tempRole = _filterRole;
    String tempStatus = _filterStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Filter Users'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Role', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<UserRole?>(
                  value: tempRole,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
                    DropdownMenuItem(value: UserRole.posUser, child: Text('POS User')),
                  ],
                  onChanged: (val) => setState(() => tempRole = val),
                 ),
                 const SizedBox(height: 16),
                 const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                 const SizedBox(height: 8),
                 DropdownButtonFormField<String>(
                  value: tempStatus,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'True', child: Text('Active')),
                    DropdownMenuItem(value: 'False', child: Text('Inactive')),
                  ],
                  onChanged: (val) => setState(() => tempStatus = val!),
                 ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                 setState(() {
                   tempRole = null;
                   tempStatus = 'All';
                 });
              },
              child: const Text('Reset'),
            ),
            ElevatedButton(
              onPressed: () {
                this.setState(() {
                  _filterRole = tempRole;
                  _filterStatus = tempStatus;
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
        label: 'Role: ${_filterRole!.name.toUpperCase()}',
        onDeleted: () => setState(() { _filterRole = null; _currentPage = 1; }),
      ));
    }

    if (_filterStatus != 'All') {
      filters.add(_buildFilterChip(
        label: 'Status: ${_filterStatus == 'True' ? 'Active' : 'Inactive'}',
        onDeleted: () => setState(() { _filterStatus = 'All'; _currentPage = 1; }),
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
             TextButton(
               onPressed: () {
                 setState(() {
                   _filterRole = null;
                   _filterStatus = 'All';
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
      backgroundColor: AppTheme.primaryColor.withAlpha(26),
      labelStyle: TextStyle(color: AppTheme.primaryColor),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildAddUserButton() {
    return ElevatedButton.icon(
      onPressed: () => showDialog(
        context: context,
        builder: (context) => const UserFormDialog(),
      ),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add User'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        elevation: 2,
        shadowColor: AppTheme.primaryColor.withAlpha(77),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildUserTable() {
    return Consumer<UserProvider>(
      builder: (context, provider, child) {
        final filteredUsers = provider.users.where((user) {
          final query = _searchQuery.toLowerCase();
          final matchesName = user.fullName.toLowerCase().contains(query);
          final matchesUsername = user.username.toLowerCase().contains(query);
          
          bool matchesRole = true;
          if (_filterRole != null) {
            matchesRole = user.role == _filterRole;
          }

          bool matchesStatus = true;
          if (_filterStatus != 'All') {
            final isActive = _filterStatus == 'True';
            matchesStatus = user.isActive == isActive;
          }

          return (matchesName || matchesUsername) && matchesRole && matchesStatus;
        }).toList();

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_outlined, size: 64, color: AppTheme.mutedTextColor),
                const SizedBox(height: 16),
                Text(
                  'No users found',
                  style: TextStyle(fontSize: 16, color: AppTheme.mutedTextColor),
                ),
              ],
            ),
          );
        }

        final startIndex = (_currentPage - 1) * _itemsPerPage;
        if (startIndex >= filteredUsers.length && _currentPage > 1) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() => _currentPage = 1);
             });
             return const SizedBox.shrink();
        }

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
                color: Colors.black.withAlpha(13),
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
                  separatorBuilder: (context, index) => Divider(height: 1, color: AppTheme.tableBorderColor),
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
          const Expanded(flex: 2, child: Text('Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textColor))),
          const Expanded(flex: 2, child: Text('Username', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textColor))),
          const Expanded(child: Text('Role', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textColor))),
          const Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textColor), textAlign: TextAlign.center)),
          const SizedBox(width: 100, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textColor), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildTableRow(User user, int index) {
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
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    _buildUserAvatar(user),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  user.username,
                  style: const TextStyle(fontSize: 13, color: AppTheme.mutedTextColor),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user.role == UserRole.admin ? 'ADMIN' : 'USER',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.isActive ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: user.isActive ? Colors.green.shade200 : Colors.red.shade200,
                      ),
                    ),
                    child: Text(
                      user.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 11,
                        color: user.isActive ? Colors.green.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 100,
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
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: Colors.red,
                      onPressed: () => _confirmDelete(context, user),
                      tooltip: 'Delete',
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

  Widget _buildUserAvatar(User user) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(26),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primaryColor.withAlpha(51)),
      ),
      child: Center(
        child: Text(
          user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete user "${user.fullName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await context.read<UserProvider>().deleteUser(user.id!);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User "${user.fullName}" deleted')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

}
