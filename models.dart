import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

/// Product Model
@JsonSerializable()
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
  
  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
  
  String get displayName => productType ?? sku;
  String get imageUrl => 'assets/screenshots/${sku}/${sku} P.1.png';
}

/// Client Model
@JsonSerializable()
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
  
  factory Client.fromJson(Map<String, dynamic> json) => _$ClientFromJson(json);
  Map<String, dynamic> toJson() => _$ClientToJson(this);
}

/// Quote Model
@JsonSerializable()
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
  
  factory Quote.fromJson(Map<String, dynamic> json) => _$QuoteFromJson(json);
  Map<String, dynamic> toJson() => _$QuoteToJson(this);
}

/// Quote Item Model
@JsonSerializable()
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
  
  factory QuoteItem.fromJson(Map<String, dynamic> json) => _$QuoteItemFromJson(json);
  Map<String, dynamic> toJson() => _$QuoteItemToJson(this);
}

/// Cart Item Model
@JsonSerializable()
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
  
  factory CartItem.fromJson(Map<String, dynamic> json) => _$CartItemFromJson(json);
  Map<String, dynamic> toJson() => _$CartItemToJson(this);
  
  void updateQuantity(int newQuantity) {
    quantity = newQuantity;
    updatedAt = DateTime.now();
    isSynced = false;
    save();
  }
}

/// User Profile Model
@JsonSerializable()
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
  
  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
  
  bool get isAdmin => role == 'admin';
  bool get isSales => role == 'sales';
  bool get isDistributor => role == 'distributor';
}

/// Sync Queue Model for offline changes
@JsonSerializable()
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
  
  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => _$SyncQueueItemFromJson(json);
  Map<String, dynamic> toJson() => _$SyncQueueItemToJson(this);
}