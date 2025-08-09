// lib/features/profile/presentation/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../admin/presentation/screens/admin_panel_screen.dart';

// Theme mode provider
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  void toggleDarkMode(bool isDark) {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String currency = 'USD (\$)';
  int itemsPerPage = 20;
  bool autoSaveCart = true;

  @override
  Widget build(BuildContext context) {
    // Get Firebase user for auth info
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.valueOrNull;

    // Get UserProfile for additional user data
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final userProfile = userProfileAsync.valueOrNull;

    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final theme = Theme.of(context);

    // Admin checks using UserProfile
    final isAdmin = userProfile?.isAdmin ?? false;
    final isSuperAdmin = userProfile?.role == 'superadmin';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        actions: [
          // Add admin panel quick access
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                setState(() {
                  // Navigate to admin panel
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminPanelScreen(),
                    ),
                  );
                });
              },
              tooltip: 'Admin Panel',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Information Card - Enhanced with badges
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'User Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // Add role badge
                          if (isSuperAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'SUPER ADMIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else if (isAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Email', user?.email ?? 'N/A'),
                      _buildInfoRow('Name',
                          userProfile?.name ?? user?.displayName ?? 'N/A'),
                      _buildInfoRow('Company', userProfile?.company ?? 'N/A'),
                      _buildInfoRow(
                          'User ID', user?.uid.substring(0, 8) ?? 'N/A'),
                      _buildInfoRow('Role', _formatRole(userProfile?.role)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle,
                                    size: 8, color: Colors.green),
                                SizedBox(width: 6),
                                Text(
                                  'Connected to Firebase',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Admin Panel Card - Only for admins
              if (isAdmin) ...[
                Card(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AdminPanelScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.purple,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Admin Panel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  isSuperAdmin
                                      ? 'Manage users and assign roles'
                                      : 'View system users',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: theme.iconTheme.color,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // App Settings Card - PRESERVED AS IS
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.settings, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'App Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Dark Mode Toggle
                      SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle: Text(themeMode == ThemeMode.system
                            ? 'Following system'
                            : isDarkMode
                                ? 'Enabled'
                                : 'Disabled'),
                        secondary: Icon(
                          isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        ),
                        value: isDarkMode,
                        onChanged: (value) {
                          ref
                              .read(themeModeProvider.notifier)
                              .toggleDarkMode(value);
                        },
                      ),
                      const Divider(),

                      // Currency Selection
                      ListTile(
                        leading: const Icon(Icons.attach_money),
                        title: const Text('Currency Display'),
                        subtitle: Text(currency),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showCurrencyDialog(),
                      ),
                      const Divider(),

                      // Items per page
                      ListTile(
                        leading: const Icon(Icons.format_list_numbered),
                        title: const Text('Products per page'),
                        subtitle: Text('$itemsPerPage items'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showItemsPerPageDialog(),
                      ),
                      const Divider(),

                      // Auto-save cart
                      SwitchListTile(
                        title: const Text('Auto-save cart'),
                        subtitle: const Text('Automatically save cart items'),
                        secondary: const Icon(Icons.save_alt),
                        value: autoSaveCart,
                        onChanged: (value) {
                          setState(() {
                            autoSaveCart = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Data Management Card - PRESERVED AS IS
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.storage, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Data Management',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Export feature coming soon'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.download),
                              label: const Text('Export Data'),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Backup created successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.backup),
                              label: const Text('Backup'),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Account Actions Card - PRESERVED AS IS
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.account_circle, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.lock),
                        title: const Text('Change Password'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password change coming soon'),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () => _showSignOutDialog(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // About Section - PRESERVED AS IS
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'About',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('App Name', 'Turbo Air Equipment'),
                      _buildInfoRow('Version', '1.0.0'),
                      _buildInfoRow('Built with', 'Flutter & Firebase'),
                      const SizedBox(height: 8),
                      Text(
                        '© 2024 Turbo Air',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRole(String? role) {
    if (role == null) return 'USER';
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
        return role.toUpperCase();
    }
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: const Text('USD (\$)'),
              value: 'USD (\$)',
              groupValue: currency,
              onChanged: (value) {
                setState(() {
                  currency = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('CAD (\$)'),
              value: 'CAD (\$)',
              groupValue: currency,
              onChanged: (value) {
                setState(() {
                  currency = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('EUR (€)'),
              value: 'EUR (€)',
              groupValue: currency,
              onChanged: (value) {
                setState(() {
                  currency = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showItemsPerPageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Products per page'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [10, 20, 30, 50].map((value) {
            return RadioListTile(
              title: Text('$value items'),
              value: value,
              groupValue: itemsPerPage,
              onChanged: (value) {
                setState(() {
                  itemsPerPage = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error signing out: $e')),
                  );
                }
              }
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
