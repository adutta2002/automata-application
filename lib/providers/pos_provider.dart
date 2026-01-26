import 'package:flutter/material.dart';
import '../models/pos_models.dart';
import '../core/database_helper.dart';

class POSProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Product> _products = [];
  List<Service> _services = [];
  List<Customer> _customers = [];
  List<Invoice> _invoices = [];
  List<Branch> _branches = [];

  List<Product> get products => _products;
  List<Service> get services => _services;
  List<Customer> get customers => _customers;
  List<Invoice> get invoices => _invoices;
  List<Branch> get branches => _branches;

  Branch? getBranchById(int? id) {
    if (id == null) return null;
    try {
      return _branches.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadInitialData() async {
    final db = await _dbHelper.database;
    
    // Load Products
    final productMaps = await db.query('products');
    _products = productMaps.map((m) => Product.fromMap(m)).toList();

    // Load Services
    final serviceMaps = await db.query('services');
    _services = serviceMaps.map((m) => Service.fromMap(m)).toList();

    // Load Customers
    final customerMaps = await db.query('customers');
    _customers = customerMaps.map((m) => Customer.fromMap(m)).toList();

    // Load Invoices (Recent)
    final invoiceMaps = await db.query('invoices', orderBy: 'created_at DESC', limit: 50);
    _invoices = [];
    for (var map in invoiceMaps) {
      final itemMaps = await db.query('invoice_items', where: 'invoice_id = ?', whereArgs: [map['id']]);
      final items = itemMaps.map((im) => InvoiceItem.fromMap(im)).toList();
      _invoices.add(Invoice.fromMap(map, items: items));
    }

    // Load HSN Codes
    final hsnMaps = await db.query('hsn_master');
    _hsnCodes = hsnMaps.map((m) => HsnCode.fromMap(m)).toList();

    // Load Branches
    final branchMaps = await db.query('branches');
    _branches = branchMaps.map((m) => Branch.fromMap(m)).toList();

    // Load Membership Plans
    final planMaps = await db.query('membership_plans');
    _membershipPlans = planMaps.map((m) => MembershipPlan.fromMap(m)).toList();

    notifyListeners();
  }

  // --- Invoice Logic ---
  
  String generateInvoiceNumber() {
    // Get current branch short code
    // Since we don't have a direct reference to 'current branch' ID easily unless we store it in POSProvider too or check loaded branches.
    // However, SettingsProvider manages the "Current Branch". POSProvider loads 'branches'.
    // Ideally, the UI passes the Short Code or POSProvider knows the active branch.
    // Let's assume the first branch is active or we need to inject SettingsProvider. 
    // BUT, a simpler way for now: Look for the active branch in _branches.
    
    String prefix = 'INV';
    try {
      final activeBranch = _branches.firstWhere((b) => b.isActive, orElse: () => _branches.first);
      if (activeBranch.shortCode != null && activeBranch.shortCode!.isNotEmpty) {
        prefix = activeBranch.shortCode!;
      }
    } catch (_) {}

    final now = DateTime.now();
    final datePart = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final timePart = "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";
    
    return "$prefix-$datePart-$timePart";
  }
  
  Future<void> createInvoice(Invoice invoice) async {
    if (invoice.branchId == null) {
       debugPrint('WARNING: Attempting to create invoice without branchId. This is required for sync.');
       // Optionally throw an error or handle it as per requirement
    }

    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final invoiceId = await txn.insert('invoices', invoice.toMap());
      for (var item in invoice.items) {
        await txn.insert('invoice_items', {
          ...item.toMap(),
          'invoice_id': invoiceId,
        });

        // Deduct stock if it's a product
        if (item.itemType == 'PRODUCT') {
          // Check stock first
          final productRes = await txn.query('products', columns: ['stock_quantity', 'name'], where: 'id = ?', whereArgs: [item.itemId]);
          if (productRes.isNotEmpty) {
            final currentStock = productRes.first['stock_quantity'] as double;
            if (currentStock < item.quantity) {
               throw Exception('Insufficient stock for ${productRes.first['name']} (Available: ${currentStock.toInt()})');
            }
            
            await txn.rawUpdate(
              'UPDATE products SET stock_quantity = stock_quantity - ? WHERE id = ?',
              [item.quantity, item.itemId],
            );
          }
        }
      }

      // Handle Membership Activation
      if (invoice.type == InvoiceType.membership && invoice.customerId != null) {
         // ... (existing membership logic remains same) ...
        final membershipItem = invoice.items.firstWhere((i) => i.itemType == 'MEMBERSHIP');
        final planId = membershipItem.itemId;
        
        // Fetch plan to get duration
        final planMaps = await txn.query('membership_plans', where: 'id = ?', whereArgs: [planId]);
        if (planMaps.isNotEmpty) {
          final plan = MembershipPlan.fromMap(planMaps.first);
          // FIX: Use invoice date, not current time, to allow backdated memberships
          final startDate = invoice.createdAt;
          final expiry = startDate.add(Duration(days: plan.durationMonths * 30)); // Approx
          
          await txn.update(
            'customers',
            {
              'membership_plan_id': planId,
              'membership_expiry': expiry.toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [invoice.customerId],
          );
        }
      }

      // Handle Advance Invoice (Credit Advance)
      if (invoice.type == InvoiceType.advance && invoice.customerId != null) {
        await txn.rawUpdate(
          'UPDATE customers SET advance_balance = advance_balance + ? WHERE id = ?',
          [invoice.totalAmount, invoice.customerId],
        );
      }

      // Handle Advance Adjustment (Debit Advance)
      if ((invoice.type == InvoiceType.product || invoice.type == InvoiceType.service) && invoice.customerId != null && invoice.advanceAdjustedAmount > 0) {
         await txn.rawUpdate(
          'UPDATE customers SET advance_balance = advance_balance - ? WHERE id = ?',
          [invoice.advanceAdjustedAmount, invoice.customerId],
        );
      }

    });
    await loadInitialData();
  }

  Future<void> updateInvoice(Invoice invoice) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
       // 1. Revert Stock for OLD items (only if they were PRODUCTS)
       // Fetch existing items for this invoice
       final oldItemsRes = await txn.query('invoice_items', where: 'invoice_id = ?', whereArgs: [invoice.id]);
       for (var map in oldItemsRes) {
         if (map['item_type'] == 'PRODUCT') {
           final qty = map['quantity'] as double;
           final itemId = map['item_id'] as int;
           await txn.rawUpdate(
             'UPDATE products SET stock_quantity = stock_quantity + ? WHERE id = ?',
             [qty, itemId]
           );
         }
       }

       // 2. Clear old items
       await txn.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [invoice.id]);

       // 3. Update Invoice Header
       await txn.update('invoices', invoice.toMap(), where: 'id = ?', whereArgs: [invoice.id]);

       // 4. Insert NEW items and Deduct Stock
       for (var item in invoice.items) {
          await txn.insert('invoice_items', {
            ...item.toMap(),
            'invoice_id': invoice.id,
          });

          if (item.itemType == 'PRODUCT') {
             // Check stock (considering we just added back the old stock, so we are validating against current available)
             final productRes = await txn.query('products', columns: ['stock_quantity', 'name'], where: 'id = ?', whereArgs: [item.itemId]);
             if (productRes.isNotEmpty) {
               final currentStock = productRes.first['stock_quantity'] as double;
               if (currentStock < item.quantity) {
                  throw Exception('Insufficient stock for ${productRes.first['name']} (Available: ${currentStock.toInt()})');
               }
               
               await txn.rawUpdate(
                 'UPDATE products SET stock_quantity = stock_quantity - ? WHERE id = ?',
                 [item.quantity, item.itemId],
               );
             }
          }
       }
       
       // Handle Customer Balances - Revert old effect and apply new?
       // For simplicity in this 'Hold' flow:
       // Typically 'Hold' invoices don't affect balance/stock until finalized. 
       // BUT our current implementation of `createInvoice` writes to DB immediately even for Hold.
       // So if we edit a Hold invoice, we validly need to revert its previous effects.
       
       // Revert Advance Adjustment (Debit) if any
       final oldInvoiceRes = await txn.query('invoices', where: 'id = ?', whereArgs: [invoice.id]);
       if (oldInvoiceRes.isNotEmpty && invoice.customerId != null) {
          final oldInv = Invoice.fromMap(oldInvoiceRes.first);
          if (oldInv.advanceAdjustedAmount > 0) {
             await txn.rawUpdate(
              'UPDATE customers SET advance_balance = advance_balance + ? WHERE id = ?',
              [oldInv.advanceAdjustedAmount, invoice.customerId],
            );
          }
          // If it was an Advance Payment invoice?
          if (oldInv.type == InvoiceType.advance) {
             await txn.rawUpdate(
              'UPDATE customers SET advance_balance = advance_balance - ? WHERE id = ?',
              [oldInv.totalAmount, invoice.customerId],
            );
          }
       }

       // Apply NEW Advance effects
       if (invoice.type == InvoiceType.advance && invoice.customerId != null) {
          await txn.rawUpdate(
            'UPDATE customers SET advance_balance = advance_balance + ? WHERE id = ?',
            [invoice.totalAmount, invoice.customerId],
          );
       }
       if ((invoice.type == InvoiceType.product || invoice.type == InvoiceType.service) && invoice.customerId != null && invoice.advanceAdjustedAmount > 0) {
           await txn.rawUpdate(
            'UPDATE customers SET advance_balance = advance_balance - ? WHERE id = ?',
            [invoice.advanceAdjustedAmount, invoice.customerId],
          );
       }
       
       // Membership update logic is tricky on edit - assumed we just overwrite expiry if active plan matches
       // (Skipping for brevity as Hold usually for products/services)
    });
    
    await loadInitialData();
  }

  Future<void> cancelInvoice(int invoiceId, String reason) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.update(
        'invoices',
        {'status': 'CANCELLED', 'cancellation_reason': reason},
        where: 'id = ?',
        whereArgs: [invoiceId],
      );

      // Restore stock
      final itemMaps = await txn.query('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);
      for (var map in itemMaps) {
        if (map['item_type'] == 'PRODUCT') {
          await txn.rawUpdate(
            'UPDATE products SET stock_quantity = stock_quantity + ? WHERE id = ?',
            [map['quantity'], map['item_id']],
          );
        }
      }
    });
    await loadInitialData();
  }

  // --- Product/Service Management ---

  Future<void> addProduct(Product product) async {
    final db = await _dbHelper.database;
    
    // Auto-generate SKU if empty to avoid UNIQUE constraint violation
    var productToInsert = product;
    if (product.sku.isEmpty) {
      final autoSku = 'SKU-${DateTime.now().millisecondsSinceEpoch}';
      productToInsert = Product(
        id: product.id,
        name: product.name,
        sku: autoSku,
        barcode: product.barcode,
        price: product.price,
        stockQuantity: product.stockQuantity,
        unit: product.unit,
        category: product.category,
        hsnCode: product.hsnCode,
        gstRate: product.gstRate,
      );
    }
    
    await db.insert('products', productToInsert.toMap());
    await loadInitialData();
  }

  Future<void> addService(Service service) async {
    final db = await _dbHelper.database;
    await db.insert('services', service.toMap());
    await loadInitialData();
  }

  // --- CRUD for Products/Services ---

  Future<void> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    await db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
    await loadInitialData();
  }

  Future<void> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
    await loadInitialData();
  }

  Future<void> updateService(Service service) async {
    final db = await _dbHelper.database;
    await db.update('services', service.toMap(), where: 'id = ?', whereArgs: [service.id]);
    await loadInitialData();
  }
  
  Future<void> deleteService(int id) async {
    final db = await _dbHelper.database;
    await db.delete('services', where: 'id = ?', whereArgs: [id]);
    await loadInitialData();
  }

  Future<Customer> addCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    final id = await db.insert('customers', customer.toMap());
    await loadInitialData();
    return Customer(
      id: id,
      name: customer.name,
      phone: customer.phone,
      email: customer.email,
      address: customer.address,
      createdAt: customer.createdAt,
    );
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    await db.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
    await loadInitialData();
  }

  Future<void> deleteCustomer(int id) async {
    final db = await _dbHelper.database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
    await loadInitialData();
  }

  // --- HSN Management ---
  List<HsnCode> _hsnCodes = [];
  List<HsnCode> get hsnCodes => _hsnCodes;

  Future<void> addHsnCode(HsnCode hsn) async {
    final db = await _dbHelper.database;
    await db.insert('hsn_master', hsn.toMap());
    await loadInitialData();
  }

  Future<void> updateHsnCode(HsnCode hsn) async {
    final db = await _dbHelper.database;
    await db.update('hsn_master', hsn.toMap(), where: 'id = ?', whereArgs: [hsn.id]);
    await loadInitialData();
  }

  Future<void> deleteHsnCode(int id) async {
    final db = await _dbHelper.database;
    await db.delete('hsn_master', where: 'id = ?', whereArgs: [id]);
    await loadInitialData();
  }

  // --- Membership Plan Management ---
  List<MembershipPlan> _membershipPlans = [];
  List<MembershipPlan> get membershipPlans => _membershipPlans;

  Future<void> addMembershipPlan(MembershipPlan plan) async {
    final db = await _dbHelper.database;
    await db.insert('membership_plans', plan.toMap());
    await loadInitialData();
  }

  Future<void> updateMembershipPlan(MembershipPlan plan) async {
    final db = await _dbHelper.database;
    await db.update('membership_plans', plan.toMap(), where: 'id = ?', whereArgs: [plan.id]);
    await loadInitialData();
  }

  Future<void> deleteMembershipPlan(int id) async {
    final db = await _dbHelper.database;
    await db.delete('membership_plans', where: 'id = ?', whereArgs: [id]);
    await loadInitialData();
  }
  Future<void> generateMasterData() async {
    final db = await _dbHelper.database;
    
    // Check if data already exists to avoid duplicates/overwrite
    if (_products.isNotEmpty || _customers.isNotEmpty) {
      debugPrint('Data already exists, skipping generation');
      return; 
    }

    await db.transaction((txn) async {
       // 1. Branch
      await txn.insert('branches', {
         'name': 'Main Branch',
         'address': '123 Market Street, City Center',
         'phone': '9876543210',
         'gstin': '29ABCDE1234F1Z5',
         'short_code': 'MAB',
         'is_active': 1
      });

      // 2. HSN Codes
      final hsnList = [
         {'code': '3304', 'description': 'Beauty Preparations', 'gst_rate': 18.0, 'type': 'GOODS'},
         {'code': '9997', 'description': 'Salon Services', 'gst_rate': 18.0, 'type': 'SERVICES'},
         {'code': '8516', 'description': 'Electric Heaters', 'gst_rate': 12.0, 'type': 'GOODS'},
      ];
      for (var h in hsnList) {
        await txn.insert('hsn_master', h);
      }

      // 3. Products
      final products = [
        {'name': 'Loreal Shampoo', 'sku': 'LOR-SH-250', 'barcode': '8901234567890', 'price': 450.0, 'stock_quantity': 50.0, 'unit': 'Bottle', 'category': 'Hair Care', 'hsn_code': '3304', 'gst_rate': 18.0},
        {'name': 'Matrix Conditioner', 'sku': 'MAT-CN-200', 'barcode': '8901234567891', 'price': 380.0, 'stock_quantity': 30.0, 'unit': 'Bottle', 'category': 'Hair Care', 'hsn_code': '3304', 'gst_rate': 18.0},
        {'name': 'Face Serum', 'sku': 'SER-GL-30', 'barcode': '8901234567892', 'price': 1200.0, 'stock_quantity': 15.0, 'unit': 'Piece', 'category': 'Skin Care', 'hsn_code': '3304', 'gst_rate': 18.0},
        {'name': 'Hair Dryer', 'sku': 'EQ-HDR-01', 'barcode': '8901234567893', 'price': 2500.0, 'stock_quantity': 5.0, 'unit': 'Piece', 'category': 'Equipment', 'hsn_code': '8516', 'gst_rate': 12.0},
      ];
      for (var p in products) {
        await txn.insert('products', p);
      }

      // 4. Services
      final services = [
        {'name': 'Men Haircut', 'rate': 250.0, 'description': 'Standard haircut', 'hsn_code': '9997', 'gst_rate': 18.0},
        {'name': 'Women Haircut', 'rate': 500.0, 'description': 'Layered cut', 'hsn_code': '9997', 'gst_rate': 18.0},
        {'name': 'Facial Cleanup', 'rate': 800.0, 'description': 'Basic cleanup', 'hsn_code': '9997', 'gst_rate': 18.0},
        {'name': 'Full Body Massage', 'rate': 1500.0, 'description': '60 min session', 'hsn_code': '9997', 'gst_rate': 18.0},
      ];
      for (var s in services) {
        await txn.insert('services', s);
      }

      // 5. Membership Plans
      final plans = [
        {'name': 'Gold Member', 'price': 5000.0, 'duration_months': 12, 'description': '10% off services', 'discount_type': 'PERCENTAGE', 'discount_value': 10.0, 'gst_rate': 18.0, 'benefits': 'Priority booking, 10% off'},
        {'name': 'Silver Member', 'price': 2500.0, 'duration_months': 6, 'description': '5% off services', 'discount_type': 'PERCENTAGE', 'discount_value': 5.0, 'gst_rate': 18.0, 'benefits': '5% off'},
      ];
      for (var pl in plans) {
        await txn.insert('membership_plans', pl);
      }

      // 6. Customers
       final customers = [
        {'name': 'Rahul Sharma', 'phone': '9876543210', 'email': 'rahul@example.com', 'address': 'Bangalore', 'created_at': DateTime.now().toIso8601String()},
        {'name': 'Priya Singh', 'phone': '9876543211', 'email': 'priya@example.com', 'address': 'Mumbai', 'created_at': DateTime.now().toIso8601String()},
        {'name': 'Amit Verma', 'phone': '9876543212', 'email': 'amit@example.com', 'address': 'Delhi', 'created_at': DateTime.now().toIso8601String()},
      ];
      for (var c in customers) {
        await txn.insert('customers', c);
      }
    });

    await loadInitialData();
  }
}
