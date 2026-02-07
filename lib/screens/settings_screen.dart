import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../core/app_theme.dart';
import '../models/pos_models.dart';
import '../providers/pos_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          if (settings.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildSectionHeader('Business Profile', Icons.business),
                  _buildBusinessSection(context, settings),
                  const SizedBox(height: 32),
                  
                  _buildSectionHeader('Invoicing & Tax', Icons.receipt_long),
                  _buildInvoiceConfigSection(context, settings),
                  const SizedBox(height: 32),
                  
                  _buildSectionHeader('Hardware & Peripherals', Icons.print_outlined),
                  _buildPrinterSection(context, settings),
                  const SizedBox(height: 32),
                  
                  _buildSectionHeader('Data Management', Icons.storage),
                  _buildDatabaseSection(context, settings),
                  const SizedBox(height: 48),
                  
                  _buildAboutSection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessSection(BuildContext context, SettingsProvider settings) {
    final branch = settings.currentBranch;
    if (branch == null) return const SizedBox.shrink();

    return _buildCard(
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50, // Replaced primaryColor.withOpacity(0.1)
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.storefront, color: AppTheme.primaryColor, size: 32),
        ),
        title: Text(
          branch.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(branch.address, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            if (branch.gstin != null && branch.gstin!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.verified_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('GSTIN: ${branch.gstin}', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ],
          ],
        ),
        trailing: ElevatedButton.icon(
          onPressed: () => _showBranchEditDialog(context, settings, branch),
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Edit Details'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryColor,
            elevation: 0,
            side: const BorderSide(color: AppTheme.primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceConfigSection(BuildContext context, SettingsProvider settings) {
    return _buildCard(
      child: Column(
        children: [
          SwitchListTile(
            activeColor: AppTheme.primaryColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            title: const Text('Product Invoice: Tax Inclusive', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Prices entered for products include tax'),
            value: settings.productTaxInclusive,
            onChanged: (val) {
              settings.updateTaxSettings(
                productInclusive: val,
                serviceInclusive: settings.serviceTaxInclusive,
              );
            },
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          SwitchListTile(
               activeColor: AppTheme.primaryColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            title: const Text('Service Invoice: Tax Inclusive', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Rates entered for services include tax'),
            value: settings.serviceTaxInclusive,
            onChanged: (val) {
              settings.updateTaxSettings(
                productInclusive: settings.productTaxInclusive,
                serviceInclusive: val,
              );
            },
          ),
           Divider(height: 1, color: Colors.grey.shade200),
          SwitchListTile(
             activeColor: AppTheme.primaryColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            title: const Text('Service Invoice: Price Editable', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Allow manual price editing during invoice creation'),
            value: settings.servicePriceEditable,
            onChanged: (val) {
              settings.updateServicePriceEditable(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterSection(BuildContext context, SettingsProvider settings) {
    return _buildCard(
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.print, color: Colors.purple.shade700),
            ),
            title: const Text('Printer Type', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Select your invoice printer format'),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: settings.printerType,
                borderRadius: BorderRadius.circular(12),
                items: const [
                  DropdownMenuItem(value: 'THERMAL_58', child: Text('Thermal 58mm')),
                  DropdownMenuItem(value: 'THERMAL_80', child: Text('Thermal 80mm')),
                  DropdownMenuItem(value: 'A4', child: Text('A4 Laser/Inkjet')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    settings.updatePrinterSettings(val, settings.printerIp);
                  }
                },
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.wifi, color: Colors.blue.shade700),
            ),
            title: const Text('Network Printer IP', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(settings.printerIp.isEmpty ? 'Not Configured' : settings.printerIp),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showPrinterIpDialog(context, settings),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseSection(BuildContext context, SettingsProvider settings) {
    return Column(
      children: [
        _buildActionTile(
          icon: Icons.backup_outlined,
          color: Colors.green,
          bgColor: Colors.green.shade50, // Added bgColor
          title: 'Backup Database',
          subtitle: 'Export a copy of your local data for safety',
          onTap: () async {
            final msg = await settings.backupDatabase();
            if (context.mounted && msg != null) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
            }
          },
        ),
        const SizedBox(height: 16),
        _buildActionTile(
          icon: Icons.restore,
          color: Colors.orange,
           bgColor: Colors.orange.shade50, // Added bgColor
          title: 'Restore Database',
           subtitle: 'Restore data from a backup file (Requires Restart)',
          onTap: () async {
             final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Confirm Restore'),
                content: const Text('This will overwrite current data. The app should be restarted after restore. Continue?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Proceed', style: TextStyle(color: Colors.orange))),
                ],
              ),
            );

            if (confirm == true && context.mounted) {
               final msg = await settings.restoreDatabase();
               if (context.mounted && msg != null) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
               }
            }
          },
        ),
        const SizedBox(height: 16),
        _buildActionTile(
          icon: Icons.data_usage,
          color: Colors.blue,
           bgColor: Colors.blue.shade50, // Added bgColor
           title: 'Generate Demo Data',
          subtitle: 'Populate with sample products, services, and customers',
          onTap: () async {
             final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Generate Data?'),
                content: const Text('This will add sample data to your database. Existing data will be preserved.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Generate', style: TextStyle(color: Colors.blue))),
                ],
              ),
            );

            if (confirm == true && context.mounted) {
               await Provider.of<POSProvider>(context, listen: false).generateMasterData();
               if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo Data Generated Successfully!')));
               }
            }
          },
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return _buildCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor, // Use passed bgColor
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }
  
  Widget _buildAboutSection() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.verified, color: Colors.grey.shade300, size: 48),
          const SizedBox(height: 12),
          Text(
            'Automata POS v1.0.0',
             style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold),
          ),
          Text(
            '© 2026 DeepMind',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.shade100, // Replaced withOpacity(0.05)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: child,
    );
  }

  void _showBranchEditDialog(BuildContext context, SettingsProvider settings, Branch branch) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _EditShopDialog(
        branch: branch,
        onSave: (name, address, gstin, phone, shortCode) async {
          await settings.updateBusinessDetails(name, address, gstin, phone, shortCode);
        },
      ),
    );
  }

  void _showPrinterIpDialog(BuildContext context, SettingsProvider settings) {
     final ipCtrl = TextEditingController(text: settings.printerIp);
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Printer IP Configuration'),
        content: TextField(controller: ipCtrl, decoration: const InputDecoration(labelText: 'Printer IP Address', hintText: '192.168.1.x')),
        actions: [
           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
           ElevatedButton(
            onPressed: () {
              settings.updatePrinterSettings(settings.printerType, ipCtrl.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
     );
  }
}

class _EditShopDialog extends StatefulWidget {
  final Branch branch;
  final Function(String name, String address, String gstin, String phone, String shortCode) onSave;

  const _EditShopDialog({required this.branch, required this.onSave});

  @override
  State<_EditShopDialog> createState() => _EditShopDialogState();
}

class _EditShopDialogState extends State<_EditShopDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _gstinController;
  late TextEditingController _shortCodeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.branch.name);
    _addressController = TextEditingController(text: widget.branch.address);
    _phoneController = TextEditingController(text: widget.branch.phone);
    _gstinController = TextEditingController(text: widget.branch.gstin);
    _shortCodeController = TextEditingController(text: widget.branch.shortCode);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    _shortCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width > 900 ? 900.0 : screenSize.width * 0.95;

    return Dialog(
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
       backgroundColor: Colors.white,
       elevation: 8,
       insetPadding: const EdgeInsets.all(16),
       child: Container(
         width: dialogWidth,
         constraints: BoxConstraints(maxHeight: screenSize.height * 0.9),
         child: Column(
           children: [
             // Header
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
               decoration: BoxDecoration(
                 gradient: LinearGradient(
                   colors: [Colors.indigo.shade50, Colors.white], // Replaced withOpacity(0.1)
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
                       const Text(
                         'Edit Visual/Store Details',
                         style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                       ),
                       const SizedBox(height: 4),
                       const Text(
                         'Update your business information',
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
                       
                       _buildSectionHeader('Basic Information', Icons.store),
                       const SizedBox(height: 24),

                       Row(
                         children: [
                           Expanded(
                             flex: 2,
                             child: _buildField(
                               label: 'Store Name', 
                               isRequired: true,
                               child: TextFormField(
                                 controller: _nameController,
                                 decoration: _inputDecoration('Enter store name', Icons.storefront),
                                 validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                               ),
                             ),
                           ),
                           const SizedBox(width: 24),
                           Expanded(
                             flex: 1,
                             child: _buildField(
                               label: 'Short Code', 
                               child: TextFormField(
                                 controller: _shortCodeController,
                                 decoration: _inputDecoration('e.g. BLR', Icons.label),
                               ),
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 24),

                       _buildSectionHeader('Contact & Legal', Icons.contact_page),
                       const SizedBox(height: 24),

                        Row(
                         children: [
                           Expanded(
                             child: _buildField(
                               label: 'Phone Number', 
                               child: TextFormField(
                                 controller: _phoneController,
                                 decoration: _inputDecoration('Contact number', Icons.phone),
                               ),
                             ),
                           ),
                           const SizedBox(width: 24),
                           Expanded(
                             child: _buildField(
                               label: 'GSTIN', 
                               child: TextFormField(
                                 controller: _gstinController,
                                 decoration: _inputDecoration('Tax Identification Number', Icons.verified_user),
                               ),
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 24),

                       _buildField(
                         label: 'Address', 
                         child: TextFormField(
                           controller: _addressController,
                           maxLines: 3,
                           decoration: _inputDecoration('Full address', Icons.location_on),
                         ),
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
                     onPressed: () {
                       if (_formKey.currentState!.validate()) {
                         widget.onSave(
                           _nameController.text,
                           _addressController.text,
                           _gstinController.text,
                           _phoneController.text,
                           _shortCodeController.text,
                         );
                         Navigator.pop(context);
                       }
                     },
                     icon: const Icon(Icons.check, size: 18),
                     label: const Text('Save Details'),
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
            color: Colors.indigo.shade50, // Replaced withOpacity(0.1)
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
