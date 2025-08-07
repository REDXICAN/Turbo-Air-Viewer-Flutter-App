// Add this to lib/core/models/models.dart or create lib/core/models/user_profile.dart

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
    required this.role,
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
          ? (json['created_at'] is DateTime
              ? json['created_at']
              : (json['created_at'].toDate()))
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (json['updated_at'] is DateTime
              ? json['updated_at']
              : (json['updated_at'].toDate()))
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

  bool get isSuperAdmin => role == 'superadmin';
  bool get isAdmin => role == 'admin' || role == 'superadmin';
  bool get isSales => role == 'sales';
  bool get isDistributor => role == 'distributor';

  String get displayRole {
    switch (role) {
      case 'superadmin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'sales':
        return 'Sales';
      case 'distributor':
        return 'Distributor';
      default:
        return role.toUpperCase();
    }
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? role,
    String? company,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
