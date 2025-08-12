// lib/core/models/models.dart

// UserProfile Model
class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isAdmin;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
    this.isAdmin = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isAdmin': isAdmin,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      role: map['role'] ?? 'user',
      createdAt:
          DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.parse(map['lastLoginAt'])
          : null,
      isAdmin: map['isAdmin'] ?? false,
    );
  }
}

// Client Model
class Client {
  final String? id;
  final String company;
  final String contactName;
  final String name;
  final String email;
  final String phone;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Client({
    this.id,
    required this.company,
    required this.contactName,
    required this.name,
    required this.email,
    required this.phone,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company': company,
      'contactName': contactName,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      company: map['company'] ?? '',
      contactName: map['contactName'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'],
      city: map['city'],
      state: map['state'],
      zipCode: map['zipCode'],
      country: map['country'],
      notes: map['notes'],
      createdAt:
          DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
}

// Product Model
class Product {
  final String? id;
  final String model;
  final String displayName;
  final String name;
  final String description;
  final String category;
  final double price;
  final String? imageUrl;
  final int stock;
  final String? dimensions;
  final String? weight;
  final String? voltage;
  final String? amperage;
  final String? phase;
  final String? frequency;
  final String? plugType;
  final String? temperatureRange;
  final String? refrigerant;
  final String? compressor;
  final String? capacity;
  final int? doors;
  final int? shelves;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.model,
    required this.displayName,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    this.imageUrl,
    required this.stock,
    this.dimensions,
    this.weight,
    this.voltage,
    this.amperage,
    this.phase,
    this.frequency,
    this.plugType,
    this.temperatureRange,
    this.refrigerant,
    this.compressor,
    this.capacity,
    this.doors,
    this.shelves,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'model': model,
      'displayName': displayName,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'stock': stock,
      'dimensions': dimensions,
      'weight': weight,
      'voltage': voltage,
      'amperage': amperage,
      'phase': phase,
      'frequency': frequency,
      'plugType': plugType,
      'temperatureRange': temperatureRange,
      'refrigerant': refrigerant,
      'compressor': compressor,
      'capacity': capacity,
      'doors': doors,
      'shelves': shelves,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      model: map['model'] ?? '',
      displayName: map['displayName'] ?? map['name'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'],
      stock: map['stock'] ?? 0,
      dimensions: map['dimensions'],
      weight: map['weight'],
      voltage: map['voltage'],
      amperage: map['amperage'],
      phase: map['phase'],
      frequency: map['frequency'],
      plugType: map['plugType'],
      temperatureRange: map['temperatureRange'],
      refrigerant: map['refrigerant'],
      compressor: map['compressor'],
      capacity: map['capacity'],
      doors: map['doors'],
      shelves: map['shelves'],
      createdAt:
          DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
}

// Quote Model
class Quote {
  final String? id;
  final String clientId;
  final String? clientName;
  final Client? client;
  final List<QuoteItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final double totalAmount;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String createdBy;

  Quote({
    this.id,
    required this.clientId,
    this.clientName,
    this.client,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    double? totalAmount,
    required this.status,
    this.notes,
    required this.createdAt,
    this.expiresAt,
    required this.createdBy,
  }) : totalAmount = totalAmount ?? total;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'client': client?.toMap(),
      'items': items.map((x) => x.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'totalAmount': totalAmount,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'],
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'],
      client: map['client'] != null ? Client.fromMap(map['client']) : null,
      items: List<QuoteItem>.from(
        (map['items'] ?? []).map((x) => QuoteItem.fromMap(x)),
      ),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      tax: (map['tax'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? map['total'] ?? 0).toDouble(),
      status: map['status'] ?? 'draft',
      notes: map['notes'],
      createdAt:
          DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      expiresAt:
          map['expiresAt'] != null ? DateTime.parse(map['expiresAt']) : null,
      createdBy: map['createdBy'] ?? '',
    );
  }
}

// QuoteItem Model
class QuoteItem {
  final String productId;
  final String productName;
  final Product? product;
  final int quantity;
  final double unitPrice;
  final double total;
  final double totalPrice;
  final DateTime addedAt;

  QuoteItem({
    required this.productId,
    required this.productName,
    this.product,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    double? totalPrice,
    required this.addedAt,
  }) : totalPrice = totalPrice ?? total;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'product': product?.toMap(),
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
      'totalPrice': totalPrice,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory QuoteItem.fromMap(Map<String, dynamic> map) {
    return QuoteItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      product: map['product'] != null ? Product.fromMap(map['product']) : null,
      quantity: map['quantity'] ?? 1,
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] ?? map['total'] ?? 0).toDouble(),
      addedAt:
          DateTime.parse(map['addedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// CartItem Model
class CartItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double total;
  final DateTime addedAt;

  CartItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      addedAt:
          DateTime.parse(map['addedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
