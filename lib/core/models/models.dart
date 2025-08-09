// lib/core/models/models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Product Model
class Product {
  final String id;
  final String sku;
  final String? category;
  final String? subcategory;
  final String? productType;
  final String? description;
  final String? voltage;
  final String? amperage;
  final String? phase;
  final String? frequency;
  final String? plugType;
  final String? dimensions;
  final String? dimensionsMetric;
  final String? weight;
  final String? weightMetric;
  final String? temperatureRange;
  final String? temperatureRangeMetric;
  final String? refrigerant;
  final String? compressor;
  final String? capacity;
  final String? doors;
  final String? shelves;
  final String? features;
  final String? certifications;
  final double? price;
  final DateTime? createdAt;
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
      productType: json['product_type'] ?? json['productType'],
      description: json['description'],
      voltage: json['voltage'],
      amperage: json['amperage'],
      phase: json['phase'],
      frequency: json['frequency'],
      plugType: json['plug_type'] ?? json['plugType'],
      dimensions: json['dimensions'],
      dimensionsMetric: json['dimensions_metric'] ?? json['dimensionsMetric'],
      weight: json['weight'],
      weightMetric: json['weight_metric'] ?? json['weightMetric'],
      temperatureRange: json['temperature_range'] ?? json['temperatureRange'],
      temperatureRangeMetric:
          json['temperature_range_metric'] ?? json['temperatureRangeMetric'],
      refrigerant: json['refrigerant'],
      compressor: json['compressor'],
      capacity: json['capacity'],
      doors: json['doors'],
      shelves: json['shelves'],
      features: json['features'],
      certifications: json['certifications'],
      price: json['price']?.toDouble(),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
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
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get displayName => productType ?? sku;
  String get imageUrl => 'assets/screenshots/$sku/$sku P.1.png';
}

/// Client Model
class Client {
  final String id;
  final String userId;
  final String company;
  final String? contactName;
  final String? contactEmail;
  final String? contactNumber;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Client({
    required this.id,
    required this.userId,
    required this.company,
    this.contactName,
    this.contactEmail,
    this.contactNumber,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      company: json['company'] ?? '',
      contactName: json['contact_name'],
      contactEmail: json['contact_email'],
      contactNumber: json['contact_number'],
      email: json['email'] ?? json['contact_email'],
      phone: json['phone'] ?? json['contact_number'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zip_code'] ?? json['zipCode'],
      notes: json['notes'],
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'company': company,
      'contact_name': contactName,
      'contact_email': contactEmail ?? email,
      'contact_number': contactNumber ?? phone,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'notes': notes,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

/// Quote Model
class Quote {
  final String id;
  final String userId;
  final String clientId;
  final String quoteNumber;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double totalAmount;
  final String status;
  final List<QuoteItem> items;
  final Map<String, dynamic>? client;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.items = const [],
    this.client,
    this.createdAt,
    this.updatedAt,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      clientId: json['client_id'] ?? '',
      quoteNumber: json['quote_number'] ?? '',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      taxRate: (json['tax_rate'] ?? 0).toDouble(),
      taxAmount: (json['tax_amount'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'draft',
      items: (json['quote_items'] as List?)
              ?.map((e) => QuoteItem.fromJson(e))
              .toList() ??
          [],
      client: json['client'],
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
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
      'client': client,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

/// Quote Item Model
class QuoteItem {
  final String id;
  final String quoteId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final Map<String, dynamic>? product;

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
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      product: json['product'],
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
      'product': product,
    };
  }
}

/// Cart Item Model
class CartItem {
  final String id;
  final String userId;
  final String? clientId;
  final String productId;
  int quantity;
  final Map<String, dynamic>? product;
  final DateTime? createdAt;
  DateTime? updatedAt;

  CartItem({
    required this.id,
    required this.userId,
    this.clientId,
    required this.productId,
    required this.quantity,
    this.product,
    this.createdAt,
    this.updatedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      clientId: json['client_id'],
      productId: json['product_id'] ?? '',
      quantity: json['quantity'] ?? 1,
      product: json['product'] ?? json['products'],
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'client_id': clientId,
      'product_id': productId,
      'quantity': quantity,
      'product': product,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  void updateQuantity(int newQuantity) {
    quantity = newQuantity;
    updatedAt = DateTime.now();
  }
}

/// User Profile Model
class UserProfile {
  final String id;
  final String email;
  final String name;
  final String? role;
  final String? company;
  final String? phone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'distributor',
    this.company,
    this.phone,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'distributor',
      company: json['company'],
      phone: json['phone'],
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'company': company,
      'phone': phone,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isSales => role == 'sales';
  bool get isDistributor => role == 'distributor';
}

// Helper function to parse DateTime from various formats
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;

  if (value is Timestamp) {
    return value.toDate();
  } else if (value is DateTime) {
    return value;
  } else if (value is String) {
    return DateTime.tryParse(value);
  } else if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  return null;
}
