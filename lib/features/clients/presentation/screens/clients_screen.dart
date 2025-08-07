import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Clients provider
final clientsProvider = StreamProvider<List<Client>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);

  return firestoreService.getClients().map((clientsList) {
    return clientsList.map((json) => Client.fromJson(json)).toList();
  });
});

// Selected client provider
final selectedClientProvider = StateProvider<Client?>((ref) => null);

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  bool _showAddForm = false;
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _companyController.dispose();
    _contactNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);
    final selectedClient = ref.watch(selectedClientProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _showAddForm = !_showAddForm;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Selected client indicator
          if (selectedClient != null)
            Container(
              color: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selected: ${selectedClient.company}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(selectedClientProvider.notifier).state = null;
                    },
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

          // Add client form
          if (_showAddForm)
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.cardColor,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add New Client',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _companyController,
                      decoration: const InputDecoration(
                        labelText: 'Company Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter company name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contactNameController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveClient,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                            child: const Text('Save Client'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _showAddForm = false;
                                _clearForm();
                              });
                            },
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Clients list
          Expanded(
            child: clientsAsync.when(
              data: (clients) {
                if (clients.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: theme.iconTheme.color?.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No clients yet',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        const Text('Add a client to get started'),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showAddForm = true;
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Client'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    final isSelected = selectedClient?.id == client.id;

                    return Card(
                      elevation: isSelected ? 4 : 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isSelected
                          ? theme.primaryColor.withOpacity(0.1)
                          : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? theme.primaryColor
                              : theme.dividerColor,
                          child: Text(
                            client.company[0].toUpperCase(),
                            style: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          client.company,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (client.contactName != null)
                              Text('Contact: ${client.contactName}'),
                            if (client.contactEmail != null)
                              Text('Email: ${client.contactEmail}'),
                            if (client.phone != null)
                              Text('Phone: ${client.phone}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              const Icon(Icons.check_circle,
                                  color: Colors.green)
                            else
                              OutlinedButton(
                                onPressed: () {
                                  ref
                                      .read(selectedClientProvider.notifier)
                                      .state = client;
                                },
                                child: const Text('Select'),
                              ),
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete,
                                          size: 20, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editClient(client);
                                } else if (value == 'delete') {
                                  _deleteClient(client);
                                }
                              },
                            ),
                          ],
                        ),
                        isThreeLine: client.contactName != null,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading clients: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _companyController.clear();
    _contactNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = ref.read(authStateProvider).valueOrNull;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in first')),
        );
        return;
      }

      final firestoreService = ref.read(firestoreServiceProvider);

      await firestoreService.addClient({
        'company': _companyController.text,
        'contact_name': _contactNameController.text.isEmpty
            ? null
            : _contactNameController.text,
        'contact_email':
            _emailController.text.isEmpty ? null : _emailController.text,
        'contact_number':
            _phoneController.text.isEmpty ? null : _phoneController.text,
        'address':
            _addressController.text.isEmpty ? null : _addressController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Client "${_companyController.text}" added successfully'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _showAddForm = false;
          _clearForm();
        });

        ref.invalidate(clientsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding client: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editClient(Client client) {
    final theme = Theme.of(context);
    _companyController.text = client.company;
    _contactNameController.text = client.contactName ?? '';
    _emailController.text = client.contactEmail ?? '';
    _phoneController.text = client.phone ?? '';
    _addressController.text = client.address ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Client'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name *',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter company name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactNameController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearForm();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;

              try {
                final firestoreService = ref.read(firestoreServiceProvider);

                await firestoreService.updateClient(client.id, {
                  'company': _companyController.text,
                  'contact_name': _contactNameController.text.isEmpty
                      ? null
                      : _contactNameController.text,
                  'contact_email': _emailController.text.isEmpty
                      ? null
                      : _emailController.text,
                  'contact_number': _phoneController.text.isEmpty
                      ? null
                      : _phoneController.text,
                  'address': _addressController.text.isEmpty
                      ? null
                      : _addressController.text,
                });

                if (!context.mounted) return;

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Client updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                _clearForm();
                ref.invalidate(clientsProvider);
              } catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating client: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteClient(Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text('Are you sure you want to delete "${client.company}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final firestoreService = ref.read(firestoreServiceProvider);

                // Check if client has quotes
                final quotesCount = await firestoreService.getCount(
                  'quotes',
                  where: {'client_id': client.id},
                );

                if (quotesCount > 0) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Cannot delete client with existing quotes'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Delete client
                await firestoreService.deleteClient(client.id);

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Client "${client.company}" deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
                ref.invalidate(clientsProvider);

                // Clear selected client if it was deleted
                if (ref.read(selectedClientProvider)?.id == client.id) {
                  ref.read(selectedClientProvider.notifier).state = null;
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting client: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Client model
class Client {
  final String id;
  final String userId;
  final String company;
  final String? contactName;
  final String? contactEmail;
  final String? phone;
  final String? address;
  final DateTime createdAt;

  Client({
    required this.id,
    required this.userId,
    required this.company,
    this.contactName,
    this.contactEmail,
    this.phone,
    this.address,
    required this.createdAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    // Handle Firestore Timestamp
    DateTime createdAt;
    if (json['created_at'] is Timestamp) {
      createdAt = (json['created_at'] as Timestamp).toDate();
    } else if (json['created_at'] is String) {
      createdAt = DateTime.parse(json['created_at']);
    } else {
      createdAt = DateTime.now();
    }

    return Client(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      company: json['company'] ?? '',
      contactName: json['contact_name'],
      contactEmail: json['contact_email'],
      phone: json['contact_number'],
      address: json['address'],
      createdAt: createdAt,
    );
  }
}
