import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bcrypt/bcrypt.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'automata_pos', 'automata.db');

    // Ensure the directory exists
    final file = File(path);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    return await openDatabase(
      path,
      version: 19,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Users Table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL,
        role TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        last_login TEXT
      )
    ''');

    // 2. Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        address TEXT,
        created_at TEXT NOT NULL,
        membership_plan_id INTEGER,
        membership_expiry TEXT,
        advance_balance REAL DEFAULT 0,
        gender TEXT,
        dob TEXT,
        doa TEXT,
        state TEXT
      )
    ''');

    // 3. Products Table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sku TEXT,
        barcode TEXT,
        price REAL NOT NULL,
        stock_quantity REAL NOT NULL,
        unit TEXT DEFAULT 'Unit',
        category TEXT DEFAULT 'General',
        hsn_code TEXT,
        gst_rate REAL DEFAULT 0
      )
    ''');

    // 4. Services Table
    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        rate REAL NOT NULL,
        description TEXT,
        hsn_code TEXT,
        gst_rate REAL DEFAULT 0
      )
    ''');

    // 5. Branches Table
    await db.execute('''
      CREATE TABLE branches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT NOT NULL,
        gstin TEXT,
        short_code TEXT,
        is_active INTEGER DEFAULT 1,
        state TEXT
      )
    ''');

    // 6. Invoices Table
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT UNIQUE NOT NULL,
        customer_id INTEGER,
        branch_id INTEGER,
        type TEXT NOT NULL,
        bill_type TEXT DEFAULT 'REGULAR',
        sub_total REAL NOT NULL,
        tax_amount REAL NOT NULL,
        discount_amount REAL NOT NULL,
        total_amount REAL NOT NULL,
        paid_amount REAL DEFAULT 0,
        balance_amount REAL DEFAULT 0,
        status TEXT DEFAULT 'ACTIVE',
        cancellation_reason TEXT,
        created_at TEXT NOT NULL,
        payment_mode TEXT,
        notes TEXT,
        advance_adjusted_amount REAL DEFAULT 0,
        FOREIGN KEY (customer_id) REFERENCES customers (id),
        FOREIGN KEY (branch_id) REFERENCES branches (id)
      )
    ''');

    // 7. Invoice Items Table
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        item_type TEXT NOT NULL,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        rate REAL NOT NULL,
        discount REAL DEFAULT 0,
        total REAL NOT NULL,
        hsn_code TEXT,
        gst_rate REAL DEFAULT 0,
        cgst REAL DEFAULT 0,
        sgst REAL DEFAULT 0,
        igst REAL DEFAULT 0,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // 8. HSN Master Table
    await db.execute('''
      CREATE TABLE hsn_master (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        description TEXT,
        gst_rate REAL DEFAULT 0,
        type TEXT DEFAULT 'GOODS',
        effective_from TEXT,
        effective_to TEXT
      )
    ''');

    // 9. Membership Plans Table
    await db.execute('''
      CREATE TABLE membership_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        duration_months INTEGER DEFAULT 1,
        description TEXT,
        discount_type TEXT DEFAULT 'FLAT',
        discount_value REAL DEFAULT 0.0,
        gst_rate REAL DEFAULT 18.0,
        benefits TEXT DEFAULT '',
        hsn_code TEXT
      )
    ''');

    // Create default admin user
    await _createDefaultAdmin(db);

    // 10. Invoice Payments Table (Version 17)
    await db.execute('''
      CREATE TABLE invoice_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        mode TEXT NOT NULL,
        transaction_id TEXT,
        payment_date TEXT,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 17) {
       await db.execute('''
        CREATE TABLE IF NOT EXISTS invoice_payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          invoice_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          mode TEXT NOT NULL,
          transaction_id TEXT,
          payment_date TEXT,
          FOREIGN KEY (invoice_id) REFERENCES invoices (id)
        )
      ''');
    }
    
    // Previous upgrade logic (if any specific column additions were needed previously, they'd be here)
    // For now we just focus on the new table
    // Previous upgrade logic continues below

    if (oldVersion < 5) {
      // Version 5: HSN Master
      await db.execute('''
        CREATE TABLE hsn_master (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT UNIQUE NOT NULL,
          description TEXT,
          gst_rate REAL DEFAULT 0
        )
      ''');
    }

    if (oldVersion < 6) {
      // Version 6: HSN Enhancements
      await db.execute("ALTER TABLE hsn_master ADD COLUMN type TEXT DEFAULT 'GOODS'");
      await db.execute("ALTER TABLE hsn_master ADD COLUMN effective_from TEXT");
      await db.execute("ALTER TABLE hsn_master ADD COLUMN effective_to TEXT");
    }

    if (oldVersion < 7) {
      // Version 7: Branches
      await db.execute('''
        CREATE TABLE branches (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          address TEXT NOT NULL,
          phone TEXT NOT NULL,
          gstin TEXT,
          is_active INTEGER DEFAULT 1
        )
      ''');
      
      await db.execute("ALTER TABLE invoices ADD COLUMN branch_id INTEGER REFERENCES branches(id)");
    }

    if (oldVersion < 8) {
      // Version 8: Membership Plans
      await db.execute('''
        CREATE TABLE membership_plans (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          price REAL NOT NULL,
          duration_months INTEGER DEFAULT 1,
          description TEXT
        )
      ''');
    }

    if (oldVersion < 9) {
      // Version 9: Membership Plan Benefits & Tax
      // SQLite doesn't support multiple columns in one ADD COLUMN statement
      try { await db.execute("ALTER TABLE membership_plans ADD COLUMN discount_type TEXT DEFAULT 'FLAT'"); } catch (_) {}
      try { await db.execute("ALTER TABLE membership_plans ADD COLUMN discount_value REAL DEFAULT 0.0"); } catch (_) {}
      try { await db.execute("ALTER TABLE membership_plans ADD COLUMN gst_rate REAL DEFAULT 18.0"); } catch (_) {}
      try { await db.execute("ALTER TABLE membership_plans ADD COLUMN benefits TEXT DEFAULT ''"); } catch (_) {}
    }

    if (oldVersion < 10) {
      // Version 10: Customer Membership Tracking
      try {
        await db.execute("ALTER TABLE customers ADD COLUMN membership_plan_id INTEGER");
        await db.execute("ALTER TABLE customers ADD COLUMN membership_expiry TEXT");
      } catch (e) {
        // ignore
      }
    }

    if (oldVersion < 11) {
      // Version 11: Advance Invoice
      try {
        await db.execute("ALTER TABLE invoices ADD COLUMN payment_mode TEXT");
        await db.execute("ALTER TABLE invoices ADD COLUMN notes TEXT");
        await db.execute("ALTER TABLE invoices ADD COLUMN advance_adjusted_amount REAL DEFAULT 0");
        await db.execute("ALTER TABLE customers ADD COLUMN advance_balance REAL DEFAULT 0");
      } catch (e) {
        // ignore
      }
    }

    if (oldVersion < 12) {
      // Version 12: Retry Advance Invoice columns in case v11 failed partially
      List<String> commands = [
        "ALTER TABLE invoices ADD COLUMN payment_mode TEXT",
        "ALTER TABLE invoices ADD COLUMN notes TEXT",
        "ALTER TABLE invoices ADD COLUMN advance_adjusted_amount REAL DEFAULT 0",
        "ALTER TABLE customers ADD COLUMN advance_balance REAL DEFAULT 0"
      ];
      
      for (var cmd in commands) {
        try {
          await db.execute(cmd);
        } catch (e) {
          // Ignore "duplicate column" errors if they were partially added
          debugPrint('Migration v12 warning (safe to ignore if column exists): $e');
        }
      }
    }
    
    if (oldVersion < 13) {
      // Version 13: Ensure Membership Plan columns and Add Short Code to Branch in case missing
      List<String> commands = [
        "ALTER TABLE membership_plans ADD COLUMN discount_type TEXT DEFAULT 'FLAT'",
        "ALTER TABLE membership_plans ADD COLUMN discount_value REAL DEFAULT 0.0",
        "ALTER TABLE membership_plans ADD COLUMN gst_rate REAL DEFAULT 18.0",
        "ALTER TABLE membership_plans ADD COLUMN benefits TEXT DEFAULT ''",
        "ALTER TABLE branches ADD COLUMN short_code TEXT"
      ];
      
      for (var cmd in commands) {
        try {
          await db.execute(cmd);
        } catch (e) {
          debugPrint('Migration v13 warning (safe to ignore): $e');
        }
      }
    }

    if (oldVersion < 14) {
      // Version 14: Customer Gender, DOB, DOA
      Directory('/tmp').createSync(recursive: true); // Dummy call to ensure fs access if needed (not needed here but good practice in some envs)

      try { await db.execute("ALTER TABLE customers ADD COLUMN gender TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE customers ADD COLUMN dob TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE customers ADD COLUMN doa TEXT"); } catch (_) {}
    }

    if (oldVersion < 15) {
      // Version 15: Membership Plan HSN Code
      try { await db.execute("ALTER TABLE membership_plans ADD COLUMN hsn_code TEXT"); } catch (_) {}
    }

    if (oldVersion < 16) {
      // Version 16: Integrated Advance Invoice (Bill Type, Paid, Balance)
      try { await db.execute("ALTER TABLE invoices ADD COLUMN bill_type TEXT DEFAULT 'REGULAR'"); } catch (_) {}
      try { await db.execute("ALTER TABLE invoices ADD COLUMN paid_amount REAL DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE invoices ADD COLUMN balance_amount REAL DEFAULT 0"); } catch (_) {}
    }
    if (oldVersion < 18) {
      // Version 18: HSN Configurable GST Split
      try { await db.execute("ALTER TABLE hsn_master ADD COLUMN cgst_rate REAL DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE hsn_master ADD COLUMN sgst_rate REAL DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE hsn_master ADD COLUMN igst_rate REAL DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE hsn_master ADD COLUMN cess_rate REAL DEFAULT 0"); } catch (_) {}
    }
    if (oldVersion < 19) {
      // Version 19: State field for IGST Logic
      try { await db.execute("ALTER TABLE branches ADD COLUMN state TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE customers ADD COLUMN state TEXT"); } catch (_) {}
    }
  }

  Future<void> _createDefaultAdmin(Database db) async {
    final passwordHash = BCrypt.hashpw('admin123', BCrypt.gensalt());
    
    await db.insert('users', {
      'username': 'admin',
      'password_hash': passwordHash,
      'full_name': 'Administrator',
      'role': 'ADMIN',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
