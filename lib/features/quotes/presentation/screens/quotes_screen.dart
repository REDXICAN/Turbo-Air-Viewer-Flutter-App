import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// Quotes provider
final quotesProvider = FutureProvider<List<Quote>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final response = await supabase
      .from('quotes')
      .select(', clients(), quote_items(, products())')
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  return (response as List).map((json) => Quote.fromJson(json)).toList();
});

class QuotesScreen extends ConsumerStatefulWidget {
  const QuotesScreen({super.key});

  @override
  ConsumerState<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends ConsumerState<QuotesScreen> {
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final quotesAsync = ref.watch(quotesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Quotes'),
        backgroundColor: const Color(0xFF20429C),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search and filter bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search field
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search quotes...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Draft', 'draft'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Sent', 'sent'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Accepted', 'accepted'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Rejected', 'rejected'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quotes list
          Expanded(
            child: quotesAsync.when(
              data: (quotes) {
                // Filter quotes
                var filteredQuotes = quotes;

                if (_filterStatus != 'all') {
                  filteredQuotes =
                      quotes.where((q) => q.status == _filterStatus).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  filteredQuotes = filteredQuotes
                      .where((q) =>
                          q.quoteNumber
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()) ||
                          (q.client?.company ?? '')
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()))
                      .toList();
                }

                if (filteredQuotes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _filterStatus != 'all'
                              ? 'No quotes found'
                              : 'No quotes yet',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty || _filterStatus != 'all'
                              ? 'Try adjusting your filters'
                              : 'Create your first quote from the Cart',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredQuotes.length,
                  itemBuilder: (context, index) {
                    final quote = filteredQuotes[index];
                    return _buildQuoteCard(quote);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF20429C).withOpacity(0.2),
      checkmarkColor: const Color(0xFF20429C),
    );
  }

  Widget _buildQuoteCard(Quote quote) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final statusColor = _getStatusColor(quote.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showQuoteDetails(quote),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Quote number
                  Text(
                    '#${quote.quoteNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  // Status chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      quote.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Client info
              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    quote.client?.company ?? 'Unknown Client',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Date
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(quote.createdAt),
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Items count and total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${quote.items.length} items',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    '\$${quote.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF20429C),
                    ),
                  ),
                ],
              ),

              // Action buttons
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewQuote(quote),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _emailQuote(quote),
                      icon: const Icon(Icons.email, size: 16),
                      label: const Text('Email'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _exportQuote(quote),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Export'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showQuoteDetails(Quote quote) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quote #${quote.quoteNumber}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Quote details
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Client info
                  _buildDetailSection(
                    'Client Information',
                    [
                      _buildDetailRow(
                          'Company', quote.client?.company ?? 'N/A'),
                      if (quote.client?.contactName != null)
                        _buildDetailRow('Contact', quote.client!.contactName!),
                      if (quote.client?.contactEmail != null)
                        _buildDetailRow('Email', quote.client!.contactEmail!),
                      if (quote.client?.phone != null)
                        _buildDetailRow('Phone', quote.client!.phone!),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Items
                  _buildDetailSection(
                    'Items (${quote.items.length})',
                    quote.items
                        .map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product?.sku ?? 'Unknown',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          '${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '\$${item.totalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 16),

                  // Totals
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Subtotal',
                            '\$${quote.subtotal.toStringAsFixed(2)}'),
                        _buildDetailRow('Tax (${quote.taxRate}%)',
                            '\$${quote.taxAmount.toStringAsFixed(2)}'),
                        const Divider(),
                        _buildDetailRow(
                          'Total',
                          '\$${quote.totalAmount.toStringAsFixed(2)}',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  void _viewQuote(Quote quote) {
    _showQuoteDetails(quote);
  }

  void _emailQuote(Quote quote) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email functionality coming soon')),
    );
  }

  void _exportQuote(Quote quote) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF export coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export as Excel'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Excel export coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Quote models
class Quote {
  final String id;
  final String quoteNumber;
  final String status;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double totalAmount;
  final DateTime createdAt;
  final Client? client;
  final List<QuoteItem> items;

  Quote({
    required this.id,
    required this.quoteNumber,
    required this.status,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.totalAmount,
    required this.createdAt,
    this.client,
    required this.items,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'],
      quoteNumber: json['quote_number'],
      status: json['status'] ?? 'draft',
      subtotal: json['subtotal']?.toDouble() ?? 0,
      taxRate: json['tax_rate']?.toDouble() ?? 0,
      taxAmount: json['tax_amount']?.toDouble() ?? 0,
      totalAmount: json['total_amount']?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      client: json['clients'] != null ? Client.fromJson(json['clients']) : null,
      items: (json['quote_items'] as List?)
              ?.map((item) => QuoteItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class QuoteItem {
  final String id;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final Product? product;

  QuoteItem({
    required this.id,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.product,
  });

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      id: json['id'],
      quantity: json['quantity'],
      unitPrice: json['unit_price']?.toDouble() ?? 0,
      totalPrice: json['total_price']?.toDouble() ?? 0,
      product:
          json['products'] != null ? Product.fromJson(json['products']) : null,
    );
  }
}

class Client {
  final String id;
  final String company;
  final String? contactName;
  final String? contactEmail;
  final String? phone;

  Client({
    required this.id,
    required this.company,
    this.contactName,
    this.contactEmail,
    this.phone,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      company: json['company'],
      contactName: json['contact_name'],
      contactEmail: json['contact_email'],
      phone: json['contact_number'],
    );
  }
}

class Product {
  final String sku;

  Product({required this.sku});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(sku: json['sku']);
  }
}
