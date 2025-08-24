// lib/core/services/realtime_database_service.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'app_logger.dart';

class RealtimeDatabaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // OPTIMIZATION: Add caching for frequently accessed data
  static final Map<String, dynamic> _productCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 10);
  static const int _maxCacheSize = 1000;

  // Enable offline persistence
  Future<void> enableOfflinePersistence() async {
    // setPersistenceEnabled is not supported on web platform
    if (!kIsWeb) {
      _db.setPersistenceEnabled(true);
      _db.setPersistenceCacheSizeBytes(100 * 1024 * 1024); // 100MB cache
    }
  }

  // Get current user ID
  String? get userId => _auth.currentUser?.uid;

  // ============ PRODUCTS ============
  Stream<List<Map<String, dynamic>>> getProducts({String? category}) {
    Query query = _db.ref('products');

    return query.onValue.map((event) {
      final List<Map<String, dynamic>> products = [];
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final product = Map<String, dynamic>.from(value);
          product['id'] = key;

          // Filter by category if provided
          if (category == null || product['category'] == category) {
            products.add(product);
          }
        });
      }

      // Sort by SKU
      products.sort((a, b) => (a['sku'] ?? '').compareTo(b['sku'] ?? ''));
      return products;
    });
  }

  Future<Map<String, dynamic>?> getProduct(String productId) async {
    // OPTIMIZATION: Check cache first
    final now = DateTime.now();
    if (_productCache.containsKey(productId) && 
        _cacheTimestamps.containsKey(productId) && 
        now.difference(_cacheTimestamps[productId]!) < _cacheExpiry) {
      return _productCache[productId];
    }
    
    try {
      final snapshot = await _db.ref('products/$productId').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        data['id'] = productId;
        
        // OPTIMIZATION: Cache the result
        _manageCacheSize();
        _productCache[productId] = data;
        _cacheTimestamps[productId] = now;
        
        return data;
      }
    } catch (e) {
      AppLogger.error('Error fetching product $productId', error: e);
    }
    return null;
  }
  
  // OPTIMIZATION: Manage cache size to prevent memory leaks
  void _manageCacheSize() {
    if (_productCache.length > _maxCacheSize) {
      final keysToRemove = _productCache.keys.take(_maxCacheSize ~/ 2).toList();
      for (final key in keysToRemove) {
        _productCache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }
  }
  
  // OPTIMIZATION: Batch fetch products (fixes N+1 query issue)
  Future<Map<String, Map<String, dynamic>>> batchGetProducts(Set<String> productIds) async {
    final Map<String, Map<String, dynamic>> results = {};
    final List<String> uncachedIds = [];
    final now = DateTime.now();
    
    // Check cache first
    for (final id in productIds) {
      if (_productCache.containsKey(id) && 
          _cacheTimestamps.containsKey(id) && 
          now.difference(_cacheTimestamps[id]!) < _cacheExpiry) {
        results[id] = _productCache[id];
      } else {
        uncachedIds.add(id);
      }
    }
    
    // Fetch uncached products in a single call
    if (uncachedIds.isNotEmpty) {
      try {
        final snapshot = await _db.ref('products').get();
        if (snapshot.exists && snapshot.value != null) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          
          for (final id in uncachedIds) {
            if (data.containsKey(id)) {
              final productData = Map<String, dynamic>.from(data[id]);
              productData['id'] = id;
              results[id] = productData;
              
              // Cache the result
              _manageCacheSize();
              _productCache[id] = productData;
              _cacheTimestamps[id] = now;
            }
          }
        }
      } catch (e) {
        AppLogger.error('Error batch fetching products', error: e);
      }
    }
    
    return results;
  }

  Future<void> addProduct(Map<String, dynamic> product) async {
    final newProductRef = _db.ref('products').push();
    await newProductRef.set({
      ...product,
      'created_at': ServerValue.timestamp,
      'updated_at': ServerValue.timestamp,
    });
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> updates) async {
    try {
      await _db.ref('products/$productId').update({
        ...updates,
        'updated_at': ServerValue.timestamp,
      });
      
      // Clear cache for this product
      _productCache.remove(productId);
      _cacheTimestamps.remove(productId);
      
      AppLogger.info(
        'Product updated: $productId',
        category: LogCategory.database,
      );
    } catch (e) {
      AppLogger.error('Error updating product $productId', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final snapshot = await _db.ref('products').get();
    final List<Map<String, dynamic>> results = [];

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data.forEach((key, value) {
        final product = Map<String, dynamic>.from(value);
        product['id'] = key;

        final searchText = query.toLowerCase();
        final sku = (product['sku'] ?? '').toString().toLowerCase();
        final description =
            (product['description'] ?? '').toString().toLowerCase();
        final category = (product['category'] ?? '').toString().toLowerCase();

        if (sku.contains(searchText) ||
            description.contains(searchText) ||
            category.contains(searchText)) {
          results.add(product);
        }
      });
    }

    return results;
  }

  // ============ CLIENTS ============
  Stream<List<Map<String, dynamic>>> getClients() {
    if (userId == null) return Stream.value([]);

    return _db
        .ref('clients/$userId')
        .onValue
        .map((event) {
      final List<Map<String, dynamic>> clients = [];
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final client = Map<String, dynamic>.from(value);
          client['id'] = key;
          clients.add(client);
        });
      }
      return clients;
    });
  }

  Future<Map<String, dynamic>?> getClient(String clientId) async {
    if (userId == null) return null;
    final snapshot = await _db.ref('clients/$userId/$clientId').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data['id'] = clientId;
      return data;
    }
    return null;
  }

  Future<String> addClient(Map<String, dynamic> client) async {
    if (userId == null) throw Exception('User not authenticated');

    final newClientRef = _db.ref('clients/$userId').push();
    await newClientRef.set({
      ...client,
      'created_at': ServerValue.timestamp,
      'updated_at': ServerValue.timestamp,
    });
    return newClientRef.key!;
  }

  Future<void> updateClient(
      String clientId, Map<String, dynamic> updates) async {
    if (userId == null) return;
    await _db.ref('clients/$userId/$clientId').update({
      ...updates,
      'updated_at': ServerValue.timestamp,
    });
  }

  Future<void> deleteClient(String clientId) async {
    if (userId == null) return;
    await _db.ref('clients/$userId/$clientId').remove();
  }

  // ============ CART ============
  Stream<List<Map<String, dynamic>>> getCartItems() {
    if (userId == null) return Stream.value([]);

    return _db
        .ref('cart_items/$userId')
        .onValue
        .map((event) {
      final List<Map<String, dynamic>> items = [];
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final item = Map<String, dynamic>.from(value);
          item['id'] = key;
          items.add(item);
        });
      }
      return items;
    });
  }

  Future<void> addToCart(String productId, int quantity) async {
    if (userId == null) throw Exception('User not authenticated');

    // If quantity is 0 or negative, remove from cart
    if (quantity <= 0) {
      await removeProductFromCart(productId);
      return;
    }

    // Check if item already exists in cart
    final existingSnapshot = await _db
        .ref('cart_items/$userId')
        .once();

    if (existingSnapshot.snapshot.value != null) {
      final data =
          Map<String, dynamic>.from(existingSnapshot.snapshot.value as Map);
      for (var entry in data.entries) {
        final item = Map<String, dynamic>.from(entry.value);
        if (item['product_id'] == productId) {
          // Set the absolute quantity (not add to existing)
          await _db.ref('cart_items/$userId/${entry.key}').update({
            'quantity': quantity,
            'updated_at': ServerValue.timestamp,
          });
          return;
        }
      }
    }

    // Add new item
    final newCartRef = _db.ref('cart_items/$userId').push();
    await newCartRef.set({
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
      'created_at': ServerValue.timestamp,
      'updated_at': ServerValue.timestamp,
    });
  }

  Future<void> removeProductFromCart(String productId) async {
    if (userId == null) return;
    
    // Find and remove the cart item with this product ID
    final existingSnapshot = await _db
        .ref('cart_items/$userId')
        .once();

    if (existingSnapshot.snapshot.value != null) {
      final data =
          Map<String, dynamic>.from(existingSnapshot.snapshot.value as Map);
      for (var entry in data.entries) {
        final item = Map<String, dynamic>.from(entry.value);
        if (item['product_id'] == productId) {
          await _db.ref('cart_items/$userId/${entry.key}').remove();
          return;
        }
      }
    }
  }

  Future<void> updateCartItem(String cartItemId, {
    int? quantity,
    double? discount,
    String? note,
    String? sequenceNumber,
  }) async {
    if (userId == null) return;
    
    // If only quantity is being updated and it's 0 or less, remove the item
    if (quantity != null && quantity <= 0 && discount == null && note == null) {
      await removeFromCart(cartItemId);
      return;
    }
    
    // Build update map with only provided values
    final updates = <String, dynamic>{
      'updated_at': ServerValue.timestamp,
    };
    
    if (quantity != null) {
      updates['quantity'] = quantity;
    }
    if (discount != null) {
      updates['discount'] = discount;
    }
    if (note != null) {
      updates['note'] = note.isEmpty ? null : note;
    }
    if (sequenceNumber != null) {
      updates['sequenceNumber'] = sequenceNumber;
    }
    
    await _db.ref('cart_items/$userId/$cartItemId').update(updates);
  }

  Future<void> removeFromCart(String cartItemId) async {
    if (userId == null) return;
    await _db.ref('cart_items/$userId/$cartItemId').remove();
  }

  Future<void> clearCart() async {
    if (userId == null) return;

    await _db.ref('cart_items/$userId').remove();
  }

  // ============ QUOTES ============
  Stream<List<Map<String, dynamic>>> getQuotes() {
    if (userId == null) return Stream.value([]);

    return _db
        .ref('quotes/$userId')
        .onValue
        .map((event) {
      final List<Map<String, dynamic>> quotes = [];
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final quote = Map<String, dynamic>.from(value);
          quote['id'] = key;
          quotes.add(quote);
        });
      }
      // Sort by created_at descending
      quotes.sort((a, b) {
        final aTime = a['created_at'] ?? 0;
        final bTime = b['created_at'] ?? 0;
        return bTime.compareTo(aTime);
      });
      return quotes;
    });
  }

  Future<Map<String, dynamic>?> getQuote(String quoteId) async {
    if (userId == null) return null;
    final snapshot = await _db.ref('quotes/$userId/$quoteId').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data['id'] = quoteId;
      return data;
    }
    return null;
  }

  Future<String> createQuote({
    required String clientId,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double taxRate,
    required double taxAmount,
    required double totalAmount,
    String? title,
    double? discountAmount,
    String? discountType,
    double? discountValue,
    String? comments,
    bool? includeCommentInEmail,
    String? projectId,
    String? projectName,
  }) async {
    if (userId == null) throw Exception('User not authenticated');
    
    // Validate inputs
    if (clientId.isEmpty) throw Exception('Client ID cannot be empty');
    if (items.isEmpty) throw Exception('Cannot create quote with no items');

    try {
      final quoteNumber = 'Q${DateTime.now().millisecondsSinceEpoch}';
      final dateStr = DateTime.now().toLocal().toString().split(' ')[0]; // YYYY-MM-DD format
      final defaultTitle = '$dateStr - Order #${quoteNumber.substring(1, 8)}'; // Use first 7 digits of timestamp
      final newQuoteRef = _db.ref('quotes/$userId').push();

      await newQuoteRef.set({
        'client_id': clientId,
        'quote_number': quoteNumber,
        'title': title?.isNotEmpty == true ? title : defaultTitle,
        'quote_items': items,  // Store items directly in the quote
        'subtotal': subtotal,
        'discount_amount': discountAmount ?? 0,
        'discount_type': discountType ?? 'fixed',
        'discount_value': discountValue ?? 0,
        'tax_rate': taxRate,
        'tax_amount': taxAmount,
        'total_amount': totalAmount,
        'comments': comments ?? '',
        'include_comment_in_email': includeCommentInEmail ?? false,
        'project_id': projectId,
        'project_name': projectName,
        'status': 'draft',
        'user_id': userId,  // Add user ID for reference
        'created_at': ServerValue.timestamp,
        'updated_at': ServerValue.timestamp,
      });

      final key = newQuoteRef.key;
      if (key == null) throw Exception('Failed to generate quote ID');
      
      // Clear all preserved comments after quote creation
      await clearAllPreservedComments();
      
      return key;
    } catch (e) {
      AppLogger.error('Error creating quote - clientId: $clientId, items: ${items.length}, total: $totalAmount', 
        error: e, 
        category: LogCategory.quote);
      throw Exception('Failed to create quote: $e');
    }
  }

  Future<void> updateQuoteStatus(String quoteId, String status) async {
    if (userId == null) return;
    await _db.ref('quotes/$userId/$quoteId').update({
      'status': status,
      'updated_at': ServerValue.timestamp,
    });
  }

  Future<void> updateQuote(String quoteId, Map<String, dynamic> updates) async {
    if (userId == null) throw Exception('User not authenticated');
    
    try {
      await _db.ref('quotes/$userId/$quoteId').update(updates);
      
      AppLogger.info(
        'Quote updated: $quoteId',
        category: LogCategory.database,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to update quote',
        error: e,
        category: LogCategory.database,
      );
      rethrow;
    }
  }

  Future<void> deleteQuote(String quoteId) async {
    try {
      if (userId == null) {
        throw Exception('User must be authenticated to delete quotes');
      }
      
      // Delete from user's quotes
      final quoteRef = _db.ref('quotes/$userId/$quoteId');
      
      // Check if quote exists
      final snapshot = await quoteRef.get();
      if (!snapshot.exists) {
        throw Exception('Quote not found');
      }
      
      // Delete the quote
      await quoteRef.remove();
      
    } catch (e) {
      // Log error and rethrow
      rethrow;
    }
  }

  // ============ PRESERVED COMMENTS ============
  // Store comments temporarily when items are removed from cart
  Future<void> preserveComment(String productId, String comment) async {
    if (userId == null) return;
    
    try {
      await _db.ref('preserved_comments/$userId/$productId').set({
        'comment': comment,
        'preserved_at': ServerValue.timestamp,
      });
      
      AppLogger.info('Comment preserved for product: $productId', category: LogCategory.business);
    } catch (e) {
      AppLogger.error('Error preserving comment', error: e);
    }
  }
  
  Future<String?> getPreservedComment(String productId) async {
    if (userId == null) return null;
    
    try {
      final snapshot = await _db.ref('preserved_comments/$userId/$productId').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return data['comment'] as String?;
      }
      return null;
    } catch (e) {
      AppLogger.error('Error fetching preserved comment', error: e);
      return null;
    }
  }
  
  Future<void> clearPreservedComment(String productId) async {
    if (userId == null) return;
    
    try {
      await _db.ref('preserved_comments/$userId/$productId').remove();
      AppLogger.info('Preserved comment cleared for product: $productId', category: LogCategory.business);
    } catch (e) {
      AppLogger.error('Error clearing preserved comment', error: e);
    }
  }
  
  Future<void> clearAllPreservedComments() async {
    if (userId == null) return;
    
    try {
      await _db.ref('preserved_comments/$userId').remove();
      AppLogger.info('All preserved comments cleared', category: LogCategory.business);
    } catch (e) {
      AppLogger.error('Error clearing all preserved comments', error: e);
    }
  }

  // ============ PROJECTS ============
  Future<String> createProject({
    required String name,
    required String clientId,
    String? description,
    String status = 'active',
  }) async {
    if (userId == null) throw Exception('User not authenticated');
    
    try {
      final newProjectRef = _db.ref('projects/$userId').push();
      
      await newProjectRef.set({
        'name': name,
        'clientId': clientId,
        'description': description ?? '',
        'status': status,
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });
      
      final key = newProjectRef.key;
      if (key == null) throw Exception('Failed to generate project ID');
      
      AppLogger.info('Project created: $name', category: LogCategory.business);
      return key;
    } catch (e) {
      AppLogger.error('Error creating project', error: e);
      throw Exception('Failed to create project: $e');
    }
  }
  
  Future<Map<String, dynamic>?> getProject(String projectId) async {
    if (userId == null) return null;
    
    try {
      final snapshot = await _db.ref('projects/$userId/$projectId').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        data['id'] = projectId;
        return data;
      }
      return null;
    } catch (e) {
      AppLogger.error('Error fetching project $projectId', error: e);
      return null;
    }
  }
  
  Future<List<Map<String, dynamic>>> getProjects({String? clientId}) async {
    if (userId == null) return [];
    
    try {
      Query query = _db.ref('projects/$userId');
      
      // Filter by client if specified
      if (clientId != null) {
        query = query.orderByChild('clientId').equalTo(clientId);
      }
      
      final snapshot = await query.get();
      
      if (!snapshot.exists || snapshot.value == null) return [];
      
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final projects = <Map<String, dynamic>>[];
      
      data.forEach((key, value) {
        final project = Map<String, dynamic>.from(value);
        project['id'] = key;
        projects.add(project);
      });
      
      // Sort by created date (most recent first)
      projects.sort((a, b) {
        final aDate = a['createdAt'] ?? 0;
        final bDate = b['createdAt'] ?? 0;
        return bDate.compareTo(aDate);
      });
      
      return projects;
    } catch (e) {
      AppLogger.error('Error fetching projects', error: e);
      return [];
    }
  }
  
  Future<void> updateProject(String projectId, Map<String, dynamic> updates) async {
    if (userId == null) throw Exception('User not authenticated');
    
    try {
      await _db.ref('projects/$userId/$projectId').update({
        ...updates,
        'updatedAt': ServerValue.timestamp,
      });
      
      AppLogger.info('Project updated: $projectId', category: LogCategory.business);
    } catch (e) {
      AppLogger.error('Error updating project $projectId', error: e);
      throw Exception('Failed to update project: $e');
    }
  }
  
  Future<void> deleteProject(String projectId) async {
    if (userId == null) throw Exception('User not authenticated');
    
    try {
      // Check if project has quotes
      final quotes = await getQuotesByProject(projectId);
      if (quotes.isNotEmpty) {
        throw Exception('Cannot delete project with existing quotes');
      }
      
      await _db.ref('projects/$userId/$projectId').remove();
      
      AppLogger.info('Project deleted: $projectId', category: LogCategory.business);
    } catch (e) {
      AppLogger.error('Error deleting project $projectId', error: e);
      throw Exception('Failed to delete project: $e');
    }
  }
  
  Future<List<Map<String, dynamic>>> getQuotesByProject(String projectId) async {
    if (userId == null) return [];
    
    try {
      final snapshot = await _db.ref('quotes/$userId')
          .orderByChild('project_id')
          .equalTo(projectId)
          .get();
      
      if (!snapshot.exists || snapshot.value == null) return [];
      
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final quotes = <Map<String, dynamic>>[];
      
      data.forEach((key, value) {
        final quote = Map<String, dynamic>.from(value);
        quote['id'] = key;
        quotes.add(quote);
      });
      
      // Sort by created date (most recent first)
      quotes.sort((a, b) {
        final aDate = a['created_at'] ?? 0;
        final bDate = b['created_at'] ?? 0;
        return bDate.compareTo(aDate);
      });
      
      return quotes;
    } catch (e) {
      AppLogger.error('Error fetching quotes for project $projectId', error: e);
      return [];
    }
  }
  
  Future<void> updateProjectStatus(String projectId, String status) async {
    if (userId == null) throw Exception('User not authenticated');
    
    try {
      await _db.ref('projects/$userId/$projectId').update({
        'status': status,
        'updatedAt': ServerValue.timestamp,
      });
      
      AppLogger.info('Project status updated: $projectId -> $status', category: LogCategory.business);
    } catch (e) {
      AppLogger.error('Error updating project status', error: e);
      throw Exception('Failed to update project status: $e');
    }
  }

  // ============ USER PROFILES ============
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final snapshot = await _db.ref('user_profiles/$uid').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data['id'] = uid;
      return data;
    }
    return null;
  }

  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String name,
    String role = 'distributor',
    String status = 'active',
  }) async {
    await _db.ref('user_profiles/$uid').set({
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'status': status,
      'created_at': ServerValue.timestamp,
      'updated_at': ServerValue.timestamp,
    });
  }

  Future<void> updateUserProfile(
      String uid, Map<String, dynamic> updates) async {
    await _db.ref('user_profiles/$uid').update({
      ...updates,
      'updated_at': ServerValue.timestamp,
    });
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snapshot = await _db.ref('user_profiles').once();
    if (snapshot.snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      return data.entries.map((entry) {
        final userMap = Map<String, dynamic>.from(entry.value);
        userMap['id'] = entry.key;
        return userMap;
      }).toList();
    }
    return [];
  }

  // ============ STATISTICS ============
  Future<int> getTotalClients() async {
    if (userId == null) return 0;

    final snapshot = await _db
        .ref('clients/$userId')
        .once();

    if (snapshot.snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      return data.length;
    }
    return 0;
  }

  Future<int> getTotalQuotes() async {
    if (userId == null) return 0;

    final snapshot = await _db.ref('quotes/$userId').once();

    if (snapshot.snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      return data.length;
    }
    return 0;
  }

  Future<int> getTotalProducts() async {
    final snapshot = await _db.ref('products').once();

    if (snapshot.snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      return data.length;
    }
    return 0;
  }
}
