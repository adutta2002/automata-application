import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../core/app_theme.dart';
import '../models/pos_models.dart';
import 'membership_plans_screen.dart';
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
      appBar: AppBar(title: const Text('Settings')),
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
                  _buildBusinessSection(context, settings),
                  const SizedBox(height: 32),
                  _buildInvoiceConfigSection(context, settings),
                  const SizedBox(height: 32),
                  _buildPrinterSection(context, settings),
                  const SizedBox(height: 32),
                  _buildDatabaseSection(context, settings),
                  const SizedBox(height: 32),
                  _buildAboutSection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBusinessSection(BuildContext context, SettingsProvider settings) {
    final branch = settings.currentBranch;
    if (branch == null) return const SizedBox.shrink();

    return _buildSection(
      'Store Details',
      [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.store, color: AppTheme.primaryColor),
          ),
          title: Text(branch.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(branch.address),
              if (branch.gstin != null && branch.gstin!.isNotEmpty)
                Text('GSTIN: ${branch.gstin}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showBranchEditDialog(context, settings, branch),
          ),
        ),
      ],
    );
  }

  void _showBranchEditDialog(BuildContext context, SettingsProvider settings, Branch branch) {
    final nameCtrl = TextEditingController(text: branch.name);
    final addrCtrl = TextEditingController(text: branch.address);
    final phoneCtrl = TextEditingController(text: branch.phone);
    final gstinCtrl = TextEditingController(text: branch.gstin);
    final shortCodeCtrl = TextEditingController(text: branch.shortCode);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${branch.name}'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Branch Name')),
                const SizedBox(height: 12),
                TextField(controller: shortCodeCtrl, decoration: const InputDecoration(labelText: 'Store Short Code (e.g. AT)', hintText: 'Used for Invoice Numbers')),
                const SizedBox(height: 12),
                TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address')),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
                const SizedBox(height: 12),
                TextField(controller: gstinCtrl, decoration: const InputDecoration(labelText: 'GSTIN')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
               await settings.updateBusinessDetails(
                 nameCtrl.text, 
                 addrCtrl.text, 
                 gstinCtrl.text, 
                 phoneCtrl.text,
                 shortCodeCtrl.text,
               ); 
               Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceConfigSection(BuildContext context, SettingsProvider settings) {
    return _buildSection(
      'Invoice Configuration',
      [
        SwitchListTile(
          title: const Text('Product Invoice: Tax Inclusive'),
          subtitle: const Text('If enabled, entered prices will include tax'),
          value: settings.productTaxInclusive,
          onChanged: (val) {
            settings.updateTaxSettings(
              productInclusive: val,
              serviceInclusive: settings.serviceTaxInclusive,
            );
          },
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Service Invoice: Tax Inclusive'),
          subtitle: const Text('If enabled, entered rates will include tax'),
          value: settings.serviceTaxInclusive,
          onChanged: (val) {
            settings.updateTaxSettings(
              productInclusive: settings.productTaxInclusive,
              serviceInclusive: val,
            );
          },
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Service Invoice: Price Editable'),
          subtitle: const Text('If enabled, you can edit service prices manually during invoice creation'),
          value: settings.servicePriceEditable,
          onChanged: (val) {
            settings.updateServicePriceEditable(val);
          },
        ),
      ],
    );
  }

  Widget _buildPrinterSection(BuildContext context, SettingsProvider settings) {
    return _buildSection(
      'Printer Configuration',
      [
        ListTile(
          leading: const Icon(Icons.print_outlined),
          title: const Text('Printer Type'),
          trailing: DropdownButton<String>(
            value: settings.printerType,
            underline: const SizedBox(),
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
        ListTile(
          leading: const Icon(Icons.wifi),
          title: const Text('Network Printer IP'),
          subtitle: Text(settings.printerIp.isEmpty ? 'Not Configured' : settings.printerIp),
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showPrinterIpDialog(context, settings),
          ),
        ),
      ],
    );
  }

  Widget _buildDatabaseSection(BuildContext context, SettingsProvider settings) {
    return _buildSection(
      'Database Management',
      [
        ListTile(
          leading: const Icon(Icons.backup_outlined, color: Colors.green),
          title: const Text('Backup Database'),
          subtitle: const Text('Export a copy of your local data'),
          onTap: () async {
            final msg = await settings.backupDatabase();
            if (context.mounted && msg != null) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
            }
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.restore_outlined, color: Colors.orange),
          title: const Text('Restore Database'),
          subtitle: const Text('Restore data from a backup file (Requires Restart)'),
          onTap: () async {
             final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Confirm Restore'),
                content: const Text('This will overwrite current data. The app should be restarted after restore. Continue?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Proceed')),
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
        const Divider(),
        ListTile(
          leading: const Icon(Icons.data_array, color: Colors.blue),
          title: const Text('Generate Demo Data'),
          subtitle: const Text('Populate with sample products, services, and customers'),
          onTap: () async {
             final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Generate Data?'),
                content: const Text('This will add sample data to your database. Existing data will be preserved.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Generate')),
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
  
  Widget _buildAboutSection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Automata POS v1.0.0\n© 2025 DeepMind',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo)),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200)
          ),
          child: Column(children: children),
        ),
      ],
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
