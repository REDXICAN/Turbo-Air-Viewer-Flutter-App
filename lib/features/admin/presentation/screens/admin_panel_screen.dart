// lib/features/admin/presentation/screens/admin_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);

    return userProfileAsync.when(
      data: (userProfile) {
        // Check if user has admin access
        if (userProfile == null || !userProfile.isAdmin) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Access Denied'),
              backgroundColor: const Color(0xFF20429C),
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'You do not have permission to access this page',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        final isSuperAdmin = userProfile.role == 'superadmin';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Panel'),
            backgroundColor: const Color(0xFF20429C),
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              // Stats Cards
              Container(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final userCount = snapshot.data?.docs.length ?? 0;
                    final adminCount = snapshot.data?.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>?;
                          if (data == null) return false;
                          final role = data['role'] as String?;
                          return role == 'admin' || role == 'superadmin';
                        }).length ??
                        0;

                    return Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Icon(Icons.people,
                                      size: 32, color: Colors.blue),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$userCount',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text('Total Users'),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Icon(Icons.admin_panel_settings,
                                      size: 32, color: Colors.purple),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$adminCount',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text('Admins'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users by email or name...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Users List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    // Convert to UserProfile objects
                    final allUsers = docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      data['id'] = doc.id;
                      return UserProfile.fromJson(data);
                    }).toList();

                    // Filter users based on search
                    final filteredUsers = allUsers.where((user) {
                      if (_searchQuery.isEmpty) return true;
                      final email = user.email.toLowerCase();
                      final name = user.name.toLowerCase();
                      final company = (user.company ?? '').toLowerCase();
                      return email.contains(_searchQuery) ||
                          name.contains(_searchQuery) ||
                          company.contains(_searchQuery);
                    }).toList();

                    if (filteredUsers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No users found'
                                  : 'No users match your search',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final isCurrentUser = user.id == userProfile.id;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getRoleColor(user.role),
                              child: Text(
                                user.email[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              user.email,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Name: ${user.name}'),
                                if (user.company != null)
                                  Text('Company: ${user.company}'),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(user.role)
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getDisplayRole(user.role),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _getRoleColor(user.role),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Joined: ${_formatDate(user.createdAt)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: isCurrentUser
                                ? Chip(
                                    label: const Text('You'),
                                    backgroundColor:
                                        Colors.blue.withOpacity(0.2),
                                  )
                                : isSuperAdmin && user.role != 'superadmin'
                                    ? PopupMenuButton<String>(
                                        onSelected: (role) =>
                                            _updateUserRole(user.id, role),
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'admin',
                                            enabled: user.role != 'admin',
                                            child: const Row(
                                              children: [
                                                Icon(Icons.admin_panel_settings,
                                                    size: 16,
                                                    color: Colors.blue),
                                                SizedBox(width: 8),
                                                Text('Make Admin'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'sales',
                                            enabled: user.role != 'sales',
                                            child: const Row(
                                              children: [
                                                Icon(Icons.badge,
                                                    size: 16,
                                                    color: Colors.green),
                                                SizedBox(width: 8),
                                                Text('Make Sales'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'distributor',
                                            enabled: user.role != 'distributor',
                                            child: const Row(
                                              children: [
                                                Icon(Icons.person,
                                                    size: 16,
                                                    color: Colors.grey),
                                                SizedBox(width: 8),
                                                Text('Make Distributor'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuDivider(),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete,
                                                    size: 16,
                                                    color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Delete User',
                                                    style: TextStyle(
                                                        color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : null,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'superadmin':
        return Colors.purple;
      case 'admin':
        return Colors.blue;
      case 'sales':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getDisplayRole(String? role) {
    switch (role) {
      case 'superadmin':
        return 'SUPER ADMIN';
      case 'admin':
        return 'ADMIN';
      case 'sales':
        return 'SALES';
      case 'distributor':
        return 'DISTRIBUTOR';
      default:
        return 'USER';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    if (newRole == 'delete') {
      _confirmDelete(userId);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'role': newRole});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User role updated to ${_getDisplayRole(newRole)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete(String userId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text(
            'Are you sure you want to delete this user? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                // Delete user document from Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .delete();

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
