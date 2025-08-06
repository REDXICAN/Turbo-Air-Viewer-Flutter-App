// lib/core/services/email_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailService {
  static Future<void> sendQuoteEmail({
    required String quoteId,
    required String clientEmail,
    String? ccEmail,
    String? additionalMessage,
    bool attachPdf = false,
    bool attachExcel = false,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // Get quote details
      final quoteResponse = await supabase
          .from('quotes')
          .select('*, clients(*), quote_items(*, products(*))')
          .eq('id', quoteId)
          .single();

      // Prepare quote data for email
      final quoteData = {
        'quoteNumber': quoteResponse['quote_number'],
        'clientName': quoteResponse['clients']['company'],
        'items': (quoteResponse['quote_items'] as List)
            .map((item) => {
                  'sku': item['products']['sku'],
                  'productType': item['products']['product_type'] ?? '',
                  'quantity': item['quantity'],
                  'unitPrice': item['unit_price'],
                  'totalPrice': item['total_price'],
                })
            .toList(),
        'subtotal': quoteResponse['subtotal'],
        'taxRate': quoteResponse['tax_rate'],
        'taxAmount': quoteResponse['tax_amount'],
        'totalAmount': quoteResponse['total_amount'],
      };

      // Call Edge Function to send email
      final response = await supabase.functions.invoke(
        'send-email',
        body: {
          'to': clientEmail,
          'cc': ccEmail,
          'subject': 'Quote #${quoteResponse['quote_number']} from Turbo Air',
          'quoteData': quoteData,
          'additionalMessage': additionalMessage,
          'attachPdf': attachPdf,
          'attachExcel': attachExcel,
        },
      );

      // Check if response contains an error
      if (response.data == null || (response.data['error'] != null)) {
        throw Exception(response.data?['error'] ?? 'Failed to send email');
      }

      // Update quote status to 'sent'
      await supabase
          .from('quotes')
          .update({'status': 'sent'}).eq('id', quoteId);
    } catch (e) {
      throw Exception('Failed to send email: $e');
    }
  }

  static Future<void> sendQuoteReminder({
    required String quoteId,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // Get quote with client info
      final quoteResponse = await supabase
          .from('quotes')
          .select('*, clients(*)')
          .eq('id', quoteId)
          .single();

      if (quoteResponse['clients']['contact_email'] == null) {
        throw Exception('Client email not found');
      }

      await sendQuoteEmail(
        quoteId: quoteId,
        clientEmail: quoteResponse['clients']['contact_email'],
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
}
