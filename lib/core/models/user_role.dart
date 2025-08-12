// lib/core/models/user_role.dart

enum UserRole {
  admin('admin', 'Admin'),
  sales('sales', 'Sales'),
  distributor('distributor', 'Distributor');

  const UserRole(this.value, this.displayName);

  final String value;
  final String displayName;

  static UserRole fromString(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'sales':
        return UserRole.sales;
      case 'distributor':
        return UserRole.distributor;
      default:
        return UserRole.distributor; // Default role
    }
  }

  @override
  String toString() => value;

  // Permission helpers
  bool get canManageUsers => this == UserRole.admin;
  bool get canManageProducts => this == UserRole.admin;
  bool get canCreateQuotes => true; // All roles can create quotes
  bool get canViewAllQuotes => this == UserRole.admin;
  bool get canEditPricing => this == UserRole.admin || this == UserRole.sales;
  bool get canAccessAdmin => this == UserRole.admin;
}