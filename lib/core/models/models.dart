import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';

// User Model
class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? metadata;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.role = 'user',
    required this.createdAt,
    this.lastLoginAt,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      photoURL: json['photoURL'],
      role: json['role'] ?? 'user',
      createdAt: _parseDateTime(json['createdAt']),
      lastLoginAt: _parseDateTime(json['lastLoginAt']),
      metadata: json['metadata'],
    );
  }
}

// Product Model
class Product {
  final String id;
  final String sku;
  final String name;
  final String description;
  final String category;
  final String? subcategory;
  final String? productType;
  final double price;
  final double? discountPrice;
  final String? imageUrl;
  final List<String>? screenshots;
  final bool isActive;
  final int? stockQuantity;
  final String? brand;
  final Map<String, dynamic>? specifications;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.description,
    required this.category,
    this.subcategory,
    this.productType,
    required this.price,
    this.discountPrice,
    this.imageUrl,
    this.screenshots,
    this.isActive = true,
    this.stockQuantity,
    this.brand,
    this.specifications,
    required this.createdAt,
    this.updatedAt,
  });

  double get finalPrice => discountPrice ?? price;
  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  double get discountPercentage =>
      hasDiscount ? ((price - discountPrice!) / price * 100) : 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'description': description,
      'category': category,
      'subcategory': subcategory,
      'productType': productType,
      'price': price,
      'discountPrice': discountPrice,
      'imageUrl': imageUrl,
      'screenshots': screenshots,
      'isActive': isActive,
      'stockQuantity': stockQuantity,
      'brand': brand,
      'specifications': specifications,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      sku: json['sku'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      subcategory: json['subcategory'],
      productType: json['productType'],
      price: (json['price'] ?? 0).toDouble(),
      discountPrice: json['discountPrice']?.toDouble(),
      imageUrl: json['imageUrl'],
      screenshots: json['screenshots'] != null
          ? List<String>.from(json['screenshots'])
          : null,
      isActive: json['isActive'] ?? true,
      stockQuantity: json['stockQuantity'],
      brand: json['brand'],
      specifications: json['specifications'],
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Product copyWith({
    String? id,
    String? sku,
    String? name,
    String? description,
    String? category,
    String? subcategory,
    String? productType,
    double? price,
    double? discountPrice,
    String? imageUrl,
    List<String>? screenshots,
    bool? isActive,
    int? stockQuantity,
    String? brand,
    Map<String, dynamic>? specifications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      productType: productType ?? this.productType,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      screenshots: screenshots ?? this.screenshots,
      isActive: isActive ?? this.isActive,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      brand: brand ?? this.brand,
      specifications: specifications ?? this.specifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Client Model
class Client {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final String? taxId;
  final String? companyName;
  final String? contactPerson;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Client({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.taxId,
    this.companyName,
    this.contactPerson,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'taxId': taxId,
      'companyName': companyName,
      'contactPerson': contactPerson,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zipCode'],
      country: json['country'],
      taxId: json['taxId'],
      companyName: json['companyName'],
      contactPerson: json['contactPerson'],
      notes: json['notes'],
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Client copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    String? taxId,
    String? companyName,
    String? contactPerson,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      taxId: taxId ?? this.taxId,
      companyName: companyName ?? this.companyName,
      contactPerson: contactPerson ?? this.contactPerson,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toRealtimeDb() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'taxId': taxId,
      'companyName': companyName,
      'contactPerson': contactPerson,
      'notes': notes,
      'createdAt': ServerValue.timestamp,
      'updatedAt': ServerValue.timestamp,
    };
  }
}

// Quote Model
class Quote {
  final String id;
  final String clientId;
  final String? clientName;
  final String? clientEmail;
  final List<QuoteItem> items;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double total;
  final String status; // draft, sent, accepted, rejected, expired
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
  final DateTime? sentAt;
  final String? notes;
  final String? terms;
  final String createdBy;
  final int? quoteNumber;

  Quote({
    required this.id,
    required this.clientId,
    this.clientName,
    this.clientEmail,
    required this.items,
    required this.subtotal,
    this.taxRate = 0.0,
    required this.taxAmount,
    required this.total,
    this.status = 'draft',
    required this.createdAt,
    this.updatedAt,
    this.expiresAt,
    this.sentAt,
    this.notes,
    this.terms,
    required this.createdBy,
    this.quoteNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'total': total,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'notes': notes,
      'terms': terms,
      'createdBy': createdBy,
      'quoteNumber': quoteNumber,
    };
  }

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] ?? '',
      clientId: json['clientId'] ?? '',
      clientName: json['clientName'],
      clientEmail: json['clientEmail'],
      items: (json['items'] as List?)
              ?.map((e) => QuoteItem.fromJson(e))
              .toList() ??
          [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      taxRate: (json['taxRate'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      status: json['status'] ?? 'draft',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      expiresAt: _parseDateTime(json['expiresAt']),
      sentAt: _parseDateTime(json['sentAt']),
      notes: json['notes'],
      terms: json['terms'],
      createdBy: json['createdBy'] ?? '',
      quoteNumber: json['quoteNumber'],
    );
  }

  Quote copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientEmail,
    List<QuoteItem>? items,
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? total,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    DateTime? sentAt,
    String? notes,
    String? terms,
    String? createdBy,
    int? quoteNumber,
  }) {
    return Quote(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      sentAt: sentAt ?? this.sentAt,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      createdBy: createdBy ?? this.createdBy,
      quoteNumber: quoteNumber ?? this.quoteNumber,
    );
  }

  Map<String, dynamic> toRealtimeDb() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'total': total,
      'status': status,
      'createdAt': ServerValue.timestamp,
      'updatedAt': ServerValue.timestamp,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
      'sentAt': sentAt?.millisecondsSinceEpoch,
      'notes': notes,
      'terms': terms,
      'createdBy': createdBy,
      'quoteNumber': quoteNumber,
    };
  }
}

// Quote Item Model
class QuoteItem {
  final String productId;
  final String productName;
  final String? productSku;
  final String? description;
  final int quantity;
  final double unitPrice;
  final double? discount;
  final double total;

  QuoteItem({
    required this.productId,
    required this.productName,
    this.productSku,
    this.description,
    required this.quantity,
    required this.unitPrice,
    this.discount,
    required this.total,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'productSku': productSku,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discount': discount,
      'total': total,
    };
  }

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productSku: json['productSku'],
      description: json['description'],
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      discount: json['discount']?.toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }
}

// Cart Model
class Cart {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double subtotal;
  final double total;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Cart({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.total,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'total': total,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      items:
          (json['items'] as List?)?.map((e) => CartItem.fromJson(e)).toList() ??
              [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toRealtimeDb() {
    return {
      'userId': userId,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'total': total,
      'createdAt': ServerValue.timestamp,
      'updatedAt': ServerValue.timestamp,
    };
  }
}

// Cart Item Model
class CartItem {
  final String id;
  final String productId;
  final Product? product;
  final String productName;
  final String? productSku;
  final String? imageUrl;
  final int quantity;
  final double unitPrice;
  final double total;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.productId,
    this.product,
    required this.productName,
    this.productSku,
    this.imageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'productSku': productSku,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productSku: json['productSku'],
      imageUrl: json['imageUrl'],
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      addedAt: _parseDateTime(json['addedAt']),
    );
  }

  CartItem copyWith({
    String? id,
    String? productId,
    Product? product,
    String? productName,
    String? productSku,
    String? imageUrl,
    int? quantity,
    double? unitPrice,
    double? total,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      product: product ?? this.product,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

// Helper function to parse DateTime
DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is Map && value['_seconds'] != null) {
    return DateTime.fromMillisecondsSinceEpoch(value['_seconds'] * 1000);
  }
  return DateTime.now();
}
