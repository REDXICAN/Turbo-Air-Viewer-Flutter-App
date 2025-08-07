import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:flutter/material.dart';

class DataMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static sb.SupabaseClient? _supabase;

  // Initialize Supabase client for migration
  static Future<void> initSupabase() async {
    if (_supabase == null) {
      await sb.Supabase.initialize(
        url: 'https://lxaritlhujdevalclhfc.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4YXJpdGxodWpkZXZhbGNsaGZjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMzOTg4NTIsImV4cCI6MjA2ODk3NDg1Mn0.2rapqW5LdMO9s4JeQOsuiqzfDmIcvvQT8OYDkA3albc',
      );
      _supabase = sb.Supabase.instance.client;
    }
  }

  // Main migration function
  static Future<MigrationResult> migrateAllData({
    required Function(String) onProgress,
    required String? userId, // Firebase user ID for user-specific data
  }) async {
    final result = MigrationResult();

    try {
      await initSupabase();

      // 1. Migrate Products (public data)
      onProgress('Migrating products...');
      await _migrateProducts(result);

      if (userId != null && _supabase!.auth.currentUser != null) {
        // 2. Migrate Clients (user-specific)
        onProgress('Migrating clients...');
        await _migrateClients(result, userId);

        // 3. Migrate Quotes (user-specific)
        onProgress('Migrating quotes...');
        await _migrateQuotes(result, userId);

        // 4. Migrate Cart Items (user-specific)
        onProgress('Migrating cart items...');
        await _migrateCartItems(result, userId);
      }

      onProgress('Migration completed!');
      result.success = true;
    } catch (e) {
      result.errors.add('Migration failed: $e');
      result.success = false;
    }

    return result;
  }

  // Migrate Products
  static Future<void> _migrateProducts(MigrationResult result) async {
    try {
      final products = await _supabase!.from('products').select();

      final batch = _firestore.batch();
      int count = 0;

      for (var product in products as List) {
        // Generate document ID from SKU for consistency
        final docId =
            product['sku'].toString().replaceAll(RegExp(r'[^\w\d]'), '_');
        final docRef = _firestore.collection('products').doc(docId);

        batch.set(docRef, {
          ...product,
          'migrated_at': FieldValue.serverTimestamp(),
        });

        count++;

        // Commit batch every 500 documents (Firestore limit)
        if (count % 500 == 0) {
          await batch.commit();
        }
      }

      await batch.commit();
      result.productsCount = count;

      debugPrint('✅ Migrated $count products');
    } catch (e) {
      result.errors.add('Products migration failed: $e');
      debugPrint('❌ Products migration failed: $e');
    }
  }

  // Migrate Clients
  static Future<void> _migrateClients(
      MigrationResult result, String firebaseUserId) async {
    try {
      final supabaseUserId = _supabase!.auth.currentUser?.id;
      if (supabaseUserId == null) {
        result.errors.add('No Supabase user logged in');
        return;
      }

      final clients = await _supabase!
          .from('clients')
          .select()
          .eq('user_id', supabaseUserId);

      final batch = _firestore.batch();
      int count = 0;

      // Map to store old ID -> new ID mapping for quotes migration
      final clientIdMap = <String, String>{};

      for (var client in clients as List) {
        final docRef = _firestore.collection('clients').doc();
        clientIdMap[client['id']] = docRef.id;

        batch.set(docRef, {
          ...client,
          'id': docRef.id,
          'user_id': firebaseUserId, // Use Firebase user ID
          'migrated_at': FieldValue.serverTimestamp(),
          'original_id': client['id'], // Keep original ID for reference
        });

        count++;

        if (count % 500 == 0) {
          await batch.commit();
        }
      }

      await batch.commit();
      result.clientsCount = count;
      result.clientIdMap = clientIdMap;

      debugPrint('✅ Migrated $count clients');
    } catch (e) {
      result.errors.add('Clients migration failed: $e');
      debugPrint('❌ Clients migration failed: $e');
    }
  }

  // Migrate Quotes
  static Future<void> _migrateQuotes(
      MigrationResult result, String firebaseUserId) async {
    try {
      final supabaseUserId = _supabase!.auth.currentUser?.id;
      if (supabaseUserId == null) {
        result.errors.add('No Supabase user logged in');
        return;
      }

      final quotes = await _supabase!
          .from('quotes')
          .select('*, quote_items(*)')
          .eq('user_id', supabaseUserId);

      int quotesCount = 0;
      int itemsCount = 0;

      for (var quote in quotes as List) {
        // Create quote document
        final quoteRef = _firestore.collection('quotes').doc();

        // Map client ID if available
        final mappedClientId =
            result.clientIdMap[quote['client_id']] ?? quote['client_id'];

        await quoteRef.set({
          ...Map<String, dynamic>.from(quote)..remove('quote_items'),
          'id': quoteRef.id,
          'user_id': firebaseUserId,
          'client_id': mappedClientId,
          'migrated_at': FieldValue.serverTimestamp(),
          'original_id': quote['id'],
        });

        // Migrate quote items
        final batch = _firestore.batch();
        for (var item in quote['quote_items'] as List) {
          final itemRef = _firestore.collection('quote_items').doc();

          // Get product document ID from SKU
          final productId = await _getProductIdFromSku(item['product_id']);

          batch.set(itemRef, {
            ...item,
            'id': itemRef.id,
            'quote_id': quoteRef.id,
            'product_id': productId ?? item['product_id'],
            'migrated_at': FieldValue.serverTimestamp(),
          });

          itemsCount++;
        }
        await batch.commit();

        quotesCount++;
      }

      result.quotesCount = quotesCount;
      result.quoteItemsCount = itemsCount;

      debugPrint('✅ Migrated $quotesCount quotes with $itemsCount items');
    } catch (e) {
      result.errors.add('Quotes migration failed: $e');
      debugPrint('❌ Quotes migration failed: $e');
    }
  }

  // Migrate Cart Items
  static Future<void> _migrateCartItems(
      MigrationResult result, String firebaseUserId) async {
    try {
      final supabaseUserId = _supabase!.auth.currentUser?.id;
      if (supabaseUserId == null) {
        result.errors.add('No Supabase user logged in');
        return;
      }

      final cartItems = await _supabase!
          .from('cart_items')
          .select()
          .eq('user_id', supabaseUserId);

      final batch = _firestore.batch();
      int count = 0;

      for (var item in cartItems as List) {
        final docRef = _firestore.collection('cart_items').doc();

        // Map client ID if available
        final mappedClientId =
            result.clientIdMap[item['client_id']] ?? item['client_id'];

        // Get product document ID from SKU
        final productId = await _getProductIdFromSku(item['product_id']);

        batch.set(docRef, {
          ...item,
          'id': docRef.id,
          'user_id': firebaseUserId,
          'client_id': mappedClientId,
          'product_id': productId ?? item['product_id'],
          'migrated_at': FieldValue.serverTimestamp(),
        });

        count++;

        if (count % 500 == 0) {
          await batch.commit();
        }
      }

      await batch.commit();
      result.cartItemsCount = count;

      debugPrint('✅ Migrated $count cart items');
    } catch (e) {
      result.errors.add('Cart items migration failed: $e');
      debugPrint('❌ Cart items migration failed: $e');
    }
  }

  // Helper function to get Firebase product ID from Supabase product ID
  static Future<String?> _getProductIdFromSku(String supabaseProductId) async {
    try {
      // First try to get the product from Supabase to get its SKU
      final product = await _supabase!
          .from('products')
          .select('sku')
          .eq('id', supabaseProductId)
          .single();

      // Generate the same document ID we used during migration
      return product['sku'].toString().replaceAll(RegExp(r'[^\w\d]'), '_');
    } catch (e) {
      debugPrint('Could not map product ID: $e');
    }
    return null;
  }

  // Clean up Supabase connection
  static void dispose() {
    _supabase = null;
  }
}

// Migration Result class
class MigrationResult {
  bool success = false;
  int productsCount = 0;
  int clientsCount = 0;
  int quotesCount = 0;
  int quoteItemsCount = 0;
  int cartItemsCount = 0;
  Map<String, String> clientIdMap = {};
  List<String> errors = [];

  String get summary {
    if (success) {
      return '''
Migration completed successfully!
- Products: $productsCount
- Clients: $clientsCount
- Quotes: $quotesCount (with $quoteItemsCount items)
- Cart Items: $cartItemsCount
''';
    } else {
      return '''
Migration failed!
Errors:
${errors.join('\n')}
''';
    }
  }
}
