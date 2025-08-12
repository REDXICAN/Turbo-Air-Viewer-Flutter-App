// lib/core/config/secure_email_config.dart
// Secure email configuration using environment variables
// This replaces the old email_config.dart with hardcoded credentials

import 'env_config.dart';

class SecureEmailConfig {
  // Email credentials from environment
  static String get gmailAddress => EnvConfig.emailSenderAddress;
  static String get gmailAppPassword => EnvConfig.emailAppPassword;
  static String get senderName => EnvConfig.emailSenderName;
  
  // Email settings
  static const String noReplyNote = 
      'This is an automated message. Please do not reply to this email.';
  
  static String get appUrl => EnvConfig.emailAppUrl;
  
  static const int emailTimeoutSeconds = 30;
  static const bool enableEmailLogging = true;
  
  // SMTP Settings from environment
  static String get smtpHost => EnvConfig.smtpHost;
  static int get smtpPort => EnvConfig.smtpPort;
  static bool get smtpSecure => EnvConfig.smtpSecure;
  
  // Rate limiting
  static const int maxEmailsPerMinute = 20;
  static const int maxEmailsPerDay = 500;
  
  // Email templates
  static const String quoteEmailSubject = 'TurboAir Quote #';
  static const String quoteApprovalSubject = 
      'Quote Approval Required - TurboAir Quote #';
  static const String quoteStatusUpdateSubject = 
      'Quote Status Update - TurboAir Quote #';
}