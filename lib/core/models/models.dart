import 'package:hive/hive.dart';

/// Product Model
@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sku;

  @HiveField(2)
  final String? category;

  @HiveField(3)
  final String? subcategory;

  @HiveField(4)
  final String? productType;

  @HiveField(5)
  final String? description;

  @HiveField(6)
  final String? voltage;

  @HiveField(7)
  final String? amperage;

  @HiveField(8)
  final String? phase;

  @HiveField(9)
  final String? frequency;

  @HiveField(10)
  final String? plugType;

  @HiveField(11)
  final String? dimensions;

  @HiveField(12)
  final String? dimensionsMetric;

  @HiveField(13)
  final String? weight;

  @HiveField(14)
  final String? weightMetric;

  @HiveField(15)
  final String? temperatureRange;

  @HiveField(16)
  final String? temperatureRangeMetric;

  @HiveField(17)
  final String? refrigerant;

  @HiveField(18)
  final String? compressor;

  @HiveField(19)
  final String? capacity;

  @HiveField(20)
  final String? doors;

  @HiveField(21)
  final String? shelves;

  @HiveField(22)
  final String? features;

  @HiveField(23)
  final String? certifications;

  @HiveField(24)
  final double? price;

  @HiveField(25)
  final DateTime? createdAt;

  @HiveField(26)
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.sku,
    this.category,
    this.subcategory,
    this.productType,
    this.description,
    this.voltage,
    this.amperage,
    this.phase,
    this.frequency,
    this.plugType,
    this.dimensions,
    this.dimensionsMetric,
    this.weight,
    this.weightMetric,
    this.temperatureRange,
    this.temperatureRangeMetric,
    this.refrigerant,
    this.compressor,
    this.capacity,
    this.doors,
    this.shelves,
    this.features,
    this.certifications,
    this.price,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      sku: json['sku'] ?? '',
      category: json['category'],
      subcategory: json['subcategory'],
      productType: json['product_type'],
      description: json['description'],
      voltage: json['voltage'],
      amperage: json['amperage'],
      phase: json['phase'],
      frequency: json['frequency'],
      plugType: json['plug_type'],
      dimensions: json['dimensions'],
      dimensionsMetric: json['dimensions_metric'],
      weight: json['weight'],
      weightMetric: json['weight_metric'],
      temperatureRange: json['temperature_range'],
      temperatureRangeMetric: json['temperature_range_metric'],
      refrigerant: json['refrigerant'],
      compressor: json['compressor'],
      capacity: json['capacity'],
      doors: json['doors'],
      shelves: json['shelves'],
      features: json['features'],
      certifications: json['certifications'],
      price: json['price']?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'category': category,
      'subcategory': subcategory,
      'product_type': productType,
      'description': description,
      'voltage': voltage,
      'amperage': amperage,
      'phase': phase,
      'frequency': frequency,
      'plug_type': plugType,
      'dimensions': dimensions,
      'dimensions_metric': dimensionsMetric,
      'weight': weight,
      'weight_metric': weightMetric,
      'temperature_range': temperatureRange,
      'temperature_range_metric': temperatureRangeMetric,
      'refrigerant': refrigerant,
      'compressor': compressor,
      'capacity': capacity,
      'doors': doors,
      'shelves': shelves,
      'features': features,
      'certifications': certifications,
      'price': price,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get displayName => productType ?? sku;
  String get imageUrl => 'assets/screenshots/$sku/$sku P.1.png';
}

/// Client Model
@HiveType(typeId: 1)
class Client extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String company;

  @HiveField(3)
  final String? contactName;

  @HiveField(4)
  final String? contactEmail;

  @HiveField(5)
  final String? contactNumber;

  @HiveField(6)
  final String? address;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  @HiveField(9)
  bool isSynced;

  Client({
    required this.id,
    required this.userId,
    required this.company,
    this.contactName,
    this.contactEmail,
    this.contactNumber,
    this.address,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = true,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      company: json['company'] ?? '',
      contactName: json['contact_name'],
      contactEmail: json['contact_email'],
      contactNumber: json['contact_number'],
      address: json['address'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      isSynced: json['is_synced'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'company': company,
      'contact_name': contactName,
      'contact_email': contactEmail,
      'contact_number': contactNumber,
      'address': address,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced,
    };
  }
}

/// Quote Model
@HiveType(typeId: 2)
class Quote extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String clientId;

  @HiveField(3)
  final String quoteNumber;

  @HiveField(4)
  final double subtotal;

  @HiveField(5)
  final double taxRate;

  @HiveField(6)
  final double taxAmount;

  @HiveField(7)
  final double totalAmount;

  @HiveField(8)
  final String status;

  @HiveField(9)
  final List<QuoteItem> items;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final DateTime updatedAt;

  @HiveField(12)
  bool isSynced;

  Quote({
    required this.id,
    required this.userId,
    required this.clientId,
    required this.quoteNumber,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.totalAmount,
    this.status = 'draft',
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = true,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      clientId: json['client_id'] ?? '',
      quoteNumber: json['quote_number'] ?? '',
      subtotal: json['subtotal']?.toDouble() ?? 0.0,
      taxRate: json['tax_rate']?.toDouble() ?? 0.0,
      taxAmount: json['tax_amount']?.toDouble() ?? 0.0,
      totalAmount: json['total_amount']?.toDouble() ?? 0.0,
      status: json['status'] ?? 'draft',
      items: (json['quote_items'] as List?)
              ?.map((e) => QuoteItem.fromJson(e))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      isSynced: json['is_synced'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'client_id': clientId,
      'quote_number': quoteNumber,
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'status': status,
      'quote_items': items.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced,
    };
  }
}

/// Quote Item Model
@HiveType(typeId: 3)
class QuoteItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String quoteId;

  @HiveField(2)
  final String productId;

  @HiveField(3)
  final int quantity;

  @HiveField(4)
  final double unitPrice;

  @HiveField(5)
  final double totalPrice;

  @HiveField(6)
  Product? product;

  QuoteItem({
    required this.id,
    required this.quoteId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.product,
  });

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      id: json['id'] ?? '',
      quoteId: json['quote_id'] ?? '',
      productId: json['product_id'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: json['unit_price']?.toDouble() ?? 0.0,
      totalPrice: json['total_price']?.toDouble() ?? 0.0,
      product:
          json['product'] != null ? Product.fromJson(json['product']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quote_id': quoteId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'product': product?.toJson(),
    };
  }
}

/// Cart Item Model
@HiveType(typeId: 4)
class CartItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String? clientId;

  @HiveField(3)
  final String productId;

  @HiveField(4)
  int quantity;

  @HiveField(5)
  Product? product;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  @HiveField(8)
  bool isSynced;

  CartItem({
    required this.id,
    required this.userId,
    this.clientId,
    required this.productId,
    required this.quantity,
    this.product,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = true,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      clientId: json['client_id'],
      productId: json['product_id'] ?? '',
      quantity: json['quantity'] ?? 1,
      product:
          json['products'] != null ? Product.fromJson(json['products']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      isSynced: json['is_synced'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'client_id': clientId,
      'product_id': productId,
      'quantity': quantity,
      'products': product?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced,
    };
  }

  void updateQuantity(int newQuantity) {
    quantity = newQuantity;
    updatedAt = DateTime.now();
    isSynced = false;
    save();
  }
}

/// User Profile Model
class UserProfile {
  final String id;
  final String email;
  final String role;
  final String? company;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    this.role = 'distributor',
    this.company,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'distributor',
      company: json['company'],
      phone: json['phone'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'company': company,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isSales => role == 'sales';
  bool get isDistributor => role == 'distributor';
}

/// Sync Queue Model for offline changes
@HiveType(typeId: 5)
class SyncQueueItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String tableName;

  @HiveField(2)
  final String operation;

  @HiveField(3)
  final Map<String, dynamic> data;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  bool synced;

  SyncQueueItem({
    required this.id,
    required this.tableName,
    required this.operation,
    required this.data,
    required this.createdAt,
    this.synced = false,
  });

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      id: json['id'] ?? '',
      tableName: json['table_name'] ?? '',
      operation: json['operation'] ?? '',
      data: json['data'] ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      synced: json['synced'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_name': tableName,
      'operation': operation,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'synced': synced,
    };
  }
}

// Hive Adapters - These need to be generated with build_runner
// For now, create stub adapters that will work temporarily
class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 0;

  @override
  Product read(BinaryReader reader) {
    // Simplified read - would be generated by build_runner
    return Product(id: '', sku: '');
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    // Simplified write - would be generated by build_runner
  }
}

class ClientAdapter extends TypeAdapter<Client> {
  @override
  final int typeId = 1;

  @override
  Client read(BinaryReader reader) {
    return Client(
        id: '',
        userId: '',
        company: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now());
  }

  @override
  void write(BinaryWriter writer, Client obj) {}
}

class QuoteAdapter extends TypeAdapter<Quote> {
  @override
  final int typeId = 2;

  @override
  Quote read(BinaryReader reader) {
    return Quote(
        id: '',
        userId: '',
        clientId: '',
        quoteNumber: '',
        subtotal: 0,
        taxRate: 0,
        taxAmount: 0,
        totalAmount: 0,
        items: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now());
  }

  @override
  void write(BinaryWriter writer, Quote obj) {}
}

class QuoteItemAdapter extends TypeAdapter<QuoteItem> {
  @override
  final int typeId = 3;

  @override
  QuoteItem read(BinaryReader reader) {
    return QuoteItem(
        id: '',
        quoteId: '',
        productId: '',
        quantity: 0,
        unitPrice: 0,
        totalPrice: 0);
  }

  @override
  void write(BinaryWriter writer, QuoteItem obj) {}
}

class CartItemAdapter extends TypeAdapter<CartItem> {
  @override
  final int typeId = 4;

  @override
  CartItem read(BinaryReader reader) {
    return CartItem(
        id: '',
        userId: '',
        productId: '',
        quantity: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now());
  }

  @override
  void write(BinaryWriter writer, CartItem obj) {}
}

class SyncQueueItemAdapter extends TypeAdapter<SyncQueueItem> {
  @override
  final int typeId = 5;

  @override
  SyncQueueItem read(BinaryReader reader) {
    return SyncQueueItem(
        id: '',
        tableName: '',
        operation: '',
        data: {},
        createdAt: DateTime.now());
  }

  @override
  void write(BinaryWriter writer, SyncQueueItem obj) {}
}
