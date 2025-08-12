// lib/core/services/export_service.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';

class ExportService {
  static final _database = FirebaseDatabase.instance;
  static final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final _dateFormat = DateFormat('MMMM dd, yyyy');

  // Generate PDF for a quote
  static Future<Uint8List> generateQuotePDF(String quoteId) async {
    final pdf = pw.Document();
    
    // Fetch quote data
    final quoteSnapshot = await _database.ref('quotes/$quoteId').get();
    if (!quoteSnapshot.exists) {
      throw Exception('Quote not found');
    }
    
    final quoteData = Map<String, dynamic>.from(quoteSnapshot.value as Map);
    
    // Fetch client data
    Map<String, dynamic>? clientData;
    if (quoteData['client_id'] != null) {
      final clientSnapshot = await _database.ref('clients/${quoteData['client_id']}').get();
      if (clientSnapshot.exists) {
        clientData = Map<String, dynamic>.from(clientSnapshot.value as Map);
      }
    }
    
    // Fetch quote items
    final itemsSnapshot = await _database
        .ref('quote_items')
        .orderByChild('quote_id')
        .equalTo(quoteId)
        .get();
    
    List<Map<String, dynamic>> items = [];
    if (itemsSnapshot.exists) {
      final itemsData = Map<String, dynamic>.from(itemsSnapshot.value as Map);
      for (var entry in itemsData.entries) {
        final item = Map<String, dynamic>.from(entry.value);
        
        // Fetch product details
        if (item['product_id'] != null) {
          final productSnapshot = await _database.ref('products/${item['product_id']}').get();
          if (productSnapshot.exists) {
            item['product'] = Map<String, dynamic>.from(productSnapshot.value as Map);
          }
        }
        
        items.add(item);
      }
    }
    
    // Build PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'TURBO AIR',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Equipment Quote',
                      style: const pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Quote #${quoteData['quote_number']}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _dateFormat.format(
                        DateTime.fromMillisecondsSinceEpoch(quoteData['created_at'] ?? 0),
                      ),
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            
            // Client Information
            if (clientData != null) ...[
              pw.Text(
                'Bill To:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      clientData['company'] ?? '',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    if (clientData['contact_name'] != null)
                      pw.Text(clientData['contact_name']),
                    if (clientData['address'] != null)
                      pw.Text(clientData['address']),
                    if (clientData['city'] != null || clientData['state'] != null)
                      pw.Text(
                        '${clientData['city'] ?? ''}, ${clientData['state'] ?? ''} ${clientData['zip_code'] ?? ''}',
                      ),
                    if (clientData['phone'] != null)
                      pw.Text('Phone: ${clientData['phone']}'),
                    if (clientData['email'] != null)
                      pw.Text('Email: ${clientData['email']}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
            ],
            
            // Items Table
            pw.Text(
              'Quote Items',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  children: [
                    _buildTableCell('SKU', isHeader: true),
                    _buildTableCell('Description', isHeader: true),
                    _buildTableCell('Qty', isHeader: true, align: pw.TextAlign.center),
                    _buildTableCell('Unit Price', isHeader: true, align: pw.TextAlign.right),
                    _buildTableCell('Total', isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                // Item rows
                ...items.map((item) {
                  final product = item['product'] ?? {};
                  return pw.TableRow(
                    children: [
                      _buildTableCell(product['sku'] ?? ''),
                      _buildTableCell(product['product_type'] ?? ''),
                      _buildTableCell(
                        item['quantity'].toString(),
                        align: pw.TextAlign.center,
                      ),
                      _buildTableCell(
                        _currencyFormat.format(item['unit_price'] ?? 0),
                        align: pw.TextAlign.right,
                      ),
                      _buildTableCell(
                        _currencyFormat.format(item['total_price'] ?? 0),
                        align: pw.TextAlign.right,
                      ),
                    ],
                  );
                }),
              ],
            ),
            
            // Summary section
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Subtotal: ${_currencyFormat.format(quoteData['subtotal'] ?? 0)}'),
                    pw.Text('Tax: ${_currencyFormat.format(quoteData['tax'] ?? 0)}'),
                    pw.Text(
                      'Total: ${_currencyFormat.format(quoteData['total'] ?? 0)}',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );
    
    return await pdf.save();
  }
  
  // Helper method to build table cells
  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
  
  // Placeholder methods for missing functionality
  static Future<Uint8List> exportProducts(List products) async {
    throw UnimplementedError('Product export not implemented');
  }
  
  static Future<Uint8List> exportClients(List clients) async {
    throw UnimplementedError('Client export not implemented');  
  }
  
  static Future<Uint8List> exportQuotes(List quotes) async {
    throw UnimplementedError('Quote export not implemented');
  }
}