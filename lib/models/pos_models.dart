class Customer {
  final int? id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final DateTime createdAt;
  final int? membershipPlanId;
  final DateTime? membershipExpiry;
  final double advanceBalance;
  // New fields
  final String? gender;
  final DateTime? dob;
  final DateTime? doa;
  final int totalVisits;
  final String? state;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.createdAt,
    this.membershipPlanId,
    this.membershipExpiry,
    this.advanceBalance = 0,
    this.gender,
    this.dob,
    this.doa,
    this.totalVisits = 0,
    this.state,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'created_at': createdAt.toIso8601String(),
      'membership_plan_id': membershipPlanId,
      'membership_expiry': membershipExpiry?.toIso8601String(),
      'advance_balance': advanceBalance,
      'gender': gender,
      'dob': dob?.toIso8601String(),
      'doa': doa?.toIso8601String(),
      'state': state,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      membershipPlanId: map['membership_plan_id'],
      membershipExpiry: map['membership_expiry'] != null ? DateTime.parse(map['membership_expiry']) : null,
      advanceBalance: (map['advance_balance'] ?? 0.0).toDouble(),
      gender: map['gender'],
      dob: map['dob'] != null ? DateTime.parse(map['dob']) : null,
      doa: map['doa'] != null ? DateTime.parse(map['doa']) : null,
      totalVisits: map['total_visits'] ?? 0,
      state: map['state'],
    );
  }
}

class Product {
  final int? id;
  final String name;
  final String sku;
  final String barcode;
  final double price;
  final double stockQuantity;
  final String unit;
  final String category;
  final String? hsnCode;
  final double gstRate;
  
  // New Fields
  final double mrp;
  final bool isStockTracking;

  Product({
    this.id,
    required this.name,
    required this.sku,
    required this.barcode,
    required this.price,
    required this.stockQuantity,
    this.unit = 'Unit',
    this.category = 'General',
    this.hsnCode,
    this.gstRate = 0,
    this.mrp = 0, // Default to 0 if not provided
    this.isStockTracking = true, // Default to true
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'price': price,
      'stock_quantity': stockQuantity,
      'unit': unit,
      'category': category,
      'hsn_code': hsnCode,
      'gst_rate': gstRate,
      'mrp': mrp,
      'is_stock_tracking': isStockTracking ? 1 : 0,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'] ?? '',
      sku: map['sku'] ?? '',
      barcode: map['barcode'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      stockQuantity: (map['stock_quantity'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'Unit',
      category: map['category'] ?? 'General',
      hsnCode: map['hsn_code'],
      gstRate: (map['gst_rate'] ?? 0.0).toDouble(),
      mrp: (map['mrp'] ?? 0.0).toDouble(),
      isStockTracking: (map['is_stock_tracking'] ?? 1) == 1,
    );
  }
}

class Service {
  final int? id;
  final String name;
  final double rate;
  final String description;
  final String? hsnCode;
  final double gstRate;

  Service({
    this.id,
    required this.name,
    required this.rate,
    required this.description,
    this.hsnCode,
    this.gstRate = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rate': rate,
      'description': description,
      'hsn_code': hsnCode,
      'gst_rate': gstRate,
    };
  }

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'],
      name: map['name'] ?? '',
      rate: (map['rate'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      hsnCode: map['hsn_code'],
      gstRate: (map['gst_rate'] ?? 0.0).toDouble(),
    );
  }
}

enum InvoiceType { service, product, advance, membership }

enum InvoiceStatus { active, cancelled, hold, partial, completed }

class InvoicePayment {
  final int? id;
  final int? invoiceId;
  final double amount;
  final String mode; // CASH, UPI, CARD, ADVANCE
  final String? transactionId;
  final DateTime? paymentDate;

  InvoicePayment({
    this.id,
    this.invoiceId,
    required this.amount,
    required this.mode,
    this.transactionId,
    this.paymentDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'amount': amount,
      'mode': mode,
      'transaction_id': transactionId,
      'payment_date': (paymentDate ?? DateTime.now()).toIso8601String(),
    };
  }

  factory InvoicePayment.fromMap(Map<String, dynamic> map) {
    return InvoicePayment(
      id: map['id'],
      invoiceId: map['invoice_id'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      mode: map['mode'] ?? 'CASH',
      transactionId: map['transaction_id'],
      paymentDate: map['payment_date'] != null ? DateTime.parse(map['payment_date']) : null,
    );
  }
}

class Invoice {
  final int? id;
  final String invoiceNumber;
  final int? customerId;
  final int? branchId;
  final InvoiceType type;
  final String billType; // 'REGULAR' or 'ADVANCE'
  final double subTotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final InvoiceStatus status;
  final String? cancellationReason;
  final DateTime createdAt;
  final List<InvoiceItem> items;
  final List<InvoicePayment> payments; // New field
  final String? paymentMode; // Kept as primary/summary mode
  final String? notes;
  final double advanceAdjustedAmount;

  Invoice({
    this.id,
    required this.invoiceNumber,
    this.customerId,
    this.branchId,
    required this.type,
    this.billType = 'REGULAR',
    required this.subTotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.balanceAmount = 0.0,
    this.status = InvoiceStatus.completed,
    this.cancellationReason,
    required this.createdAt,
    this.items = const [],
    this.payments = const [], // New field
    this.paymentMode,
    this.notes,
    this.advanceAdjustedAmount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'branch_id': branchId,
      'type': type.name.toUpperCase(),
      'bill_type': billType,
      'sub_total': subTotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'balance_amount': balanceAmount,
      'status': status.name.toUpperCase(),
      'cancellation_reason': cancellationReason,
      'created_at': createdAt.toIso8601String(),
      'payment_mode': paymentMode,
      'notes': notes,
      'advance_adjusted_amount': advanceAdjustedAmount,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, {List<InvoiceItem> items = const [], List<InvoicePayment> payments = const []}) {
    return Invoice(
      id: map['id'],
      invoiceNumber: map['invoice_number'] ?? '',
      customerId: map['customer_id'],
      branchId: map['branch_id'],
      type: InvoiceType.values.firstWhere((e) => e.name.toUpperCase() == map['type'], orElse: () => InvoiceType.product),
      billType: map['bill_type'] ?? 'REGULAR',
      subTotal: (map['sub_total'] ?? 0.0).toDouble(),
      taxAmount: (map['tax_amount'] ?? 0.0).toDouble(),
      discountAmount: (map['discount_amount'] ?? 0.0).toDouble(),
      totalAmount: (map['total_amount'] ?? 0.0).toDouble(),
      paidAmount: (map['paid_amount'] ?? 0.0).toDouble(),
      balanceAmount: (map['balance_amount'] ?? 0.0).toDouble(),
      status: InvoiceStatus.values.firstWhere((e) => e.name.toUpperCase() == map['status'], orElse: () => InvoiceStatus.completed),
      cancellationReason: map['cancellation_reason'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      items: items,
      payments: payments, // New field map
      paymentMode: map['payment_mode'],
      notes: map['notes'],
      advanceAdjustedAmount: (map['advance_adjusted_amount'] ?? 0.0).toDouble(),
    );
  }
}

class Branch {
  final int? id;
  final String name;
  final String address;
  final String phone;
  final String? gstin;
  final String? shortCode;
  final bool isActive;
  final String? state;

  Branch({
    this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.gstin,
    this.shortCode,
    this.isActive = true,
    this.state,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'gstin': gstin,
      'short_code': shortCode,
      'is_active': isActive ? 1 : 0,
      'state': state,
    };
  }

  factory Branch.fromMap(Map<String, dynamic> map) {
    return Branch(
      id: map['id'],
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      gstin: map['gstin'],
      shortCode: map['short_code'],
      isActive: map['is_active'] == 1,
      state: map['state'],
    );
  }
}

class InvoiceItem {
  final int? id;
  final int? invoiceId;
  final int itemId;
  final String itemType; // 'PRODUCT' or 'SERVICE'
  final String name;
  final double quantity;
  final double rate;
  final double discount;
  final double total;
  
  final String? hsnCode;
  final double gstRate;
  final double cgst;
  final double sgst;
  final double igst;

  InvoiceItem({
    this.id,
    this.invoiceId,
    required this.itemId,
    required this.itemType,
    required this.name,
    required this.quantity,
    required this.rate,
    this.discount = 0.0,
    required this.total,
    this.hsnCode,
    this.gstRate = 0,
    this.cgst = 0,
    this.sgst = 0,
    this.igst = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'item_id': itemId,
      'item_type': itemType,
      'name': name,
      'quantity': quantity,
      'rate': rate,
      'discount': discount,
      'total': total,
      'hsn_code': hsnCode,
      'gst_rate': gstRate,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'],
      invoiceId: map['invoice_id'],
      itemId: map['item_id'] ?? 0,
      itemType: map['item_type'] ?? 'PRODUCT',
      name: map['name'] ?? '',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      rate: (map['rate'] ?? 0.0).toDouble(),
      discount: (map['discount'] ?? 0.0).toDouble(),
      total: (map['total'] ?? 0.0).toDouble(),
      hsnCode: map['hsn_code'],
      gstRate: (map['gst_rate'] ?? 0.0).toDouble(),
      cgst: (map['cgst'] ?? 0.0).toDouble(),
      sgst: (map['sgst'] ?? 0.0).toDouble(),
      igst: (map['igst'] ?? 0.0).toDouble(),
    );
  }

  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    int? itemId,
    String? itemType,
    String? name,
    double? quantity,
    double? rate,
    double? discount,
    double? total,
    String? hsnCode,
    double? gstRate,
    double? cgst,
    double? sgst,
    double? igst,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      hsnCode: hsnCode ?? this.hsnCode,
      gstRate: gstRate ?? this.gstRate,
      cgst: cgst ?? this.cgst,
      sgst: sgst ?? this.sgst,
      igst: igst ?? this.igst,
    );
  }
}

class HsnCode {
  final int? id;
  final String code;
  final String description;
  final double gstRate;
  final double cgstRate;
  final double sgstRate;
  final double igstRate;
  final double cessRate;
  final String type; // 'GOODS' or 'SERVICES'
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;

  HsnCode({
    this.id,
    required this.code,
    required this.description,
    required this.gstRate,
    this.cgstRate = 0,
    this.sgstRate = 0,
    this.igstRate = 0,
    this.cessRate = 0,
    this.type = 'GOODS',
    this.effectiveFrom,
    this.effectiveTo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'gst_rate': gstRate,
      'cgst_rate': cgstRate,
      'sgst_rate': sgstRate,
      'igst_rate': igstRate,
      'cess_rate': cessRate,
      'type': type,
      'effective_from': effectiveFrom?.toIso8601String(),
      'effective_to': effectiveTo?.toIso8601String(),
    };
  }

  factory HsnCode.fromMap(Map<String, dynamic> map) {
    return HsnCode(
      id: map['id'],
      code: map['code'] ?? '',
      description: map['description'] ?? '',
      gstRate: (map['gst_rate'] ?? 0.0).toDouble(),
      cgstRate: (map['cgst_rate'] ?? 0.0).toDouble(),
      sgstRate: (map['sgst_rate'] ?? 0.0).toDouble(),
      igstRate: (map['igst_rate'] ?? 0.0).toDouble(),
      cessRate: (map['cess_rate'] ?? 0.0).toDouble(),
      type: map['type'] ?? 'GOODS',
      effectiveFrom: map['effective_from'] != null ? DateTime.parse(map['effective_from']) : null,
      effectiveTo: map['effective_to'] != null ? DateTime.parse(map['effective_to']) : null,
    );
  }
}

class HsnTaxBreakdown {
  final String hsnCode; 
  final double baseAmount;
  final double gstRate;
  final double cgst;
  final double sgst;
  final double igst;
  final double totalTax;

  HsnTaxBreakdown({
    required this.hsnCode,
    required this.baseAmount,
    required this.gstRate,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.totalTax,
  });
}

class MembershipPlan {
  final int? id;
  final String name;
  final double price;
  final int durationMonths;
  final String description;
  final String discountType; // 'FLAT' or 'PERCENTAGE'
  final double discountValue;
  final double gstRate;
  final String? hsnCode;
  final String benefits;

  MembershipPlan({
    this.id,
    required this.name,
    required this.price,
    required this.durationMonths,
    this.description = '',
    this.discountType = 'FLAT',
    this.discountValue = 0.0,
    this.gstRate = 18.0,
    this.benefits = '',
    this.hsnCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'duration_months': durationMonths,
      'description': description,
      'discount_type': discountType,
      'discount_value': discountValue,
      'gst_rate': gstRate,
      'benefits': benefits,
      'hsn_code': hsnCode,
    };
  }

  factory MembershipPlan.fromMap(Map<String, dynamic> map) {
    return MembershipPlan(
      id: map['id'],
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      durationMonths: map['duration_months'] ?? 1,
      description: map['description'] ?? '',
      discountType: map['discount_type'] ?? 'FLAT',
      discountValue: (map['discount_value'] ?? 0.0).toDouble(),
      gstRate: (map['gst_rate'] ?? 18.0).toDouble(),
      benefits: map['benefits'] ?? '',
      hsnCode: map['hsn_code'],
    );
  }
}
