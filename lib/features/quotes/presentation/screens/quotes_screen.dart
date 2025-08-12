// lib/features/quotes/presentation/screens/quotes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/models/models.dart';

// Quotes provider using Realtime Database
final quotesProvider = StreamProvider<List<Quote>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);

  return dbService.getQuotes().asyncMap((quotesList) async {
    // Fetch additional data for each quote
    final List<Quote> quotes = [];

    for (final quoteData in quotesList) {
      // Fetch client data
      Map<String, dynamic>? clientData;
      if (quoteData['client_id'] != null) {
        clientData = await dbService.getClient(quoteData['client_id']);
      }

      // Fetch quote items
      final List<QuoteItem> items = [];
      if (quoteData['quote_items'] != null) {
        for (final itemData in quoteData['quote_items']) {
          // Fetch product data for each item
          final productData =
              await dbService.getProduct(itemData['product_id']);
          items.add(QuoteItem(
            productId: itemData['product_id'] ?? '',
            productName: productData?['name'] ?? 'Unknown Product',
            quantity: itemData['quantity'] ?? 1,
            unitPrice: (itemData['unit_price'] ?? 0).toDouble(),
            total: (itemData['total_price'] ?? 0).toDouble(),
            product: productData != null ? Product.fromMap(productData) : null,
            addedAt: DateTime.now(),
          ));
        }
      }

      quotes.add(Quote(
        id: quoteData['id'],
        clientId: quoteData['client_id'],
        quoteNumber: quoteData['quote_number'],
        subtotal: (quoteData['subtotal'] ?? 0).toDouble(),
        tax: (quoteData['tax_amount'] ?? 0).toDouble(),
        total: (quoteData['total_amount'] ?? 0).toDouble(),
        status: quoteData['status'] ?? 'draft',
        items: items,
        client: clientData != null ? Client.fromMap(clientData) : null,
        createdBy: quoteData['user_id'] ?? '',
        createdAt: quoteData['created_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(quoteData['created_at'])
            : DateTime.now(),
      ));
    }

    return quotes;
  });
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotes'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: Column(
        children: [
          // Search and filter bar
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.cardColor,
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
                    fillColor: theme.inputDecorationTheme.fillColor,
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
                          (q.quoteNumber
                              ?.toLowerCase()
                              .contains(_searchQuery.toLowerCase()) ?? false) ||
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
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: theme.iconTheme.color?.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No quotes found',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty || _filterStatus != 'all'
                              ? 'Try adjusting your filters'
                              : 'Create your first quote from the Cart',
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
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading quotes: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(quotesProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      backgroundColor: theme.chipTheme.backgroundColor,
      selectedColor: theme.primaryColor.withOpacity(0.2),
      checkmarkColor: theme.primaryColor,
    );
  }

  Widget _buildQuoteCard(Quote quote) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final statusColor = _getStatusColor(quote.status);
    final theme = Theme.of(context);

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
                  Icon(Icons.business, size: 16, color: theme.iconTheme.color),
                  const SizedBox(width: 4),
                  Text(quote.client?.company ?? 'Unknown Client'),
                ],
              ),
              const SizedBox(height: 4),

              // Date
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: theme.iconTheme.color),
                  const SizedBox(width: 4),
                  Text(dateFormat.format(quote.createdAt)),
                ],
              ),
              const SizedBox(height: 12),

              // Items count and total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${quote.items.length} items'),
                  Text(
                    '\$${quote.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
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
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'export_pdf',
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Export PDF'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'export_excel',
                        child: Row(
                          children: [
                            Icon(Icons.table_chart, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Export Excel'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'export_pdf':
                          _exportQuote(quote, 'pdf');
                          break;
                        case 'export_excel':
                          _exportQuote(quote, 'excel');
                          break;
                        case 'delete':
                          _deleteQuote(quote);
                          break;
                      }
                    },
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
    context.push('/quotes/${quote.id}');
  }

  void _viewQuote(Quote quote) {
    _showQuoteDetails(quote);
  }

  void _emailQuote(Quote quote) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email functionality coming soon')),
    );
  }

  void _exportQuote(Quote quote, String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${format.toUpperCase()} export coming soon')),
    );
  }

  void _deleteQuote(Quote quote) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Quote'),
        content: Text(
            'Are you sure you want to delete quote #${quote.quoteNumber}?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // TODO: Implement delete functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Quote deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
