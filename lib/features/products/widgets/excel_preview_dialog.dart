// lib/features/products/widgets/excel_preview_dialog.dart
import 'package:flutter/material.dart';

class ExcelPreviewDialog extends StatefulWidget {
  final Map<String, dynamic> previewData;
  final Function(List<Map<String, dynamic>>, bool) onConfirm;

  const ExcelPreviewDialog({
    super.key,
    required this.previewData,
    required this.onConfirm,
  });

  @override
  State<ExcelPreviewDialog> createState() => _ExcelPreviewDialogState();
}

class _ExcelPreviewDialogState extends State<ExcelPreviewDialog> {
  bool _clearExisting = false;
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  
  List<Map<String, dynamic>> get products => widget.previewData['products'] ?? [];
  List<String> get errors => widget.previewData['errors'] ?? [];
  
  int get totalPages => (products.length / _itemsPerPage).ceil();
  
  List<Map<String, dynamic>> get currentPageProducts {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, products.length);
    return products.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.preview, color: Colors.blue),
          const SizedBox(width: 8),
          Text('Preview Excel Import (${products.length} products)'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        products.length.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      Text('Total Products', style: theme.textTheme.bodySmall),
                    ],
                  ),
                  if (errors.isNotEmpty)
                    Column(
                      children: [
                        Text(
                          errors.length.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        Text('Warnings', style: theme.textTheme.bodySmall),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Clear existing checkbox
            CheckboxListTile(
              title: const Text('Clear existing products before import'),
              subtitle: const Text('Warning: This will remove all current products'),
              value: _clearExisting,
              onChanged: (value) {
                setState(() {
                  _clearExisting = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Divider(),
            
            // Products table
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Row')),
                      DataColumn(label: Text('SKU')),
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Description')),
                      DataColumn(label: Text('Price')),
                    ],
                    rows: currentPageProducts.map((product) {
                      return DataRow(
                        cells: [
                          DataCell(Text(product['row_number']?.toString() ?? '')),
                          DataCell(Text(product['sku'] ?? '')),
                          DataCell(Text(product['category'] ?? '')),
                          DataCell(
                            Tooltip(
                              message: product['description'] ?? '',
                              child: Text(
                                (product['description'] ?? '').length > 30
                                    ? '${(product['description'] ?? '').substring(0, 30)}...'
                                    : product['description'] ?? '',
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              product['price'] != null 
                                  ? '\$${product['price'].toStringAsFixed(2)}'
                                  : 'N/A',
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            
            // Pagination
            if (totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                  ),
                  Text('Page ${_currentPage + 1} of $totalPages'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < totalPages - 1
                        ? () => setState(() => _currentPage++)
                        : null,
                  ),
                ],
              ),
            
            // Errors section
            if (errors.isNotEmpty) ...[
              const Divider(),
              Text(
                'Warnings (${errors.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 60,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  itemCount: errors.length,
                  itemBuilder: (context, index) {
                    return Text(
                      errors[index],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.upload),
          label: Text(
            _clearExisting 
                ? 'Replace All Products (${products.length})' 
                : 'Import ${products.length} Products',
          ),
          onPressed: products.isNotEmpty
              ? () {
                  Navigator.of(context).pop();
                  widget.onConfirm(products, _clearExisting);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _clearExisting ? Colors.orange : theme.primaryColor,
          ),
        ),
      ],
    );
  }
}