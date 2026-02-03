import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/tab_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';
import '../models/pos_models.dart';
import '../providers/pos_provider.dart';
import 'dashboard_screen.dart';
import 'invoices_screen.dart';
import 'inventory_screen.dart';
import 'customers_screen.dart';
import 'service_management_screen.dart';
import 'user_management_screen.dart';
import 'hsn_management_screen.dart';
import 'reports/reports_screen.dart';
import 'membership_plans_screen.dart';
import 'settings_screen.dart';
import 'create_invoices/service_invoice_screen.dart';
import 'create_invoices/product_invoice_screen.dart';

import 'create_invoices/membership_invoice_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize with Dashboard tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.read<TabProvider>().hasTab('dashboard')) {
        context.read<TabProvider>().addTab(
          TabItem(
            id: 'dashboard',
            title: 'Dashboard',
            widget: const DashboardScreen(),
            type: TabType.dashboard,
          ),
        );
      }
      // Load Data Once
      context.read<POSProvider>().loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () => _navigateToTab(context, 'dashboard'),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () => _navigateToTab(context, 'invoices'),
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () => _navigateToTab(context, 'inventory'),
        const SingleActivator(LogicalKeyboardKey.digit4, control: true): () => _navigateToTab(context, 'services'),
        const SingleActivator(LogicalKeyboardKey.digit5, control: true): () => _navigateToTab(context, 'customers'),
        const SingleActivator(LogicalKeyboardKey.digit6, control: true): () => _navigateToTab(context, 'memberships'),
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () => _showNewInvoiceDialog(context),
        const SingleActivator(LogicalKeyboardKey.f1): () => _showShortcutsHelp(context),
        const SingleActivator(LogicalKeyboardKey.question, control: true): () => _showShortcutsHelp(context), // Alternative for F1
      },
      child: Focus(
        autofocus: true,
        onKey: (node, event) {
             // Optional: Handle keys here if needed, or let CallbackShortcuts handle it
             return KeyEventResult.ignored; 
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isDesktop = constraints.maxWidth >= 1000;
            
            return Scaffold(
              drawer: !isDesktop ? Drawer(child: _buildSidebar(context)) : null,
              appBar: !isDesktop 
                ? AppBar(
                    title: const Text('Automata POS'),
                    // Hamburger menu will appear automatically
                  ) 
                : null, 
              body: Row(
                children: [
                  if (isDesktop) _buildSidebar(context),
                  Expanded(
                    child: Column(
                      children: [
                        if (isDesktop) ...[
                           // No extra spacing needed if top tab bar is there
                        ] else ...[
                           // On mobile with AppBar, we might still want tabs below it
                           _buildTopTabBar(context),
                        ],
                        if (isDesktop) _buildTopTabBar(context),
                        
                        Expanded(
                          child: Consumer<TabProvider>(
                            builder: (context, provider, child) {
                              if (provider.tabs.isEmpty) return const SizedBox.shrink();
                              return IndexedStack(
                                index: provider.activeIndex,
                                children: provider.tabs.map((t) => t.widget).toList(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  void _navigateToTab(BuildContext context, String tabId) {
    final provider = context.read<TabProvider>();
    Widget widget;
    String title;
    TabType type;

    // Map IDs to widget/title/type if not already existing
    // This is a bit redundant with _buildNavItem but ensures shortcuts work even if tab isn't open
    if (provider.hasTab(tabId)) {
      provider.setActiveTab(tabId);
      return;
    }

    // If tab doesn't exist, Create it
    switch (tabId) {
      case 'dashboard':
        widget = const DashboardScreen();
        title = 'Dashboard';
        type = TabType.dashboard;
        break;
      case 'invoices':
        widget = const InvoicesScreen();
        title = 'Invoices';
        type = TabType.dashboard; // Using dashboard type as generic for list screens
        break;
      case 'inventory':
        widget = const InventoryScreen();
        title = 'Products';
        type = TabType.dashboard;
        break;
      case 'services':
        widget = const ServiceManagementScreen();
        title = 'Services';
        type = TabType.dashboard;
        break;
      case 'customers':
        widget = const CustomersScreen();
        title = 'Customers';
        type = TabType.dashboard;
        break;
      case 'memberships':
        widget = const MembershipPlansScreen();
        title = 'Memberships';
        type = TabType.membership;
        break;
      default:
        return;
    }
    
    provider.addTab(TabItem(id: tabId, title: title, widget: widget, type: type));
  }

  void _showNewInvoiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Create New Invoice'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _navigateToCreateInvoice(context, InvoiceType.service);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [Icon(Icons.build_outlined), SizedBox(width: 12), Text('Service Invoice')]),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _navigateToCreateInvoice(context, InvoiceType.product);
            },
            child: const Padding(
               padding: EdgeInsets.symmetric(vertical: 8),
               child: Row(children: [Icon(Icons.shopping_bag_outlined), SizedBox(width: 12), Text('Product Invoice')]),
            ),
          ),

          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _navigateToCreateInvoice(context, InvoiceType.membership);
            },
            child: const Padding(
               padding: EdgeInsets.symmetric(vertical: 8),
               child: Row(children: [Icon(Icons.card_membership_outlined), SizedBox(width: 12), Text('Membership Invoice')]),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateInvoice(BuildContext context, InvoiceType type) {
    final tabId = '${type.name}_${DateTime.now().millisecondsSinceEpoch}';
    Widget screen;
    String title;
    TabType tabType;
    
    switch (type) {
      case InvoiceType.service: 
        screen = ServiceInvoiceScreen(tabId: tabId); 
        title = 'Service Inv';
        tabType = TabType.serviceInvoice;
        break;
      case InvoiceType.product: 
        screen = ProductInvoiceScreen(tabId: tabId); 
        title = 'Product Inv';
        tabType = TabType.productInvoice;
        break;

      case InvoiceType.membership: 
        screen = MembershipInvoiceScreen(tabId: tabId); 
        title = 'Membership';
        tabType = TabType.membership;
        break;
      case InvoiceType.advance:
        return; // Should not be reached via this menu
    }

    context.read<TabProvider>().addTab(
      TabItem(
        id: tabId,
        title: title,
        widget: screen,
        type: tabType,
      ),
    );
  }

  void _showShortcutsHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keyboard Shortcuts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShortcutRow('Ctrl + 1', 'Dashboard'),
            _buildShortcutRow('Ctrl + 2', 'Invoices'),
            _buildShortcutRow('Ctrl + 3', 'Products'),
            _buildShortcutRow('Ctrl + 4', 'Services'),
            _buildShortcutRow('Ctrl + 5', 'Customers'),
            _buildShortcutRow('Ctrl + 6', 'Memberships'),
            const Divider(),
            _buildShortcutRow('Ctrl + N', 'New Invoice Menu'),
            _buildShortcutRow('F1 / Ctrl + ?', 'Show Shortcuts'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(String keys, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Text(keys, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace')),
          ),
          const SizedBox(width: 12),
          Text(description),
        ],
      ),
    );
  }

  Widget _buildTopTabBar(BuildContext context) {
    return Container(
      height: 40,
      color: Colors.grey.shade200,
      child: Consumer<TabProvider>(
        builder: (context, provider, child) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            itemCount: provider.tabs.length,
              itemBuilder: (context, index) {
                final tab = provider.tabs[index];
                final isActive = provider.activeIndex == index;
                return InkWell(
                  onTap: () => provider.setActiveIndex(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.transparent,
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                        top: isActive ? BorderSide(color: AppTheme.primaryColor, width: 2) : BorderSide.none,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconForTab(tab.type),
                          size: 14,
                          color: isActive ? AppTheme.primaryColor : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tab.title,
                          style: TextStyle(
                            color: isActive ? Colors.black87 : Colors.grey.shade700,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                        if (tab.id != 'dashboard') ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => provider.removeTab(tab.id),
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(Icons.close, size: 14, color: Colors.grey),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
        },
      ),
    );
  }

  IconData _getIconForTab(TabType type) {
    switch (type) {
      case TabType.dashboard: return Icons.dashboard;
      case TabType.serviceInvoice: return Icons.build;
      case TabType.productInvoice: return Icons.shopping_bag;
      case TabType.advance: return Icons.payments;
      case TabType.membership: return Icons.card_membership;
      default: return Icons.circle;
    }
  }

  Widget _buildSidebar(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppTheme.sidebarColor,
        border: Border(
          right: BorderSide(color: AppTheme.sidebarBorderColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildLogo(),
          const SizedBox(height: 24),
          // User Profile Section
          if (currentUser != null) _buildUserProfile(currentUser),
          const SizedBox(height: 24),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildNavItem(context, 'dashboard', Icons.dashboard_outlined, 'Dashboard', const DashboardScreen(), TabType.dashboard),
                  _buildNavItem(context, 'invoices', Icons.receipt_long_outlined, 'Invoices', const InvoicesScreen(), TabType.dashboard),
                  _buildNavItem(context, 'customers', Icons.people_outline, 'Customers', const CustomersScreen(), TabType.dashboard),

                  // Admin Items merged into main list
                   if (authProvider.isAdmin) ...[
                     const SizedBox(height: 24), // Subtle spacing instead of divider
                     Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                       child: Align(
                         alignment: Alignment.centerLeft,
                         child: Text('ADMINISTRATION', style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                       ),
                     ),
                    _buildNavItem(context, 'inventory', Icons.inventory_2_outlined, 'Products', const InventoryScreen(), TabType.dashboard),
                    _buildNavItem(context, 'services', Icons.miscellaneous_services_outlined, 'Services', const ServiceManagementScreen(), TabType.dashboard),
                    _buildNavItem(context, 'users', Icons.people_alt_outlined, 'Users', const UserManagementScreen(), TabType.dashboard),
                    _buildNavItem(context, 'memberships', Icons.card_membership_outlined, 'Memberships', const MembershipPlansScreen(), TabType.membership),
                    _buildNavItem(context, 'hsn', Icons.numbers, 'HSN Master', const HsnManagementScreen(), TabType.dashboard),
                    _buildNavItem(context, 'reports', Icons.bar_chart_outlined, 'Reports', const ReportsScreen(), TabType.dashboard),
                    _buildNavItem(context, 'settings', Icons.settings_outlined, 'Settings', const SettingsScreen(), TabType.dashboard),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          // Logout remains at bottom
          _buildLogoutButton(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUserProfile(user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Text(
                user.fullName[0].toUpperCase(),
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.role == UserRole.admin ? 'Administrator' : 'POS User',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );

            if (confirm == true && context.mounted) {
              context.read<TabProvider>().clearTabs();
              await context.read<AuthProvider>().logout();
            }
          },
          borderRadius: BorderRadius.circular(10),
          hoverColor: Colors.red.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.logout, color: Colors.red, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'Automata POS',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String id, IconData icon, String label, Widget widget, TabType type) {
    final provider = context.watch<TabProvider>();
    final isSelected = provider.tabs.isNotEmpty && provider.tabs[provider.activeIndex].id == id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (provider.hasTab(id)) {
              provider.setActiveTab(id);
            } else {
              provider.addTab(TabItem(id: id, title: label, widget: widget, type: type));
            }
          },
          borderRadius: BorderRadius.circular(10),
          hoverColor: AppTheme.sidebarHoverColor,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border(
                left: BorderSide(
                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.sidebarTextColor,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.sidebarTextColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
