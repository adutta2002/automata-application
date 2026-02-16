import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pos_models.dart';
import '../providers/pos_provider.dart';
import '../core/app_theme.dart';
import 'hsn_form_screen.dart';
import '../widgets/common/pagination_controls.dart';

class HsnManagementScreen extends StatefulWidget {
  const HsnManagementScreen({super.key});

  @override
  State<HsnManagementScreen> createState() => _HsnManagementScreenState();
}

class _HsnManagementScreenState extends State<HsnManagementScreen> {
  String _searchQuery = '';
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSearchAndFilter(),
          Expanded(child: _buildHsnTable()),
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
            'HSN/SAC Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          _buildAddHsnButton(),
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
                hintText: 'Search HSN codes or description...',
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Filter HSN/SAC'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('More filters coming soon...', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddHsnButton() {
    return ElevatedButton.icon(
      onPressed: () => showDialog(
        context: context,
        builder: (context) => const HsnFormDialog(),
      ),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add HSN/SAC'),
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

  Widget _buildHsnTable() {
    return Consumer<POSProvider>(
      builder: (context, provider, child) {
        final filteredHsn = provider.hsnCodes.where((h) {
          final query = _searchQuery.toLowerCase();
          return h.code.toLowerCase().contains(query) ||
                 h.description.toLowerCase().contains(query);
        }).toList();

        if (filteredHsn.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.tag, size: 64, color: AppTheme.mutedTextColor),
                const SizedBox(height: 16),
                Text(
                  'No HSN/SAC codes found',
                  style: TextStyle(fontSize: 16, color: AppTheme.mutedTextColor),
                ),
              ],
            ),
          );
        }

        final startIndex = (_currentPage - 1) * _itemsPerPage;
        if (startIndex >= filteredHsn.length && _currentPage > 1) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() => _currentPage = 1);
             });
             return const SizedBox.shrink();
        }

        final endIndex = (startIndex + _itemsPerPage < filteredHsn.length) 
            ? startIndex + _itemsPerPage 
            : filteredHsn.length;
            
        final paginatedHsn = filteredHsn.sublist(startIndex, endIndex);

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
                  itemCount: paginatedHsn.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: AppTheme.tableBorderColor),
                  itemBuilder: (context, index) {
                    final hsn = paginatedHsn[index];
                    return _buildTableRow(hsn, index);
                  },
                ),
              ),
              PaginationControls(
                currentPage: _currentPage,
                totalItems: filteredHsn.length,
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
          const Expanded(flex: 2, child: Text('Code', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textColor))),
          const Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textColor))),
          const Expanded(child: Text('Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textColor), textAlign: TextAlign.center)),
          const Expanded(child: Text('GST Rate', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textColor), textAlign: TextAlign.center)),
          const SizedBox(width: 100, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textColor), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildTableRow(HsnCode hsn, int index) {
    return Material(
      color: index.isEven ? AppTheme.tableRowEvenColor : AppTheme.tableRowOddColor,
      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (context) => HsnFormDialog(hsn: hsn),
        ),
        hoverColor: AppTheme.tableHoverColor,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  hsn.code,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textColor),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  hsn.description,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hsn.type == 'GOODS' ? Colors.green.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      hsn.type,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: hsn.type == 'GOODS' ? Colors.green.shade700 : Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${hsn.gstRate}%',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textColor),
                  textAlign: TextAlign.center,
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
                        builder: (context) => HsnFormDialog(hsn: hsn),
                      ),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: Colors.red,
                      onPressed: () => _confirmDelete(context, hsn),
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

  void _confirmDelete(BuildContext context, HsnCode hsn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete HSN Code "${hsn.code}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await context.read<POSProvider>().deleteHsnCode(hsn.id!);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('HSN Code "${hsn.code}" deleted')));
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
