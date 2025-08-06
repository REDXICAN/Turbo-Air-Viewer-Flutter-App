// lib/core/services/email_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class EmailService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static Future<void> sendQuoteEmail({
    required String quoteId,
    required String clientEmail,
    String? ccEmail,
    String? additionalMessage,
    bool attachPdf = false,
    bool attachExcel = false,
  }) async {
    try {
      // Get quote details with nested data
      final quoteDoc = await _firestore.collection('quotes').doc(quoteId).get();

      if (!quoteDoc.exists) {
        throw Exception('Quote not found');
      }

      final quoteData = quoteDoc.data()!;

      // Get client details
      final clientDoc = await _firestore
          .collection('clients')
          .doc(quoteData['client_id'])
          .get();

      if (!clientDoc.exists) {
        throw Exception('Client not found');
      }

      final clientData = clientDoc.data()!;

      // Get quote items with product details
      final itemsSnapshot = await _firestore
          .collection('quote_items')
          .where('quote_id', isEqualTo: quoteId)
          .get();

      final items = <Map<String, dynamic>>[];

      for (final itemDoc in itemsSnapshot.docs) {
        final itemData = itemDoc.data();

        // Get product details for each item
        final productDoc = await _firestore
            .collection('products')
            .doc(itemData['product_id'])
            .get();

        if (productDoc.exists) {
          final productData = productDoc.data()!;
          items.add({
            'sku': productData['sku'],
            'productType': productData['product_type'] ?? '',
            'quantity': itemData['quantity'],
            'unitPrice': itemData['unit_price'],
            'totalPrice': itemData['total_price'],
          });
        }
      }

      // Prepare email data
      final emailData = {
        'to': clientEmail,
        'cc': ccEmail,
        'subject': 'Quote #${quoteData['quote_number']} from Turbo Air',
        'quoteData': {
          'quoteNumber': quoteData['quote_number'],
          'clientName': clientData['company'],
          'items': items,
          'subtotal': quoteData['subtotal'],
          'taxRate': quoteData['tax_rate'],
          'taxAmount': quoteData['tax_amount'],
          'totalAmount': quoteData['total_amount'],
        },
        'additionalMessage': additionalMessage,
        'attachPdf': attachPdf,
        'attachExcel': attachExcel,
      };

      // Call Firebase Function to send email
      final HttpsCallable callable = _functions.httpsCallable('sendEmail');
      final response = await callable.call(emailData);

      // Check if response contains an error
      if (response.data != null && response.data['error'] != null) {
        throw Exception(response.data['error']);
      }

      // Update quote status to 'sent'
      await _firestore.collection('quotes').doc(quoteId).update({
        'status': 'sent',
        'sent_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to send email: $e');
    }
  }

  static Future<void> sendQuoteReminder({
    required String quoteId,
  }) async {
    try {
      // Get quote with client info
      final quoteDoc = await _firestore.collection('quotes').doc(quoteId).get();

      if (!quoteDoc.exists) {
        throw Exception('Quote not found');
      }

      final quoteData = quoteDoc.data()!;

      // Get client details
      final clientDoc = await _firestore
          .collection('clients')
          .doc(quoteData['client_id'])
          .get();

      if (!clientDoc.exists) {
        throw Exception('Client not found');
      }

      final clientData = clientDoc.data()!;

      if (clientData['contact_email'] == null) {
        throw Exception('Client email not found');
      }

      await sendQuoteEmail(
        quoteId: quoteId,
        clientEmail: clientData['contact_email'],
        additionalMessage:
            'This is a friendly reminder about your quote. Please let us know if you have any questions.',
      );
    } catch (e) {
      throw Exception('Failed to send reminder: $e');
    }
  }

  static Future<void> sendBulkEmails({
    required List<String> quoteIds,
    required String message,
    required BuildContext context,
  }) async {
    int successCount = 0;
    int failureCount = 0;

    for (final quoteId in quoteIds) {
      try {
        if (!context.mounted) return;
        await sendQuoteReminder(quoteId: quoteId);
        successCount++;
      } catch (e) {
        failureCount++;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sent: $successCount, Failed: $failureCount'),
          backgroundColor: failureCount > 0 ? Colors.orange : Colors.green,
        ),
      );
    }
  }

  // Alternative: Direct SendGrid integration (if not using Firebase Functions)
  static Future<void> sendQuoteEmailViaSendGrid({
    required String quoteId,
    required String clientEmail,
    String? ccEmail,
    String? additionalMessage,
    bool attachPdf = false,
    bool attachExcel = false,
  }) async {
    // Note: You'll need to add 'http' package to pubspec.yaml
    // and store SENDGRID_API_KEY securely (e.g., in Firebase Remote Config)

    // import 'package:http/http.dart' as http;

    // Example SendGrid implementation:
    /*
    final apiKey = 'YOUR_SENDGRID_API_KEY'; // Get from secure storage
    final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'personalizations': [
          {
            'to': [{'email': clientEmail}],
            'cc': ccEmail != null ? [{'email': ccEmail}] : null,
          }
        ],
        'from': {'email': 'turboairquotes@gmail.com', 'name': 'Turbo Air'},
        'subject': 'Your Quote from Turbo Air',
        'content': [
          {
            'type': 'text/html',
            'value': generateEmailHtml(quoteData),
          }
        ],
      }),
    );
    
    if (response.statusCode != 202) {
      throw Exception('Failed to send email: ${response.body}');
    }
    */
  }
}
