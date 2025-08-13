// lib/core/services/email_service.dart

import 'dart:typed_data';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../config/secure_email_config.dart';
import 'export_service.dart';

class EmailService {
  late SmtpServer _smtpServer;

  EmailService() {
    _smtpServer = gmail(SecureEmailConfig.gmailAddress, SecureEmailConfig.gmailAppPassword);
  }

  /// Send quote email with user information
  Future<bool> sendQuoteEmail({
    required String recipientEmail,
    required String recipientName,
    required String quoteNumber,
    required String htmlContent,
    required Map<String, dynamic> userInfo, // User/salesman info
    List<Attachment>? attachments,
  }) async {
    try {
      // Build user signature block
      final userSignature = _buildUserSignature(userInfo);

      // Prepare email body with user info
      final enhancedHtmlContent = '''
$htmlContent

<br><br>
<hr style="border: 1px solid #e0e0e0; margin: 20px 0;">
$userSignature

<p style="color: #666; font-size: 12px; margin-top: 20px;">
  ${SecureEmailConfig.noReplyNote}<br>
  For inquiries, please contact your sales representative directly using the information above.
</p>
      ''';

      final message = Message()
        ..from = Address(SecureEmailConfig.gmailAddress, SecureEmailConfig.senderName)
        ..recipients.add(recipientEmail)
        ..subject = '${SecureEmailConfig.quoteEmailSubject}$quoteNumber'
        ..html = enhancedHtmlContent;

      // Set reply-to as the user's email if available
      if (userInfo['email'] != null && userInfo['email'].isNotEmpty) {
        // message.replyTo.add(Address(userInfo['email'], userInfo['name'] ?? ''));
      }

      // Add attachments if provided
      if (attachments != null && attachments.isNotEmpty) {
        message.attachments.addAll(attachments);
      }

      // Send email
      await send(message, _smtpServer,
          timeout: const Duration(seconds: SecureEmailConfig.emailTimeoutSeconds));

      if (SecureEmailConfig.enableEmailLogging) {
        // Email sent successfully
      }

      return true;
    } catch (e) {
      // Error sending email
      return false;
    }
  }

  /// Build user signature HTML block
  String _buildUserSignature(Map<String, dynamic> userInfo) {
    final buffer = StringBuffer();

    buffer
        .writeln('<div style="font-family: Arial, sans-serif; color: #333;">');
    buffer.writeln(
        '<p style="margin: 10px 0;"><strong>Your Sales Representative:</strong></p>');
    buffer.writeln('<table style="border-collapse: collapse;">');

    // Name
    if (userInfo['name'] != null && userInfo['name'].isNotEmpty) {
      buffer.writeln('<tr>');
      buffer.writeln(
          '<td style="padding: 5px 10px 5px 0; color: #666;">Name:</td>');
      buffer.writeln(
          '<td style="padding: 5px 0;"><strong>${userInfo['name']}</strong></td>');
      buffer.writeln('</tr>');
    }

    // Role (Salesman/Distributor)
    if (userInfo['role'] != null && userInfo['role'].isNotEmpty) {
      buffer.writeln('<tr>');
      buffer.writeln(
          '<td style="padding: 5px 10px 5px 0; color: #666;">Role:</td>');
      buffer.writeln('<td style="padding: 5px 0;">${userInfo['role']}</td>');
      buffer.writeln('</tr>');
    }

    // Company
    if (userInfo['company'] != null && userInfo['company'].isNotEmpty) {
      buffer.writeln('<tr>');
      buffer.writeln(
          '<td style="padding: 5px 10px 5px 0; color: #666;">Company:</td>');
      buffer.writeln('<td style="padding: 5px 0;">${userInfo['company']}</td>');
      buffer.writeln('</tr>');
    }

    // Email
    if (userInfo['email'] != null && userInfo['email'].isNotEmpty) {
      buffer.writeln('<tr>');
      buffer.writeln(
          '<td style="padding: 5px 10px 5px 0; color: #666;">Email:</td>');
      buffer.writeln(
          '<td style="padding: 5px 0;"><a href="mailto:${userInfo['email']}" style="color: #0066cc;">${userInfo['email']}</a></td>');
      buffer.writeln('</tr>');
    }

    // Phone
    if (userInfo['phone'] != null && userInfo['phone'].isNotEmpty) {
      buffer.writeln('<tr>');
      buffer.writeln(
          '<td style="padding: 5px 10px 5px 0; color: #666;">Phone:</td>');
      buffer.writeln(
          '<td style="padding: 5px 0;"><a href="tel:${userInfo['phone']}" style="color: #0066cc;">${userInfo['phone']}</a></td>');
      buffer.writeln('</tr>');
    }

    // Territory/Region
    if (userInfo['territory'] != null && userInfo['territory'].isNotEmpty) {
      buffer.writeln('<tr>');
      buffer.writeln(
          '<td style="padding: 5px 10px 5px 0; color: #666;">Territory:</td>');
      buffer
          .writeln('<td style="padding: 5px 0;">${userInfo['territory']}</td>');
      buffer.writeln('</tr>');
    }

    buffer.writeln('</table>');
    buffer.writeln('</div>');

    return buffer.toString();
  }

  /// Send quote with PDF attachment (fully functional)
  Future<bool> sendQuoteWithPDF({
    required String recipientEmail,
    required String recipientName,
    required String quoteNumber,
    required String quoteId,
    required Map<String, dynamic> userInfo,
    String? customMessage,
  }) async {
    // Build email HTML content
    final htmlContent = '''
<div style="font-family: Arial, sans-serif; color: #333;">
  <h2 style="color: #0066cc;">TurboAir Quote #$quoteNumber</h2>
  
  <p>Dear $recipientName,</p>
  
  <p>${customMessage ?? 'Please find attached your TurboAir quote. If you have any questions or need modifications, please don\'t hesitate to contact your sales representative.'}</p>
  
  <p style="margin-top: 20px;">
    <strong>Quote Details:</strong><br>
    Quote Number: $quoteNumber<br>
    Date: ${DateTime.now().toString().split(' ')[0]}<br>
  </p>
  
  <p style="margin-top: 20px;">
    The detailed quote is attached as a PDF document.
  </p>
</div>
    ''';

    // Generate PDF attachment
    List<Attachment> attachments = [];
    try {
      // Generate PDF bytes from ExportService
      final Uint8List pdfBytes = await ExportService.generateQuotePDF(quoteId);
      
      // Create attachment from bytes using StreamAttachment
      final attachment = StreamAttachment(
        Stream.value(pdfBytes),
        'application/pdf',
        fileName: 'Quote_$quoteNumber.pdf',
        size: pdfBytes.length,
      );
      
      attachments.add(attachment);
    } catch (e) {
      // If PDF generation fails, log error but still send email
      print('Failed to generate PDF attachment: $e');
    }

    return await sendQuoteEmail(
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      quoteNumber: quoteNumber,
      htmlContent: htmlContent,
      userInfo: userInfo,
      attachments: attachments,
    );
  }
  
  /// Send quote with provided PDF bytes (alternative method)
  Future<bool> sendQuoteWithPDFBytes({
    required String recipientEmail,
    required String recipientName,
    required String quoteNumber,
    required Uint8List pdfBytes,
    required Map<String, dynamic> userInfo,
    String? customMessage,
  }) async {
    // Build email HTML content
    final htmlContent = '''
<div style="font-family: Arial, sans-serif; color: #333;">
  <h2 style="color: #0066cc;">TurboAir Quote #$quoteNumber</h2>
  
  <p>Dear $recipientName,</p>
  
  <p>${customMessage ?? 'Please find attached your TurboAir quote. If you have any questions or need modifications, please don\'t hesitate to contact your sales representative.'}</p>
  
  <p style="margin-top: 20px;">
    <strong>Quote Details:</strong><br>
    Quote Number: $quoteNumber<br>
    Date: ${DateTime.now().toString().split(' ')[0]}<br>
  </p>
  
  <p style="margin-top: 20px;">
    The detailed quote is attached as a PDF document.
  </p>
</div>
    ''';

    // Create attachment from provided bytes
    final attachment = StreamAttachment(
      Stream.value(pdfBytes),
      'application/pdf',
      fileName: 'Quote_$quoteNumber.pdf',
      size: pdfBytes.length,
    );

    return await sendQuoteEmail(
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      quoteNumber: quoteNumber,
      htmlContent: htmlContent,
      userInfo: userInfo,
      attachments: [attachment],
    );
  }
}