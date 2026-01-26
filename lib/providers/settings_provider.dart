import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../core/database_helper.dart';
import 'package:automata_pos/models/pos_models.dart';

class SettingsProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  SharedPreferences? _prefs;

  // Keys
  static const String KEY_PRINTER_TYPE = 'printer_type'; // 'THERMAL_58', 'THERMAL_80', 'A4'
  static const String KEY_PRINTER_IP = 'printer_ip'; // For network printers
  static const String KEY_BACKUP_EMAIL = 'backup_email';
  static const String KEY_CURRENT_BRANCH_ID = 'current_branch_id';
  static const String KEY_PRODUCT_TAX_INCLUSIVE = 'product_tax_inclusive';
  static const String KEY_SERVICE_TAX_INCLUSIVE = 'service_tax_inclusive';

  // Values
  bool _productTaxInclusive = false;
  bool _serviceTaxInclusive = false;

  // Getters
  bool get productTaxInclusive => _productTaxInclusive;
  bool get serviceTaxInclusive => _serviceTaxInclusive;
  static const String KEY_BUSINESS_NAME = 'business_name';
  static const String KEY_BUSINESS_ADDRESS = 'business_address';
  static const String KEY_BUSINESS_GSTIN = 'business_gstin';
  static const String KEY_BUSINESS_PHONE = 'business_phone';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Values
  Branch? _currentBranch;
  List<Branch> _branches = [];
  
  String _printerType = 'THERMAL_80';
  String _printerIp = '';
  String _backupEmail = '';

  // Getters
  Branch? get currentBranch => _currentBranch;
  List<Branch> get branches => _branches;
  int? get currentBranchId => _currentBranch?.id;
  String get businessName => _currentBranch?.name ?? 'My Shop';
  String get businessAddress => _currentBranch?.address ?? '';
  String get businessGstin => _currentBranch?.gstin ?? '';
  String get businessPhone => _currentBranch?.phone ?? '';
  
  String get printerType => _printerType;
  String get printerIp => _printerIp;
  String get backupEmail => _backupEmail;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    _prefs = await SharedPreferences.getInstance();
    
    await _initBranchLogic();
    await _loadBranches();

    // Load simple prefs
    _printerType = _prefs?.getString(KEY_PRINTER_TYPE) ?? 'THERMAL_80';
    _printerIp = _prefs?.getString(KEY_PRINTER_IP) ?? '';
    _backupEmail = _prefs?.getString(KEY_BACKUP_EMAIL) ?? '';
    _productTaxInclusive = _prefs?.getBool(KEY_PRODUCT_TAX_INCLUSIVE) ?? false;
    _serviceTaxInclusive = _prefs?.getBool(KEY_SERVICE_TAX_INCLUSIVE) ?? false;

    _isLoading = false;
    notifyListeners();
  }

  // ... (existing code) ...

  Future<void> updateTaxSettings({required bool productInclusive, required bool serviceInclusive}) async {
    _productTaxInclusive = productInclusive;
    _serviceTaxInclusive = serviceInclusive;
    notifyListeners();
    await _prefs?.setBool(KEY_PRODUCT_TAX_INCLUSIVE, productInclusive);
    await _prefs?.setBool(KEY_SERVICE_TAX_INCLUSIVE, serviceInclusive);
  }

  Future<void> _loadBranches() async {
    final db = await _dbHelper.database;
    final maps = await db.query('branches');
    _branches = maps.map((m) => Branch.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> _initBranchLogic() async {
    final db = await _dbHelper.database;
    final branchId = _prefs?.getInt(KEY_CURRENT_BRANCH_ID);
    
    if (branchId != null) {
      // Try fetching active branch
      final maps = await db.query('branches', where: 'id = ?', whereArgs: [branchId]);
      if (maps.isNotEmpty) {
        _currentBranch = Branch.fromMap(maps.first);
      }
    }

    // If still null, try to pick ANY active branch
    if (_currentBranch == null) {
       final maps = await db.query('branches', where: 'is_active = 1', limit: 1);
       if (maps.isNotEmpty) {
         _currentBranch = Branch.fromMap(maps.first);
         await _prefs?.setInt(KEY_CURRENT_BRANCH_ID, _currentBranch!.id!);
       }
    }

    // If STILL null (first run or migration needed)
    if (_currentBranch == null) {
      await _runBranchMigration(db);
    }
  }

  Future<void> _runBranchMigration(Database db) async {
    // Check if any branches exist
    final countRes = await db.rawQuery('SELECT COUNT(*) FROM branches');
    final count = countRes.first.values.first as int?;
    
    if (count != null && count > 0) {
      // Pick first one
      final maps = await db.query('branches', limit: 1);
      _currentBranch = Branch.fromMap(maps.first);
    } else {
      // Migration: Check legacy prefs
      final legacyName = _prefs?.getString(KEY_BUSINESS_NAME);
      if (legacyName != null) {
        // Create branch from legacy
        final newBranch = Branch(
          name: legacyName,
          address: _prefs?.getString(KEY_BUSINESS_ADDRESS) ?? '',
          phone: _prefs?.getString(KEY_BUSINESS_PHONE) ?? '',
          gstin: _prefs?.getString(KEY_BUSINESS_GSTIN),
        );
        final id = await db.insert('branches', newBranch.toMap());
        _currentBranch = Branch(
          id: id,
          name: newBranch.name,
          address: newBranch.address,
          phone: newBranch.phone,
          gstin: newBranch.gstin,
        );
      } else {
        // Create default
        final defaultBranch = Branch(
          name: 'My Shop', 
          address: 'Local Address', 
          phone: '',
        );
        final id = await db.insert('branches', defaultBranch.toMap());
        _currentBranch = Branch(
          id: id,
          name: defaultBranch.name,
          address: defaultBranch.address,
          phone: defaultBranch.phone,
        );
      }
    }
    
    // Save selection
    if (_currentBranch != null) {
      await _prefs?.setInt(KEY_CURRENT_BRANCH_ID, _currentBranch!.id!);
    }
  }

  Future<void> updateBusinessDetails(String name, String address, String gstin, String phone, String shortCode) async {
    if (_currentBranch == null) return;
    
    final db = await _dbHelper.database;
    final updatedBranch = Branch(
      id: _currentBranch!.id,
      name: name,
      address: address,
      phone: phone,
      gstin: gstin,
      shortCode: shortCode,
      isActive: _currentBranch!.isActive,
    );

    // Ensure column exists (Simple migration for dev)
    try {
      await db.update('branches', updatedBranch.toMap(), where: 'id = ?', whereArgs: [_currentBranch!.id]);
    } catch (e) {
      if (e.toString().contains('no such column: short_code')) {
        await db.execute('ALTER TABLE branches ADD COLUMN short_code TEXT');
        await db.update('branches', updatedBranch.toMap(), where: 'id = ?', whereArgs: [_currentBranch!.id]);
      } else {
        rethrow;
      }
    }
    
    _currentBranch = updatedBranch;
    await _loadBranches(); // Refresh list
    notifyListeners();
  }

  Future<void> updatePrinterSettings(String type, String ip) async {
    _printerType = type;
    _printerIp = ip;
    notifyListeners();
    
    await _prefs?.setString(KEY_PRINTER_TYPE, type);
    await _prefs?.setString(KEY_PRINTER_IP, ip);
  }

  Future<void> updateBackupSettings(String email) async {
    _backupEmail = email;
    notifyListeners();
    await _prefs?.setString(KEY_BACKUP_EMAIL, email);
  }

  // Backup Database
  Future<String?> backupDatabase() async {
     try {
       final documentsDirectory = await getApplicationDocumentsDirectory();
       final dbPath = p.join(documentsDirectory.path, 'automata_pos', 'automata.db');
       final file = File(dbPath);
       
       if (!await file.exists()) {
         return "Database file not found.";
       }

       String? result = await FilePicker.platform.saveFile(
         dialogTitle: 'Save Database Backup',
         fileName: 'automata_backup_${DateTime.now().millisecondsSinceEpoch}.db',
         type: FileType.any,
       );

       if (result != null) {
          await file.copy(result);
          return "Backup saved successfully to $result";
       }
       return null; // Cancelled
     } catch (e) {
       return "Backup failed: $e";
     }
  }

  // Restore Database
  Future<String?> restoreDatabase() async {
     try {
       final result = await FilePicker.platform.pickFiles(
         dialogTitle: 'Select Backup File',
         type: FileType.any,
         allowMultiple: false,
       );

       if (result != null && result.files.single.path != null) {
          final backupPath = result.files.single.path!;
          
          final documentsDirectory = await getApplicationDocumentsDirectory();
          final dbPath = p.join(documentsDirectory.path, 'automata_pos', 'automata.db');
          
          final backupFile = File(backupPath);
          await backupFile.copy(dbPath);
          
          return "Database restored. Please restart the application.";
       }
       return null; // Cancelled
     } catch (e) {
       return "Restore failed: $e";
     }
  }
}
