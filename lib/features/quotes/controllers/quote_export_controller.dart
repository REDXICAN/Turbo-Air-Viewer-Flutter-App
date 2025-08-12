// lib/features/quotes/controllers/quote_export_controller.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/email_service.dart';

class QuoteExportController {
  final EmailService _emailService = EmailService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Export quote as PDF with user information
  Future<List<int>> generateQuotePDF({
    required Map<String, dynamic> quoteData,
    required Map<String, dynamic> userInfo,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            _buildPDFHeader(),
            pw.SizedBox(height: 20),

            // Quote Information
            _buildQuoteInfo(quoteData),
            pw.SizedBox(height: 20),

            // Customer Information
            _buildCustomerInfo(quoteData['customer']),
            pw.SizedBox(height: 20),

            // Products Table
            _buildProductsTable(quoteData['items']),
            pw.SizedBox(height: 20),

            // Totals
            _buildTotals(quoteData),
            pw.SizedBox(height: 40),

            // Salesman/Distributor Information (Added to PDF)
            _buildSalesRepInfo(userInfo),
            pw.SizedBox(height: 20),

            // Terms and Conditions
            _buildTermsAndConditions(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Build PDF header
  pw.Widget _buildPDFHeader() {
    return pw.Container(
      padding: pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TURBOAIR',
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Professional Refrigeration Solutions',
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  /// Build sales representative information section
  pw.Widget _buildSalesRepInfo(Map<String, dynamic> userInfo) {
    return pw.Container(
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Your Sales Representative',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (userInfo['name'] != null)
                      _buildInfoRow('Name:', userInfo['name']),
                    if (userInfo['role'] != null)
                      _buildInfoRow('Role:', userInfo['role']),
                    if (userInfo['company'] != null)
                      _buildInfoRow('Company:', userInfo['company']),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (userInfo['email'] != null)
                      _buildInfoRow('Email:', userInfo['email']),
                    if (userInfo['phone'] != null)
                      _buildInfoRow('Phone:', userInfo['phone']),
                    if (userInfo['territory'] != null)
                      _buildInfoRow('Territory:', userInfo['territory']),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ... Other PDF building methods (buildQuoteInfo, buildCustomerInfo, etc.)

  /// Send quote via email with user information
  Future<bool> sendQuoteEmail({
    required String quoteId,
    required String customerEmail,
    required String customerName,
  }) async {
    try {
      // Get current user (salesman/distributor)
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Fetch user details from Firestore
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }

      final userData = userDoc.data() ?? {};

      // Prepare user information for email
      final userInfo = {
        'name': userData['displayName'] ??
            currentUser.displayName ??
            'TurboAir Sales Team',
        'email': userData['email'] ?? currentUser.email ?? '',
        'phone': userData['phone'] ?? '',
        'role':
            userData['role'] ?? userData['userType'] ?? 'Sales Representative',
        'company':
            userData['company'] ?? userData['distributorName'] ?? 'TurboAir',
        'territory': userData['territory'] ?? userData['region'] ?? '',
      };

      // Fetch quote data
      final quoteDoc = await _firestore.collection('quotes').doc(quoteId).get();

      if (!quoteDoc.exists) {
        throw Exception('Quote not found');
      }

      final quoteData = quoteDoc.data() ?? {};

      // Generate PDF with user info
      final pdfBytes = await generateQuotePDF(
        quoteData: quoteData,
        userInfo: userInfo,
      );

      // Prepare custom message based on user role
      String customMessage;
      if (userData['userType'] == 'distributor') {
        customMessage = '''
Thank you for your interest in TurboAir products. As your authorized distributor, 
we're committed to providing you with the best refrigeration solutions for your needs. 
Please review the attached quote and don't hesitate to contact us with any questions 
or to proceed with your order.
        ''';
      } else {
        customMessage = '''
Thank you for considering TurboAir for your refrigeration needs. I've prepared 
this quote specifically for your requirements. Please review the attached document 
and feel free to reach out if you need any modifications or have questions about 
the products or pricing.
        ''';
      }

      // Send email with all information
      final success = await _emailService.sendQuoteWithPDF(
        recipientEmail: customerEmail,
        recipientName: customerName,
        quoteNumber: quoteData['quoteNumber'] ?? quoteId,
        pdfBytes: pdfBytes,
        userInfo: userInfo,
        customMessage: customMessage,
      );

      if (success) {
        // Log email activity
        await _firestore.collection('email_logs').add({
          'quoteId': quoteId,
          'sentBy': currentUser.uid,
          'sentTo': customerEmail,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'sent',
          'userInfo': userInfo,
        });
      }

      return success;
    } catch (e) {
      // Error sending quote email

      // Log error
      await _firestore.collection('email_logs').add({
        'quoteId': quoteId,
        'sentBy': _auth.currentUser?.uid,
        'sentTo': customerEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'failed',
        'error': e.toString(),
      });

      return false;
    }
  }

  // Helper methods for building other PDF sections
  pw.Widget _buildQuoteInfo(Map<String, dynamic> quoteData) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Quote #${quoteData['quoteNumber'] ?? 'N/A'}',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text('Date: ${DateTime.now().toString().split(' ')[0]}'),
          pw.Text(
              'Valid Until: ${DateTime.now().add(Duration(days: 30)).toString().split(' ')[0]}'),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerInfo(Map<String, dynamic>? customer) {
    if (customer == null) return pw.Container();

    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Bill To:',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(customer['name'] ?? ''),
          pw.Text(customer['company'] ?? ''),
          pw.Text(customer['address'] ?? ''),
          pw.Text(
              '${customer['city'] ?? ''}, ${customer['state'] ?? ''} ${customer['zip'] ?? ''}'),
          pw.Text(customer['email'] ?? ''),
          pw.Text(customer['phone'] ?? ''),
        ],
      ),
    );
  }

  pw.Widget _buildProductsTable(List<dynamic>? items) {
    if (items == null || items.isEmpty) return pw.Container();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.all(5),
              child: pw.Text('Model',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(5),
              child: pw.Text('Description',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(5),
              child: pw.Text('Qty',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(5),
              child: pw.Text('Price',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(5),
              child: pw.Text('Total',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        // Data rows
        ...items.map((item) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: pw.EdgeInsets.all(5),
                  child: pw.Text(item['model'] ?? ''),
                ),
                pw.Padding(
                  padding: pw.EdgeInsets.all(5),
                  child: pw.Text(item['description'] ?? ''),
                ),
                pw.Padding(
                  padding: pw.EdgeInsets.all(5),
                  child: pw.Text('${item['quantity'] ?? 0}'),
                ),
                pw.Padding(
                  padding: pw.EdgeInsets.all(5),
                  child: pw.Text(
                      '\$${item['price']?.toStringAsFixed(2) ?? '0.00'}'),
                ),
                pw.Padding(
                  padding: pw.EdgeInsets.all(5),
                  child: pw.Text(
                      '\$${item['total']?.toStringAsFixed(2) ?? '0.00'}'),
                ),
              ],
            )),
      ],
    );
  }

  pw.Widget _buildTotals(Map<String, dynamic> quoteData) {
    final subtotal = quoteData['subtotal'] ?? 0.0;
    final tax = quoteData['tax'] ?? 0.0;
    final total = quoteData['total'] ?? 0.0;

    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        child: pw.Column(
          children: [
            _buildTotalRow('Subtotal:', '\$${subtotal.toStringAsFixed(2)}'),
            _buildTotalRow('Tax:', '\$${tax.toStringAsFixed(2)}'),
            pw.Divider(),
            _buildTotalRow(
              'Total:',
              '\$${total.toStringAsFixed(2)}',
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildTotalRow(String label, String value, {bool bold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTermsAndConditions() {
    return pw.Container(
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Terms and Conditions',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            '• Prices are valid for 30 days from quote date\n'
            '• Payment terms: Net 30 days\n'
            '• Shipping and handling charges may apply\n'
            '• All sales are subject to TurboAir standard terms and conditions',
            style: pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }
}
