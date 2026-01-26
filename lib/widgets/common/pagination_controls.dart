import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalItems;
  final int itemsPerPage;
  final Function(int) onPageChanged;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = (totalItems / itemsPerPage).ceil();
    // If no items, show 1 page (empty)
    final displayTotalPages = totalPages == 0 ? 1 : totalPages;
    
    // Calculate range
    final startItem = totalItems == 0 ? 0 : (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage) > totalItems ? totalItems : (currentPage * itemsPerPage);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.tableBorderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $startItem to $endItem of $totalItems entries',
            style: const TextStyle(
              color: AppTheme.mutedTextColor,
              fontSize: 13,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
                padding: EdgeInsets.zero,
                tooltip: 'Previous Page',
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Page $currentPage of $displayTotalPages',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.textColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
                icon: const Icon(Icons.chevron_right),
                padding: EdgeInsets.zero,
                tooltip: 'Next Page',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
